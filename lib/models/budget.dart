class Budget {
  final int? id;
  final int categoryId;
  final int monthlyLimit; // Batas bulanan dalam rupiah
  final String monthYear; // Format 'YYYY-MM', misal '2026-11'

  const Budget({
    this.id,
    required this.categoryId,
    required this.monthlyLimit,
    required this.monthYear,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'monthly_limit': monthlyLimit,
      'month_year': monthYear,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      categoryId: (map['category_id'] as num).toInt(),
      monthlyLimit: (map['monthly_limit'] as num).toInt(),
      monthYear: map['month_year'] as String,
    );
  }

  Budget copyWith({
    int? id,
    int? categoryId,
    int? monthlyLimit,
    String? monthYear,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      monthYear: monthYear ?? this.monthYear,
    );
  }

  /// Rasio pengeluaran terhadap batas anggaran (0.0 sampai 1.0).
  double progressRatio(int spentAmount) {
    if (monthlyLimit <= 0) return 0.0;
    return (spentAmount / monthlyLimit).clamp(0.0, 1.0);
  }

  /// Menentukan apakah pengeluaran telah melebihi batas anggaran bulanan.
  bool isOverBudget(int spentAmount) {
    return spentAmount > monthlyLimit;
  }

  /// Sisa anggaran yang tersedia (bisa bernilai negatif jika over budget).
  int remainingAmount(int spentAmount) {
    return monthlyLimit - spentAmount;
  }
}
