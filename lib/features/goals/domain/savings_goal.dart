import '../../../core/dates/date_utils.dart';
import '../../../core/money/money.dart';

class GoalContribution {
  final String id;
  final String userId;
  final String goalId;
  final Money amount;
  final String contributionType; // 'contribution' | 'withdrawal'
  final DateTime contributionDate;
  final String? notes;
  final DateTime createdAt;

  const GoalContribution({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.amount,
    required this.contributionType,
    required this.contributionDate,
    this.notes,
    required this.createdAt,
  });

  bool get isContribution => contributionType == 'contribution';
  bool get isWithdrawal => contributionType == 'withdrawal';

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'goal_id': goalId,
        'amount': amount.amount.toString(),
        'contribution_type': contributionType,
        'contribution_date': AppDateUtils.toIsoDate(contributionDate),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory GoalContribution.fromJson(Map<String, dynamic> json, String currency) {
    return GoalContribution(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalId: json['goal_id'] as String,
      amount: Money.parse(json['amount'].toString(), currency),
      contributionType: json['contribution_type'] as String,
      contributionDate: AppDateUtils.parseIsoDate(json['contribution_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SavingsGoal {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final Money targetAmount;
  final String currencyCode;
  final DateTime? targetDate;
  final String? iconKey;
  final String status; // 'active' | 'completed' | 'paused' | 'archived'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed or aggregated current saved amount
  final Money? computedSaved;
  final List<GoalContribution> contributions;

  const SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.targetAmount,
    required this.currencyCode,
    this.targetDate,
    this.iconKey,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.computedSaved,
    this.contributions = const [],
  });

  Money get currentSaved => computedSaved ?? Money.zero(currencyCode);

  bool get isCompleted => status == 'completed' || currentSaved >= targetAmount;

  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    Money? targetAmount,
    String? currencyCode,
    DateTime? targetDate,
    String? iconKey,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Money? computedSaved,
    List<GoalContribution>? contributions,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      targetDate: targetDate ?? this.targetDate,
      iconKey: iconKey ?? this.iconKey,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      computedSaved: computedSaved ?? this.computedSaved,
      contributions: contributions ?? this.contributions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'description': description,
        'target_amount': targetAmount.amount.toString(),
        'currency_code': currencyCode,
        'target_date': targetDate != null ? AppDateUtils.toIsoDate(targetDate!) : null,
        'icon_key': iconKey,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    final currency = json['currency_code'] as String;
    return SavingsGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      targetAmount: Money.parse(json['target_amount'].toString(), currency),
      currencyCode: currency,
      targetDate: json['target_date'] != null ? AppDateUtils.parseIsoDate(json['target_date'] as String) : null,
      iconKey: json['icon_key'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      contributions: (json['goal_contributions'] as List<dynamic>?)
              ?.map((e) => GoalContribution.fromJson(e as Map<String, dynamic>, currency))
              .toList() ??
          const [],
    );
  }
}
