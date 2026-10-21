import '../../../core/dates/date_utils.dart';
import '../../../core/money/money.dart';
import '../../../shared/models/category.dart';

class BudgetCategory {
  final String id;
  final String userId;
  final String budgetId;
  final String categoryId;
  final Money allocatedAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  final Category? category;

  const BudgetCategory({
    required this.id,
    required this.userId,
    required this.budgetId,
    required this.categoryId,
    required this.allocatedAmount,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'budget_id': budgetId,
        'category_id': categoryId,
        'allocated_amount': allocatedAmount.amount.toString(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory BudgetCategory.fromJson(Map<String, dynamic> json, String currency) {
    return BudgetCategory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      budgetId: json['budget_id'] as String,
      categoryId: json['category_id'] as String,
      allocatedAmount: Money.parse(json['allocated_amount'].toString(), currency),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['categories'] != null ? Category.fromJson(json['categories'] as Map<String, dynamic>) : null,
    );
  }
}

class Budget {
  final String id;
  final String userId;
  final String name;
  final Money amount;
  final String currencyCode;
  final String periodType; // 'daily' | 'weekly' | 'monthly' | 'yearly' | 'custom'
  final DateTime startDate;
  final DateTime? endDate;
  final List<double> alertThresholds;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BudgetCategory> categories;

  const Budget({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.currencyCode,
    required this.periodType,
    required this.startDate,
    this.endDate,
    this.alertThresholds = const [0.8, 1.0],
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.categories = const [],
  });

  Budget copyWith({
    String? id,
    String? userId,
    String? name,
    Money? amount,
    String? currencyCode,
    String? periodType,
    DateTime? startDate,
    DateTime? endDate,
    List<double>? alertThresholds,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<BudgetCategory>? categories,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      alertThresholds: alertThresholds ?? this.alertThresholds,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'amount': amount.amount.toString(),
        'currency_code': currencyCode,
        'period_type': periodType,
        'start_date': AppDateUtils.toIsoDate(startDate),
        'end_date': endDate != null ? AppDateUtils.toIsoDate(endDate!) : null,
        'alert_thresholds': alertThresholds,
        'is_archived': isArchived,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Budget.fromJson(Map<String, dynamic> json) {
    final currency = json['currency_code'] as String;
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      amount: Money.parse(json['amount'].toString(), currency),
      currencyCode: currency,
      periodType: json['period_type'] as String,
      startDate: AppDateUtils.parseIsoDate(json['start_date'] as String),
      endDate: json['end_date'] != null ? AppDateUtils.parseIsoDate(json['end_date'] as String) : null,
      alertThresholds: (json['alert_thresholds'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [0.8, 1.0],
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      categories: (json['budget_categories'] as List<dynamic>?)
              ?.map((e) => BudgetCategory.fromJson(e as Map<String, dynamic>, currency))
              .toList() ??
          const [],
    );
  }
}
