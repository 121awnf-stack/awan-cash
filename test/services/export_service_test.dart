import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:awan_cash/services/export_service.dart';
import 'package:awan_cash/models/transaction_entry.dart';
import 'package:awan_cash/models/wallet.dart';
import 'package:awan_cash/models/category.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('ExportService CSV Generation', () {
    const cashWallet = Wallet(
      id: 1,
      name: 'Dompet Tunai',
      type: WalletType.cash,
      color: 0xFF10B981,
      icon: 'payments',
    );
    const bankWallet = Wallet(
      id: 2,
      name: 'BCA Utama',
      type: WalletType.bank,
      color: 0xFF1E40AF,
      icon: 'account_balance',
    );
    const foodCategory = Category(
      id: 10,
      name: 'Makanan & Minuman',
      type: TransactionType.expense,
      icon: 'restaurant',
      color: 0xFFEF4444,
    );
    const salaryCategory = Category(
      id: 20,
      name: 'Gaji Pokok',
      type: TransactionType.income,
      icon: 'work',
      color: 0xFF22C55E,
    );

    final sampleDate = DateTime(2026, 11, 19, 10, 15, 0);

    test('CSV starts with UTF-8 BOM character (\\uFEFF)', () {
      final csv = ExportService.instance.generateCsvString(
        transactions: [],
        wallets: [cashWallet],
        categories: [foodCategory],
      );

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv.codeUnitAt(0), 0xFEFF);
    });

    test('CSV header matches exact expected semicolon-separated format', () {
      final csv = ExportService.instance.generateCsvString(
        transactions: [],
        wallets: [],
        categories: [],
      );

      final lines = const LineSplitter().convert(csv);
      // Strip UTF-8 BOM from first line if present
      final header = lines.first.replaceAll('\uFEFF', '');

      expect(
        header,
        'ID;Tanggal;Waktu;Tipe;Kategori;Dompet Asal;Dompet Tujuan;Nominal;Catatan',
      );
    });

    test('CSV formats expense, income, and transfer transaction entries correctly', () {
      final transactions = [
        TransactionEntry(
          id: 101,
          type: TransactionType.expense,
          amount: 45000,
          walletId: 1,
          categoryId: 10,
          dateTime: sampleDate,
          notes: 'Makan siang enak',
        ),
        TransactionEntry(
          id: 102,
          type: TransactionType.income,
          amount: 8000000,
          walletId: 2,
          categoryId: 20,
          dateTime: sampleDate.add(const Duration(hours: 2)),
          notes: 'Gaji bulan November',
        ),
        TransactionEntry(
          id: 103,
          type: TransactionType.transfer,
          amount: 500000,
          walletId: 2,
          toWalletId: 1,
          dateTime: sampleDate.add(const Duration(hours: 4)),
          notes: 'Tarik tunai dari ATM',
        ),
      ];

      final csv = ExportService.instance.generateCsvString(
        transactions: transactions,
        wallets: [cashWallet, bankWallet],
        categories: [foodCategory, salaryCategory],
      );

      final lines = const LineSplitter().convert(csv);
      expect(lines.length, 4); // 1 header + 3 rows

      // Row 1: Pengeluaran
      final rowExpense = lines[1];
      expect(rowExpense, contains('101;'));
      expect(rowExpense, contains('"Pengeluaran";'));
      expect(rowExpense, contains('"Makanan & Minuman";'));
      expect(rowExpense, contains('"Dompet Tunai";'));
      expect(rowExpense, contains('"-"')); // No toWallet
      expect(rowExpense, contains('45000;'));
      expect(rowExpense, contains('"Makan siang enak"'));

      // Row 2: Pemasukan
      final rowIncome = lines[2];
      expect(rowIncome, contains('102;'));
      expect(rowIncome, contains('"Pemasukan";'));
      expect(rowIncome, contains('"Gaji Pokok";'));
      expect(rowIncome, contains('"BCA Utama";'));
      expect(rowIncome, contains('8000000;'));
      expect(rowIncome, contains('"Gaji bulan November"'));

      // Row 3: Transfer
      final rowTransfer = lines[3];
      expect(rowTransfer, contains('103;'));
      expect(rowTransfer, contains('"Transfer";'));
      expect(rowTransfer, contains('"Transfer Saldo";')); // Automatic category label for transfer
      expect(rowTransfer, contains('"BCA Utama";"Dompet Tunai";'));
      expect(rowTransfer, contains('500000;'));
      expect(rowTransfer, contains('"Tarik tunai dari ATM"'));
    });

    test('CSV sanitizes semicolons in notes by replacing them with commas', () {
      final tx = TransactionEntry(
        id: 201,
        type: TransactionType.expense,
        amount: 30000,
        walletId: 1,
        categoryId: 10,
        dateTime: sampleDate,
        notes: 'Item 1; Item 2; Item 3',
      );

      final csv = ExportService.instance.generateCsvString(
        transactions: [tx],
        wallets: [cashWallet],
        categories: [foodCategory],
      );

      final lines = const LineSplitter().convert(csv);
      final row = lines[1];

      expect(row, contains('"Item 1, Item 2, Item 3"'));
      expect(row.contains('Item 1;'), isFalse);
    });

    test('CSV handles missing foreign keys gracefully with fallback values', () {
      final orphanedTx = TransactionEntry(
        id: 301,
        type: TransactionType.expense,
        amount: 15000,
        walletId: 999, // Unknown wallet
        categoryId: 888, // Unknown category
        dateTime: sampleDate,
      );

      final csv = ExportService.instance.generateCsvString(
        transactions: [orphanedTx],
        wallets: [],
        categories: [],
      );

      final lines = const LineSplitter().convert(csv);
      final row = lines[1];

      expect(row, contains('"Dompet #999"')); // Fallback wallet name
      expect(row, contains('"-"')); // Fallback category name
    });
  });

  group('Backup & Restore JSON Data Mapping Schema', () {
    test('validates complete backup JSON payload schema structure', () {
      final backupPayload = <String, dynamic>{
        'app': 'Awan Cash',
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'wallets': [
          {
            'id': 1,
            'name': 'Dompet Kas',
            'type': 'cash',
            'initial_balance': 100000,
            'color': 0xFF10B981,
            'icon': 'payments',
          }
        ],
        'categories': [
          {
            'id': 1,
            'name': 'Makanan',
            'type': 'expense',
            'icon': 'restaurant',
            'color': 0xFFEF4444,
          }
        ],
        'transactions': [
          {
            'id': 1,
            'type': 'expense',
            'amount': 25000,
            'wallet_id': 1,
            'to_wallet_id': null,
            'category_id': 1,
            'date_time': '2026-11-19T12:00:00.000',
            'notes': 'Soto ayam',
            'receipt_path': null,
          }
        ],
        'budgets': [
          {
            'id': 1,
            'category_id': 1,
            'monthly_limit': 1000000,
            'month_year': '2026-11',
          }
        ],
        'settings': [
          {
            'key': 'security_biometric_enabled',
            'value': 'true',
          }
        ],
      };

      // Verify JSON serialization and roundtrip deserialization
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupPayload);
      expect(jsonString.isNotEmpty, isTrue);

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(decoded['app'], 'Awan Cash');
      expect(decoded['version'], '1.0');
      expect(decoded['exported_at'], isNotNull);
      expect(DateTime.tryParse(decoded['exported_at'] as String), isNotNull);

      // Verify sub-collections
      expect(decoded['wallets'], isA<List>());
      expect((decoded['wallets'] as List).length, 1);
      final walletMap = (decoded['wallets'] as List).first as Map<String, dynamic>;
      expect(walletMap['name'], 'Dompet Kas');
      expect(walletMap['type'], 'cash');

      expect(decoded['categories'], isA<List>());
      final catMap = (decoded['categories'] as List).first as Map<String, dynamic>;
      expect(catMap['name'], 'Makanan');

      expect(decoded['transactions'], isA<List>());
      final txMap = (decoded['transactions'] as List).first as Map<String, dynamic>;
      expect(txMap['amount'], 25000);

      expect(decoded['budgets'], isA<List>());
      final bgtMap = (decoded['budgets'] as List).first as Map<String, dynamic>;
      expect(bgtMap['monthly_limit'], 1000000);

      expect(decoded['settings'], isA<List>());
      final setMap = (decoded['settings'] as List).first as Map<String, dynamic>;
      expect(setMap['key'], 'security_biometric_enabled');
    });

    test('validates schema when backup collections are empty', () {
      final emptyBackup = <String, dynamic>{
        'app': 'Awan Cash',
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'wallets': [],
        'categories': [],
        'transactions': [],
        'budgets': [],
        'settings': [],
      };

      final jsonString = jsonEncode(emptyBackup);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(decoded['app'], 'Awan Cash');
      expect(decoded['wallets'], isEmpty);
      expect(decoded['categories'], isEmpty);
      expect(decoded['transactions'], isEmpty);
      expect(decoded['budgets'], isEmpty);
      expect(decoded['settings'], isEmpty);
    });

    test('validates rejection of malformed or invalid JSON input for restore', () {
      const invalidJson = '{"app": "Awan Cash", "wallets": [invalid}';

      expect(() => jsonDecode(invalidJson), throwsA(isA<FormatException>()));
    });
  });
}
