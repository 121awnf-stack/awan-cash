enum WalletType { cash, bank, ewallet }

class Wallet {
  final int? id;
  final String name;
  final WalletType type;
  final int initialBalance;
  final int color;
  final String icon;

  const Wallet({
    this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0,
    required this.color,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.name,
      'initial_balance': initialBalance,
      'color': color,
      'icon': icon,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: WalletType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WalletType.cash,
      ),
      initialBalance: (map['initial_balance'] as num?)?.toInt() ?? 0,
      color: (map['color'] as num?)?.toInt() ?? 0xFF0EA5E9,
      icon: (map['icon'] as String?) ?? 'payments',
    );
  }

  Wallet copyWith({
    int? id,
    String? name,
    WalletType? type,
    int? initialBalance,
    int? color,
    String? icon,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}
