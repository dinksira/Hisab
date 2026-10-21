import '../../../core/dates/date_utils.dart';
import '../../../core/money/money.dart';
import '../../../shared/models/category.dart';
import '../../accounts/domain/account.dart';

class FinancialTransaction {
  final String id;
  final String userId;
  final String? accountId;
  final String? categoryId;
  final String transactionType; // 'expense' | 'income'
  final Money amount;
  final String currencyCode;
  final String description;
  final DateTime transactionDate;
  final String? notes;
  final String? merchant;
  final List<String> tags;
  final String? recurringTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined presentation data
  final Category? category;
  final Account? account;

  const FinancialTransaction({
    required this.id,
    required this.userId,
    this.accountId,
    this.categoryId,
    required this.transactionType,
    required this.amount,
    required this.currencyCode,
    required this.description,
    required this.transactionDate,
    this.notes,
    this.merchant,
    this.tags = const [],
    this.recurringTransactionId,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.account,
  });

  bool get isExpense => transactionType == 'expense';
  bool get isIncome => transactionType == 'income';

  FinancialTransaction copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? categoryId,
    String? transactionType,
    Money? amount,
    String? currencyCode,
    String? description,
    DateTime? transactionDate,
    String? notes,
    String? merchant,
    List<String>? tags,
    String? recurringTransactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
    Account? account,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      notes: notes ?? this.notes,
      merchant: merchant ?? this.merchant,
      tags: tags ?? this.tags,
      recurringTransactionId: recurringTransactionId ?? this.recurringTransactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      account: account ?? this.account,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'account_id': accountId,
        'category_id': categoryId,
        'transaction_type': transactionType,
        'amount': amount.amount.toString(),
        'currency_code': currencyCode,
        'description': description,
        'transaction_date': AppDateUtils.toIsoDate(transactionDate),
        'notes': notes,
        'merchant': merchant,
        'tags': tags,
        'recurring_transaction_id': recurringTransactionId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    final currency = json['currency_code'] as String;
    return FinancialTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountId: json['account_id'] as String?,
      categoryId: json['category_id'] as String?,
      transactionType: json['transaction_type'] as String,
      amount: Money.parse(json['amount'].toString(), currency),
      currencyCode: currency,
      description: json['description'] as String,
      transactionDate: AppDateUtils.parseIsoDate(json['transaction_date'] as String),
      notes: json['notes'] as String?,
      merchant: json['merchant'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      recurringTransactionId: json['recurring_transaction_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['categories'] != null ? Category.fromJson(json['categories'] as Map<String, dynamic>) : null,
      account: json['accounts'] != null ? Account.fromJson(json['accounts'] as Map<String, dynamic>) : null,
    );
  }
}
