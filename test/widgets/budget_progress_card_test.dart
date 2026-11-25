import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:awan_cash/core/format.dart';
import 'package:awan_cash/models/budget.dart';
import 'package:awan_cash/models/category.dart';
import 'package:awan_cash/widgets/budget_progress_card.dart';

Widget buildTestableWidget(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('id', 'ID'),
      Locale('en', 'US'),
    ],
    locale: const Locale('id', 'ID'),
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  const testCategory = Category(
    id: 5,
    name: 'Belanja Bulanan',
    type: TransactionType.expense,
    icon: 'shopping_cart',
    color: 0xFF3B82F6,
  );

  const testBudget = Budget(
    id: 1,
    categoryId: 5,
    monthlyLimit: 1000000,
    monthYear: '2026-11',
  );

  group('BudgetProgressCard Widget Tests', () {
    testWidgets('Safe state (< 75% ratio) displays remaining budget and green styling', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const BudgetProgressCard(
            budget: testBudget,
            category: testCategory,
            spentAmount: 400000, // 40%
          ),
        ),
      );

      // Verify category title
      expect(find.text('Belanja Bulanan'), findsOneWidget);

      // Verify remaining budget text
      expect(find.text('Tersisa ${formatRupiah(600000)}'), findsOneWidget);

      // Verify spent text
      expect(find.text('Terpakai: ${formatRupiah(400000)}'), findsOneWidget);

      // Verify percentage text
      final percentageFinder = find.text('40% dari ${formatRupiah(1000000)}');
      expect(percentageFinder, findsOneWidget);

      // Verify green color (#10B981) on percentage text
      final percentageText = tester.widget<Text>(percentageFinder);
      expect(percentageText.style?.color, const Color(0xFF10B981));

      // Verify progress bar indicator
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, closeTo(0.4, 0.001));
      final colorAnim = progressIndicator.valueColor as AlwaysStoppedAnimation<Color>;
      expect(colorAnim.value, const Color(0xFF10B981));
    });

    testWidgets('Warning state (>= 75% and < 100% ratio) displays warning and amber styling', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const BudgetProgressCard(
            budget: testBudget,
            category: testCategory,
            spentAmount: 850000, // 85%
          ),
        ),
      );

      // Verify remaining budget text
      expect(find.text('Tersisa ${formatRupiah(150000)}'), findsOneWidget);

      // Verify percentage text
      final percentageFinder = find.text('85% dari ${formatRupiah(1000000)}');
      expect(percentageFinder, findsOneWidget);

      // Verify amber/warning color (#F59E0B) on percentage text
      final percentageText = tester.widget<Text>(percentageFinder);
      expect(percentageText.style?.color, const Color(0xFFF59E0B));

      // Verify progress bar indicator
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, closeTo(0.85, 0.001));
      final colorAnim = progressIndicator.valueColor as AlwaysStoppedAnimation<Color>;
      expect(colorAnim.value, const Color(0xFFF59E0B));
    });

    testWidgets('Over-budget state (>= 100% ratio) displays over-budget warning and red styling', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const BudgetProgressCard(
            budget: testBudget,
            category: testCategory,
            spentAmount: 1300000, // 130%
          ),
        ),
      );

      // Verify over-budget message
      expect(find.text('Melebihi anggaran sebesar ${formatRupiah(300000)}'), findsOneWidget);

      // Verify percentage text
      final percentageFinder = find.text('130% dari ${formatRupiah(1000000)}');
      expect(percentageFinder, findsOneWidget);

      // Verify red color (#EF4444) on percentage text
      final percentageText = tester.widget<Text>(percentageFinder);
      expect(percentageText.style?.color, const Color(0xFFEF4444));

      // Verify progress bar indicator clamped to 1.0 and red
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 1.0);
      final colorAnim = progressIndicator.valueColor as AlwaysStoppedAnimation<Color>;
      expect(colorAnim.value, const Color(0xFFEF4444));
    });

    testWidgets('Invokes onEdit callback when edit icon button is tapped', (tester) async {
      bool editTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          BudgetProgressCard(
            budget: testBudget,
            category: testCategory,
            spentAmount: 500000,
            onEdit: () {
              editTapped = true;
            },
          ),
        ),
      );

      // Tap on edit icon button
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(editTapped, isTrue);
    });

    testWidgets('Displays fallback category name when category is null', (tester) async {
      const budgetWithoutCat = Budget(
        id: 2,
        categoryId: 99,
        monthlyLimit: 500000,
        monthYear: '2026-11',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const BudgetProgressCard(
            budget: budgetWithoutCat,
            category: null,
            spentAmount: 100000,
          ),
        ),
      );

      expect(find.text('Kategori #99'), findsOneWidget);
    });
  });
}
