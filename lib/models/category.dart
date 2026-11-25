enum TransactionType { expense, income, transfer }

class Category {
  final int? id;
  final String name;
  final TransactionType type; // expense atau income
  final String icon;
  final int color;

  const Category({
    this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.name,
      'icon': icon,
      'color': color,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      icon: (map['icon'] as String?) ?? 'category',
      color: (map['color'] as num?)?.toInt() ?? 0xFF0EA5E9,
    );
  }

  Category copyWith({
    int? id,
    String? name,
    TransactionType? type,
    String? icon,
    int? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
