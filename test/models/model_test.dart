import 'package:flutter_test/flutter_test.dart';
import 'package:awan_cash/models/wallet.dart';
import 'package:awan_cash/models/category.dart';
import 'package:awan_cash/models/transaction_entry.dart';
import 'package:awan_cash/models/budget.dart';

void main() {
  group('Wallet Model', () {
    test('toMap() includes all fields when id is present', () {
      const wallet = Wallet(
        id: 1,
        name: 'BCA Utama',
        type: WalletType.bank,
        initialBalance: 5000000,
        color: 0xFF1E40AF,
        icon: 'account_balance',
      );

      final map = wallet.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'BCA Utama');
      expect(map['type'], 'bank');
      expect(map['initial_balance'], 5000000);
      expect(map['color'], 0xFF1E40AF);
      expect(map['icon'], 'account_balance');
    });

    test('toMap() omits id when id is null', () {
      const wallet = Wallet(
        name: 'Dompet Tunai',
        type: WalletType.cash,
        initialBalance: 100000,
        color: 0xFF10B981,
        icon: 'payments',
      );

      final map = wallet.toMap();

      expect(map.containsKey('id'), isFalse);
      expect(map['name'], 'Dompet Tunai');
      expect(map['type'], 'cash');
    });

    test('fromMap() constructs valid Wallet object with all fields', () {
      final map = {
        'id': 10,
        'name': 'GoPay',
        'type': 'ewallet',
        'initial_balance': 250000,
        'color': 0xFF00AED6,
        'icon': 'account_balance_wallet',
      };

      final wallet = Wallet.fromMap(map);

      expect(wallet.id, 10);
      expect(wallet.name, 'GoPay');
      expect(wallet.type, WalletType.ewallet);
      expect(wallet.initialBalance, 250000);
      expect(wallet.color, 0xFF00AED6);
      expect(wallet.icon, 'account_balance_wallet');
    });

    test('fromMap() applies defaults when optional map fields are missing or null', () {
      final map = {
        'name': 'Kantong Cadangan',
        'type': 'unknown_type',
      };

      final wallet = Wallet.fromMap(map);

      expect(wallet.id, isNull);
      expect(wallet.name, 'Kantong Cadangan');
      expect(wallet.type, WalletType.cash); // Fallback ke cash
      expect(wallet.initialBalance, 0); // Default 0
      expect(wallet.color, 0xFF0EA5E9); // Default color
      expect(wallet.icon, 'payments'); // Default icon
    });

    test('WalletType enum serialization and deserialization', () {
      for (final type in WalletType.values) {
        final wallet = Wallet(
          name: 'Test ${type.name}',
          type: type,
          color: 0,
          icon: 'icon',
        );
        final map = wallet.toMap();
        expect(map['type'], type.name);

        final deserialized = Wallet.fromMap(map);
        expect(deserialized.type, type);
      }
    });

    test('copyWith updates specified fields and preserves existing fields', () {
      const original = Wallet(
        id: 1,
        name: 'Dompet Fisik',
        type: WalletType.cash,
        initialBalance: 50000,
        color: 0xFF123456,
        icon: 'wallet',
      );

      final updated = original.copyWith(
        name: 'Dompet Saku',
        initialBalance: 150000,
      );

      expect(updated.id, 1);
      expect(updated.name, 'Dompet Saku');
      expect(updated.type, WalletType.cash);
      expect(updated.initialBalance, 150000);
      expect(updated.color, 0xFF123456);
      expect(updated.icon, 'wallet');
    });
  });

  group('Category Model', () {
    test('toMap() includes all fields when id is present', () {
      const category = Category(
        id: 5,
        name: 'Makanan & Minuman',
        type: TransactionType.expense,
        icon: 'restaurant',
        color: 0xFFEF4444,
      );

      final map = category.toMap();

      expect(map['id'], 5);
      expect(map['name'], 'Makanan & Minuman');
      expect(map['type'], 'expense');
      expect(map['icon'], 'restaurant');
      expect(map['color'], 0xFFEF4444);
    });

    test('toMap() omits id when id is null', () {
      const category = Category(
        name: 'Gaji Bulanan',
        type: TransactionType.income,
        icon: 'work',
        color: 0xFF10B981,
      );

      final map = category.toMap();

      expect(map.containsKey('id'), isFalse);
      expect(map['name'], 'Gaji Bulanan');
      expect(map['type'], 'income');
    });

    test('fromMap() constructs valid Category object', () {
      final map = {
        'id': 3,
        'name': 'Bonus',
        'type': 'income',
        'icon': 'card_giftcard',
        'color': 0xFF22C55E,
      };

      final category = Category.fromMap(map);

      expect(category.id, 3);
      expect(category.name, 'Bonus');
      expect(category.type, TransactionType.income);
      expect(category.icon, 'card_giftcard');
      expect(category.color, 0xFF22C55E);
    });

    test('fromMap() uses default values when fields are missing or unknown', () {
      final map = {
        'name': 'Kategori Lain',
        'type': 'invalid_type',
      };

      final category = Category.fromMap(map);

      expect(category.id, isNull);
      expect(category.name, 'Kategori Lain');
      expect(category.type, TransactionType.expense); // Fallback ke expense
      expect(category.icon, 'category'); // Default icon
      expect(category.color, 0xFF0EA5E9); // Default color
    });

    test('TransactionType serialization/deserialization for Category', () {
      final testTypes = [TransactionType.expense, TransactionType.income];
      for (final type in testTypes) {
        final category = Category(
          name: 'Cat ${type.name}',
          type: type,
          icon: 'icon',
          color: 0,
        );
        final map = category.toMap();
        expect(map['type'], type.name);

        final deserialized = Category.fromMap(map);
        expect(deserialized.type, type);
      }
    });

    test('copyWith updates specified fields and preserves existing fields', () {
      const original = Category(
        id: 2,
        name: 'Belanja',
        type: TransactionType.expense,
        icon: 'shopping_cart',
        color: 0xFFF59E0B,
      );

      final updated = original.copyWith(
        name: 'Belanja Bulanan',
        color: 0xFF3B82F6,
      );

      expect(updated.id, 2);
      expect(updated.name, 'Belanja Bulanan');
      expect(updated.type, TransactionType.expense);
      expect(updated.icon, 'shopping_cart');
      expect(updated.color, 0xFF3B82F6);
    });
  });

  group('TransactionEntry Model', () {
    final testDate = DateTime(2026, 11, 19, 14, 30, 45);

    test('toMap() includes all fields when populated', () {
      final entry = TransactionEntry(
        id: 42,
        type: TransactionType.transfer,
        amount: 500000,
        walletId: 1,
        toWalletId: 2,
        categoryId: null,
        dateTime: testDate,
        notes: 'Transfer uang kas',
        receiptPath: '/storage/receipt_42.jpg',
      );

      final map = entry.toMap();

      expect(map['id'], 42);
      expect(map['type'], 'transfer');
      expect(map['amount'], 500000);
      expect(map['wallet_id'], 1);
      expect(map['to_wallet_id'], 2);
      expect(map['category_id'], isNull);
      expect(map['date_time'], testDate.toIso8601String());
      expect(map['notes'], 'Transfer uang kas');
      expect(map['receipt_path'], '/storage/receipt_42.jpg');
    });

    test('toMap() omits id when id is null', () {
      final entry = TransactionEntry(
        type: TransactionType.expense,
        amount: 25000,
        walletId: 1,
        categoryId: 3,
        dateTime: testDate,
      );

      final map = entry.toMap();

      expect(map.containsKey('id'), isFalse);
      expect(map['amount'], 25000);
      expect(map['to_wallet_id'], isNull);
      expect(map['notes'], isNull);
      expect(map['receipt_path'], isNull);
    });

    test('fromMap() constructs valid TransactionEntry and parses ISO8601 date', () {
      final map = {
        'id': 100,
        'type': 'income',
        'amount': 7500000,
        'wallet_id': 2,
        'to_wallet_id': null,
        'category_id': 4,
        'date_time': '2026-11-19T14:30:45.000',
        'notes': 'Gaji Proyek',
        'receipt_path': null,
      };

      final entry = TransactionEntry.fromMap(map);

      expect(entry.id, 100);
      expect(entry.type, TransactionType.income);
      expect(entry.amount, 7500000);
      expect(entry.walletId, 2);
      expect(entry.toWalletId, isNull);
      expect(entry.categoryId, 4);
      expect(entry.dateTime, DateTime.parse('2026-11-19T14:30:45.000'));
      expect(entry.notes, 'Gaji Proyek');
      expect(entry.receiptPath, isNull);
    });

    test('fromMap() handles num to int casting and fallback for unknown type', () {
      final map = {
        'id': 1,
        'type': 'unsupported_type',
        'amount': 15000.0, // Double cast ke int
        'wallet_id': 1.0,
        'to_wallet_id': 2.0,
        'category_id': 3.0,
        'date_time': testDate.toIso8601String(),
      };

      final entry = TransactionEntry.fromMap(map);

      expect(entry.type, TransactionType.expense); // Fallback ke expense
      expect(entry.amount, 15000);
      expect(entry.walletId, 1);
      expect(entry.toWalletId, 2);
      expect(entry.categoryId, 3);
    });

    test('TransactionType serialization across all types', () {
      for (final type in TransactionType.values) {
        final entry = TransactionEntry(
          type: type,
          amount: 1000,
          walletId: 1,
          dateTime: testDate,
        );
        final map = entry.toMap();
        expect(map['type'], type.name);

        final deserialized = TransactionEntry.fromMap(map);
        expect(deserialized.type, type);
      }
    });

    test('copyWith updates specified fields and preserves existing fields', () {
      final original = TransactionEntry(
        id: 7,
        type: TransactionType.expense,
        amount: 45000,
        walletId: 1,
        categoryId: 2,
        dateTime: testDate,
        notes: 'Makan siang',
        receiptPath: '/path/struk.jpg',
      );

      final updated = original.copyWith(
        amount: 50000,
        notes: 'Makan siang + es teh',
      );

      expect(updated.id, 7);
      expect(updated.type, TransactionType.expense);
      expect(updated.amount, 50000);
      expect(updated.walletId, 1);
      expect(updated.categoryId, 2);
      expect(updated.dateTime, testDate);
      expect(updated.notes, 'Makan siang + es teh');
      expect(updated.receiptPath, '/path/struk.jpg');
    });
  });

  group('Budget Model', () {
    test('toMap() includes all fields when id is present', () {
      const budget = Budget(
        id: 12,
        categoryId: 3,
        monthlyLimit: 1500000,
        monthYear: '2026-11',
      );

      final map = budget.toMap();

      expect(map['id'], 12);
      expect(map['category_id'], 3);
      expect(map['monthly_limit'], 1500000);
      expect(map['month_year'], '2026-11');
    });

    test('toMap() omits id when id is null', () {
      const budget = Budget(
        categoryId: 3,
        monthlyLimit: 2000000,
        monthYear: '2026-11',
      );

      final map = budget.toMap();

      expect(map.containsKey('id'), isFalse);
      expect(map['category_id'], 3);
      expect(map['monthly_limit'], 2000000);
      expect(map['month_year'], '2026-11');
    });

    test('fromMap() correctly reconstructs Budget', () {
      final map = {
        'id': 8,
        'category_id': 2,
        'monthly_limit': 1200000,
        'month_year': '2026-12',
      };

      final budget = Budget.fromMap(map);

      expect(budget.id, 8);
      expect(budget.categoryId, 2);
      expect(budget.monthlyLimit, 1200000);
      expect(budget.monthYear, '2026-12');
    });

    test('copyWith updates specified fields and preserves existing fields', () {
      const original = Budget(
        id: 1,
        categoryId: 5,
        monthlyLimit: 1000000,
        monthYear: '2026-11',
      );

      final updated = original.copyWith(
        monthlyLimit: 1500000,
      );

      expect(updated.id, 1);
      expect(updated.categoryId, 5);
      expect(updated.monthlyLimit, 1500000);
      expect(updated.monthYear, '2026-11');
    });

    group('progressRatio logic', () {
      const budget = Budget(
        categoryId: 1,
        monthlyLimit: 1000000,
        monthYear: '2026-11',
      );

      test('returns 0.0 when spentAmount is 0', () {
        expect(budget.progressRatio(0), 0.0);
      });

      test('returns correct fractional ratio for partial spending', () {
        expect(budget.progressRatio(250000), closeTo(0.25, 0.001));
        expect(budget.progressRatio(500000), closeTo(0.50, 0.001));
        expect(budget.progressRatio(750000), closeTo(0.75, 0.001));
      });

      test('returns 1.0 when spentAmount equals monthlyLimit exactly', () {
        expect(budget.progressRatio(1000000), 1.0);
      });

      test('clamps to 1.0 when spentAmount exceeds monthlyLimit', () {
        expect(budget.progressRatio(1500000), 1.0);
        expect(budget.progressRatio(2000000), 1.0);
      });

      test('returns 0.0 when monthlyLimit is 0 or negative (guard zero division)', () {
        const zeroBudget = Budget(categoryId: 1, monthlyLimit: 0, monthYear: '2026-11');
        const negativeBudget = Budget(categoryId: 1, monthlyLimit: -500, monthYear: '2026-11');

        expect(zeroBudget.progressRatio(100000), 0.0);
        expect(negativeBudget.progressRatio(100000), 0.0);
      });
    });

    group('isOverBudget logic', () {
      const budget = Budget(
        categoryId: 1,
        monthlyLimit: 1000000,
        monthYear: '2026-11',
      );

      test('returns false when spentAmount is strictly less than limit', () {
        expect(budget.isOverBudget(0), isFalse);
        expect(budget.isOverBudget(999999), isFalse);
      });

      test('returns false when spentAmount equals limit', () {
        expect(budget.isOverBudget(1000000), isFalse);
      });

      test('returns true when spentAmount exceeds limit', () {
        expect(budget.isOverBudget(1000001), isTrue);
        expect(budget.isOverBudget(1500000), isTrue);
      });
    });

    group('remainingAmount logic', () {
      const budget = Budget(
        categoryId: 1,
        monthlyLimit: 1000000,
        monthYear: '2026-11',
      );

      test('returns positive remaining amount when under budget', () {
        expect(budget.remainingAmount(300000), 700000);
      });

      test('returns 0 when spent amount equals limit', () {
        expect(budget.remainingAmount(1000000), 0);
      });

      test('returns negative deficit when over budget', () {
        expect(budget.remainingAmount(1200000), -200000);
      });
    });
  });
}
