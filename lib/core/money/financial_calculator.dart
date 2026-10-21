import 'package:decimal/decimal.dart';
import 'money.dart';

/// Calculation engine for financial aggregations and balances.
/// Pure, deterministic, and testable without UI or database dependencies.
class FinancialCalculator {
  FinancialCalculator._();

  /// Calculates the current balance of an account:
  /// Opening balance + qualifying income - qualifying expenses + incoming transfers - outgoing transfers
  static Money calculateAccountBalance({
    required Money openingBalance,
    required Iterable<Money> incomeTransactions,
    required Iterable<Money> expenseTransactions,
    required Iterable<Money> incomingTransfers,
    required Iterable<Money> outgoingTransfers,
  }) {
    Money balance = openingBalance;

    for (final inc in incomeTransactions) {
      balance = balance + inc;
    }
    for (final exp in expenseTransactions) {
      balance = balance - exp;
    }
    for (final inTransfer in incomingTransfers) {
      balance = balance + inTransfer;
    }
    for (final outTransfer in outgoingTransfers) {
      balance = balance - outTransfer;
    }

    return balance;
  }

  /// Calculates net cash flow:
  /// Total qualifying income - Total qualifying expenses.
  /// Transfers and savings contributions are excluded.
  static Money calculateNetCashFlow({
    required String currency,
    required Iterable<Money> incomeTransactions,
    required Iterable<Money> expenseTransactions,
  }) {
    Money totalIncome = Money.zero(currency);
    Money totalExpense = Money.zero(currency);

    for (final inc in incomeTransactions) {
      totalIncome = totalIncome + inc;
    }
    for (final exp in expenseTransactions) {
      totalExpense = totalExpense + exp;
    }

    return totalIncome - totalExpense;
  }

  /// Calculates budget consumption and remaining allowance.
  /// Returns spending percentage (0.0 to 1.0+), remaining money, and overspend status.
  static ({
    Money spent,
    Money remaining,
    double progress,
    bool isOverBudget,
  }) calculateBudgetProgress({
    required Money budgetLimit,
    required Iterable<Money> qualifyingExpenses,
  }) {
    Money spent = Money.zero(budgetLimit.currency);
    for (final exp in qualifyingExpenses) {
      spent = spent + exp;
    }

    final remaining = budgetLimit - spent;
    final isOverBudget = spent > budgetLimit;

    double progress = 0.0;
    if (!budgetLimit.isZero) {
      progress = (spent.amount / budgetLimit.amount).toDouble();
      if (progress < 0.0) progress = 0.0;
    }

    return (
      spent: spent,
      remaining: remaining,
      progress: progress,
      isOverBudget: isOverBudget,
    );
  }

  /// Calculates savings goal progress:
  /// Current saved = qualifying contributions - qualifying withdrawals.
  static ({
    Money currentSaved,
    Money remainingTarget,
    double progress,
    bool isCompleted,
  }) calculateGoalProgress({
    required Money targetAmount,
    required Iterable<Money> contributions,
    required Iterable<Money> withdrawals,
  }) {
    Money saved = Money.zero(targetAmount.currency);

    for (final c in contributions) {
      saved = saved + c;
    }
    for (final w in withdrawals) {
      saved = saved - w;
    }

    if (saved.isNegative) {
      saved = Money.zero(targetAmount.currency);
    }

    final remaining = targetAmount - saved;
    final isCompleted = saved >= targetAmount;

    double progress = 0.0;
    if (!targetAmount.isZero) {
      progress = (saved.amount / targetAmount.amount).toDouble();
      if (progress < 0.0) progress = 0.0;
      if (progress > 1.0) progress = 1.0;
    }

    return (
      currentSaved: saved,
      remainingTarget: remaining.isNegative ? Money.zero(targetAmount.currency) : remaining,
      progress: progress,
      isCompleted: isCompleted,
    );
  }

  /// Calculates category spending breakdown percentages
  static Map<String, double> calculateCategoryPercentages({
    required Map<String, Money> categoryTotals,
  }) {
    if (categoryTotals.isEmpty) return {};

    Decimal totalSpent = Decimal.zero;
    for (final entry in categoryTotals.values) {
      totalSpent = totalSpent + entry.amount;
    }

    if (totalSpent == Decimal.zero) return {};

    final result = <String, double>{};
    for (final entry in categoryTotals.entries) {
      final ratio = (entry.value.amount / totalSpent).toDouble();
      result[entry.key] = ratio;
    }
    return result;
  }
}
