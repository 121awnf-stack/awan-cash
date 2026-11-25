import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:awan_cash/core/format.dart';
import 'package:awan_cash/core/theme.dart';
import 'package:awan_cash/models/category.dart';
import 'package:awan_cash/models/transaction_entry.dart';
import 'package:awan_cash/models/wallet.dart';
import 'package:awan_cash/widgets/transaction_tile.dart';

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
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  const sampleCategory = Category(
    id: 1,
    name: 'Makanan & Minuman',
    type: TransactionType.expense,
    icon: 'restaurant',
    color: 0xFFF43F5E,
  );

  const sampleIncomeCategory = Category(
    id: 2,
    name: 'Gaji Bulanan',
    type: TransactionType.income,
    icon: 'payments',
    color: 0xFF10B981,
  );

  const sourceWallet = Wallet(
    id: 10,
    name: 'Dompet Utama',
    type: WalletType.cash,
    initialBalance: 500000,
    color: 0xFF0EA5E9,
    icon: 'payments',
  );

  const destinationWallet = Wallet(
    id: 20,
    name: 'Rekening BCA',
    type: WalletType.bank,
    initialBalance: 2000000,
    color: 0xFF6366F1,
    icon: 'account_balance',
  );

  group('TransactionTile Widget Tests', () {
    testWidgets('Expense transaction displays - Rp prefix, rose color, icon, and wallet name', (tester) async {
      final tx = TransactionEntry(
        id: 101,
        type: TransactionType.expense,
        amount: 45000,
        walletId: 10,
        categoryId: 1,
        dateTime: DateTime(2026, 11, 19, 12, 30),
        notes: 'Makan siang nasi padang',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          TransactionTile(
            transaction: tx,
            category: sampleCategory,
            wallet: sourceWallet,
          ),
        ),
      );

      // Verify category title and notes
      expect(find.text('Makanan & Minuman'), findsOneWidget);
      expect(find.text('Makan siang nasi padang'), findsOneWidget);

      // Verify wallet name
      expect(find.text('Dompet Utama'), findsOneWidget);

      // Verify category icon
      expect(find.byIcon(Icons.restaurant), findsOneWidget);

      // Verify amount formatted with '- ' prefix
      final expectedAmountText = '- ${formatRupiah(45000)}';
      final amountFinder = find.text(expectedAmountText);
      expect(amountFinder, findsOneWidget);

      // Verify expense color (Rose #F43F5E / AppColors.expense)
      final textWidget = tester.widget<Text>(amountFinder);
      expect(textWidget.style?.color, AppColors.expense);
    });

    testWidgets('Income transaction displays + Rp prefix and emerald green color', (tester) async {
      final tx = TransactionEntry(
        id: 102,
        type: TransactionType.income,
        amount: 5000000,
        walletId: 10,
        categoryId: 2,
        dateTime: DateTime(2026, 11, 19, 9, 0),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          TransactionTile(
            transaction: tx,
            category: sampleIncomeCategory,
            wallet: sourceWallet,
          ),
        ),
      );

      // Verify category name and icon
      expect(find.text('Gaji Bulanan'), findsOneWidget);
      expect(find.byIcon(Icons.payments), findsOneWidget);

      // Verify amount formatted with '+ ' prefix
      final expectedAmountText = '+ ${formatRupiah(5000000)}';
      final amountFinder = find.text(expectedAmountText);
      expect(amountFinder, findsOneWidget);

      // Verify income color (Emerald Green #10B981 / AppColors.income)
      final textWidget = tester.widget<Text>(amountFinder);
      expect(textWidget.style?.color, AppColors.income);
    });

    testWidgets('Transfer transaction displays title, transfer icon, and indigo color', (tester) async {
      final tx = TransactionEntry(
        id: 103,
        type: TransactionType.transfer,
        amount: 250000,
        walletId: 10,
        toWalletId: 20,
        dateTime: DateTime(2026, 11, 19, 14, 15),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          TransactionTile(
            transaction: tx,
            wallet: sourceWallet,
            toWallet: destinationWallet,
          ),
        ),
      );

      // Verify Transfer title format
      expect(find.text('Transfer: Dompet Utama → Rekening BCA'), findsOneWidget);

      // Verify transfer icon
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);

      // Verify amount without prefix and indigo color
      final expectedAmountText = formatRupiah(250000);
      final amountFinder = find.text(expectedAmountText);
      expect(amountFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(amountFinder);
      expect(textWidget.style?.color, AppColors.transfer);
    });

    testWidgets('Invokes onTap callback when tile is tapped', (tester) async {
      bool tapped = false;
      final tx = TransactionEntry(
        id: 104,
        type: TransactionType.expense,
        amount: 15000,
        walletId: 10,
        categoryId: 1,
        dateTime: DateTime(2026, 11, 19, 8, 0),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          TransactionTile(
            transaction: tx,
            category: sampleCategory,
            wallet: sourceWallet,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(TransactionTile));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('Fallback title when category is null', (tester) async {
      final expenseTx = TransactionEntry(
        id: 105,
        type: TransactionType.expense,
        amount: 20000,
        walletId: 10,
        dateTime: DateTime(2026, 11, 19, 10, 0),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          TransactionTile(
            transaction: expenseTx,
            wallet: sourceWallet,
          ),
        ),
      );

      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);
    });

    testWidgets('Dismissible / delete action can be wrapped around TransactionTile', (tester) async {
      bool deleted = false;
      final tx = TransactionEntry(
        id: 106,
        type: TransactionType.expense,
        amount: 30000,
        walletId: 10,
        categoryId: 1,
        dateTime: DateTime(2026, 11, 19, 11, 0),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          Dismissible(
            key: const ValueKey(106),
            onDismissed: (_) => deleted = true,
            child: TransactionTile(
              transaction: tx,
              category: sampleCategory,
              wallet: sourceWallet,
            ),
          ),
        ),
      );

      // Swipe to trigger dismissal
      await tester.drag(find.byType(Dismissible), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });
}
