import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:awan_cash/core/format.dart';
import 'package:awan_cash/models/wallet.dart';
import 'package:awan_cash/widgets/wallet_card.dart';

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
      body: Center(child: child),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('WalletCard Widget Tests', () {
    testWidgets('Renders cash wallet with Tunai badge, name, and formatted balance', (tester) async {
      const cashWallet = Wallet(
        id: 1,
        name: 'Dompet Fisik',
        type: WalletType.cash,
        initialBalance: 100000,
        color: 0xFF10B981,
        icon: 'payments',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const WalletCard(
            wallet: cashWallet,
            balance: 350000,
          ),
        ),
      );

      // Verify wallet name
      expect(find.text('Dompet Fisik'), findsOneWidget);

      // Verify formatted balance
      expect(find.text(formatRupiah(350000)), findsOneWidget);

      // Verify Tunai badge
      expect(find.text('Tunai'), findsOneWidget);

      // Verify wallet icon
      expect(find.byIcon(Icons.payments), findsOneWidget);
    });

    testWidgets('Renders bank wallet with Bank badge, name, and formatted balance', (tester) async {
      const bankWallet = Wallet(
        id: 2,
        name: 'BCA Prioritas',
        type: WalletType.bank,
        initialBalance: 5000000,
        color: 0xFF0EA5E9,
        icon: 'account_balance',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const WalletCard(
            wallet: bankWallet,
            balance: 12500000,
          ),
        ),
      );

      // Verify wallet name
      expect(find.text('BCA Prioritas'), findsOneWidget);

      // Verify formatted balance
      expect(find.text(formatRupiah(12500000)), findsOneWidget);

      // Verify Bank badge
      expect(find.text('Bank'), findsOneWidget);
    });

    testWidgets('Renders e-wallet with E-Wallet badge, name, and formatted balance', (tester) async {
      const eWallet = Wallet(
        id: 3,
        name: 'GoPay & OVO',
        type: WalletType.ewallet,
        initialBalance: 50000,
        color: 0xFF6366F1,
        icon: 'credit_card',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const WalletCard(
            wallet: eWallet,
            balance: 75000,
          ),
        ),
      );

      // Verify wallet name
      expect(find.text('GoPay & OVO'), findsOneWidget);

      // Verify formatted balance
      expect(find.text(formatRupiah(75000)), findsOneWidget);

      // Verify E-Wallet badge
      expect(find.text('E-Wallet'), findsOneWidget);
    });

    testWidgets('Invokes onTap callback when card is tapped', (tester) async {
      bool tapped = false;
      const wallet = Wallet(
        id: 4,
        name: 'Dana Darurat',
        type: WalletType.bank,
        initialBalance: 10000000,
        color: 0xFF0284C7,
        icon: 'savings',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          WalletCard(
            wallet: wallet,
            balance: 10000000,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(WalletCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
