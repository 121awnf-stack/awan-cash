import 'category.dart';
export 'category.dart' show TransactionType;

class TransactionEntry {
  final int? id;
  final TransactionType type;
  final int amount; // dalam Rupiah
  final int walletId; // Dompet asal
  final int? toWalletId; // Dompet tujuan (khusus transfer)
  final int? categoryId; // Kategori (khusus pemasukan & pengeluaran)
  final DateTime dateTime;
  final String? notes;
  final String? receiptPath;

  const TransactionEntry({
    this.id,
    required this.type,
    required this.amount,
    required this.walletId,
    this.toWalletId,
    this.categoryId,
    required this.dateTime,
    this.notes,
    this.receiptPath,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.name,
      'amount': amount,
      'wallet_id': walletId,
      'to_wallet_id': toWalletId,
      'category_id': categoryId,
      'date_time': dateTime.toIso8601String(),
      'notes': notes,
      'receipt_path': receiptPath,
    };
  }

  factory TransactionEntry.fromMap(Map<String, dynamic> map) {
    return TransactionEntry(
      id: map['id'] as int?,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (map['amount'] as num).toInt(),
      walletId: (map['wallet_id'] as num).toInt(),
      toWalletId: (map['to_wallet_id'] as num?)?.toInt(),
      categoryId: (map['category_id'] as num?)?.toInt(),
      dateTime: DateTime.parse(map['date_time'] as String),
      notes: map['notes'] as String?,
      receiptPath: map['receipt_path'] as String?,
    );
  }

  TransactionEntry copyWith({
    int? id,
    TransactionType? type,
    int? amount,
    int? walletId,
    int? toWalletId,
    int? categoryId,
    DateTime? dateTime,
    String? notes,
    String? receiptPath,
  }) {
    return TransactionEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      categoryId: categoryId ?? this.categoryId,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      receiptPath: receiptPath ?? this.receiptPath,
    );
  }
}
