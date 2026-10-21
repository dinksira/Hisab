class Category {
  final String id;
  final String? userId;
  final String name;
  final String transactionType; // 'expense' | 'income'
  final String iconKey;
  final String? colorHex;
  final bool isSystem;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    this.userId,
    required this.name,
    required this.transactionType,
    required this.iconKey,
    this.colorHex,
    this.isSystem = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpense => transactionType == 'expense';
  bool get isIncome => transactionType == 'income';

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? transactionType,
    String? iconKey,
    String? colorHex,
    bool? isSystem,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      transactionType: transactionType ?? this.transactionType,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      isSystem: isSystem ?? this.isSystem,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'transaction_type': transactionType,
        'icon_key': iconKey,
        'color_hex': colorHex,
        'is_system': isSystem,
        'is_archived': isArchived,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      transactionType: json['transaction_type'] as String,
      iconKey: json['icon_key'] as String,
      colorHex: json['color_hex'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
