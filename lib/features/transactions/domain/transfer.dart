import '../../../core/dates/date_utils.dart';
import '../../../core/money/money.dart';
import '../../accounts/domain/account.dart';

class AccountTransfer {
  final String id;
  final String userId;
  final String fromAccountId;
  final String toAccountId;
  final Money amount;
  final String currencyCode;
  final DateTime transferDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined presentation data
  final Account? fromAccount;
  final Account? toAccount;

  const AccountTransfer({
    required this.id,
    required this.userId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.currencyCode,
    required this.transferDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.fromAccount,
    this.toAccount,
  });

  AccountTransfer copyWith({
    String? id,
    String? userId,
    String? fromAccountId,
    String? toAccountId,
    Money? amount,
    String? currencyCode,
    DateTime? transferDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Account? fromAccount,
    Account? toAccount,
  }) {
    return AccountTransfer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      transferDate: transferDate ?? this.transferDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fromAccount: fromAccount ?? this.fromAccount,
      toAccount: toAccount ?? this.toAccount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'from_account_id': fromAccountId,
        'to_account_id': toAccountId,
        'amount': amount.amount.toString(),
        'currency_code': currencyCode,
        'transfer_date': AppDateUtils.toIsoDate(transferDate),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory AccountTransfer.fromJson(Map<String, dynamic> json) {
    final currency = json['currency_code'] as String;
    return AccountTransfer(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fromAccountId: json['from_account_id'] as String,
      toAccountId: json['to_account_id'] as String,
      amount: Money.parse(json['amount'].toString(), currency),
      currencyCode: currency,
      transferDate: AppDateUtils.parseIsoDate(json['transfer_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
