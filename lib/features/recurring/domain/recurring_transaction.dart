import '../../../core/dates/date_utils.dart';
import '../../../core/money/money.dart';
import '../../../shared/models/category.dart';
import '../../accounts/domain/account.dart';

class RecurringTransaction {
  final String id;
  final String userId;
  final String? accountId;
  final String? categoryId;
  final String transactionType; // 'expense' | 'income'
  final Money amount;
  final String currencyCode;
  final String description;
  final String frequency; // 'daily' | 'weekly' | 'monthly' | 'yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextExpectedDate;
  final String status; // 'active' | 'paused' | 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;

  final Category? category;
  final Account? account;

  const RecurringTransaction({
    required this.id,
    required this.userId,
    this.accountId,
    this.categoryId,
    required this.transactionType,
    required this.amount,
    required this.currencyCode,
    required this.description,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextExpectedDate,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.account,
  });

  bool get isActive => status == 'active';
  bool get isExpense => transactionType == 'expense';
  bool get isIncome => transactionType == 'income';

  /// Calculate the subsequent expected date based on frequency
  DateTime computeNextDateAfter(DateTime fromDate) {
    switch (frequency) {
      case 'daily':
        return fromDate.add(const Duration(days: 1));
      case 'weekly':
        return fromDate.add(const Duration(days: 7));
      case 'monthly':
        final nextMonth = fromDate.month == 12 ? 1 : fromDate.month + 1;
        final nextYear = fromDate.month == 12 ? fromDate.year + 1 : fromDate.year;
        // handle month end (e.g. Jan 31 -> Feb 28)
        final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final day = fromDate.day > lastDayOfNextMonth ? lastDayOfNextMonth : fromDate.day;
        return DateTime(nextYear, nextMonth, day);
      case 'yearly':
        final isLeapFeb29 = fromDate.month == 2 && fromDate.day == 29;
        final day = isLeapFeb29 ? 28 : fromDate.day;
        return DateTime(fromDate.year + 1, fromDate.month, day);
      default:
        return fromDate.add(const Duration(days: 30));
    }
  }

  RecurringTransaction copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? categoryId,
    String? transactionType,
    Money? amount,
    String? currencyCode,
    String? description,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextExpectedDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
    Account? account,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextExpectedDate: nextExpectedDate ?? this.nextExpectedDate,
      status: status ?? this.status,
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
        'frequency': frequency,
        'start_date': AppDateUtils.toIsoDate(startDate),
        'end_date': endDate != null ? AppDateUtils.toIsoDate(endDate!) : null,
        'next_expected_date': AppDateUtils.toIsoDate(nextExpectedDate),
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    final currency = json['currency_code'] as String;
    return RecurringTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountId: json['account_id'] as String?,
      categoryId: json['category_id'] as String?,
      transactionType: json['transaction_type'] as String,
      amount: Money.parse(json['amount'].toString(), currency),
      currencyCode: currency,
      description: json['description'] as String,
      frequency: json['frequency'] as String,
      startDate: AppDateUtils.parseIsoDate(json['start_date'] as String),
      endDate: json['end_date'] != null ? AppDateUtils.parseIsoDate(json['end_date'] as String) : null,
      nextExpectedDate: AppDateUtils.parseIsoDate(json['next_expected_date'] as String),
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['categories'] != null ? Category.fromJson(json['categories'] as Map<String, dynamic>) : null,
      account: json['accounts'] != null ? Account.fromJson(json['accounts'] as Map<String, dynamic>) : null,
    );
  }
}
