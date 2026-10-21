import '../../../core/money/money.dart';

class Account {
  final String id;
  final String userId;
  final String name;
  final String accountType; // 'cash' | 'checking' | 'savings' | 'wallet' | 'other'
  final String currencyCode;
  final Money openingBalance;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Computed balance after applying qualifying transactions and transfers
  final Money? computedBalance;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.accountType,
    required this.currencyCode,
    required this.openingBalance,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.computedBalance,
  });

  Money get currentBalance => computedBalance ?? openingBalance;

  Account copyWith({
    String? id,
    String? userId,
    String? name,
    String? accountType,
    String? currencyCode,
    Money? openingBalance,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    Money? computedBalance,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      currencyCode: currencyCode ?? this.currencyCode,
      openingBalance: openingBalance ?? this.openingBalance,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      computedBalance: computedBalance ?? this.computedBalance,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'account_type': accountType,
        'currency_code': currencyCode,
        'opening_balance': openingBalance.amount.toString(),
        'is_archived': isArchived,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Account.fromJson(Map<String, dynamic> json) {
    final currency = json['currency_code'] as String;
    return Account(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      accountType: json['account_type'] as String,
      currencyCode: currency,
      openingBalance: Money.parse(json['opening_balance'].toString(), currency),
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
