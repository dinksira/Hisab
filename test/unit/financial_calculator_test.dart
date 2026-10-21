import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money/financial_calculator.dart';
import 'package:hisab/core/money/money.dart';

void main() {
  group('FinancialCalculator tests', () {
    test('Calculates account balance with opening balance, income, expenses, and transfers', () {
      final opening = Money.parse('1000.00', 'USD');
      final income = [Money.parse('500.00', 'USD'), Money.parse('250.00', 'USD')];
      final expenses = [Money.parse('300.00', 'USD'), Money.parse('50.00', 'USD')];
      final incomingTransfers = [Money.parse('100.00', 'USD')];
      final outgoingTransfers = [Money.parse('200.00', 'USD')];

      final balance = FinancialCalculator.calculateAccountBalance(
        openingBalance: opening,
        incomeTransactions: income,
        expenseTransactions: expenses,
        incomingTransfers: incomingTransfers,
        outgoingTransfers: outgoingTransfers,
      );

      // 1000 + 750 - 350 + 100 - 200 = 1300.00
      expect(balance, equals(Money.parse('1300.00', 'USD')));
    });

    test('Allows negative account balances (overdraft / debt)', () {
      final opening = Money.parse('50.00', 'USD');
      final expenses = [Money.parse('150.00', 'USD')];

      final balance = FinancialCalculator.calculateAccountBalance(
        openingBalance: opening,
        incomeTransactions: [],
        expenseTransactions: expenses,
        incomingTransfers: [],
        outgoingTransfers: [],
      );

      expect(balance, equals(Money.parse('-100.00', 'USD')));
      expect(balance.isNegative, isTrue);
    });

    test('Net cash flow excludes transfers and reflects income minus expenses', () {
      final income = [Money.parse('2000.00', 'USD')];
      final expenses = [Money.parse('800.00', 'USD'), Money.parse('200.00', 'USD')];

      final netFlow = FinancialCalculator.calculateNetCashFlow(
        currency: 'USD',
        incomeTransactions: income,
        expenseTransactions: expenses,
      );

      expect(netFlow, equals(Money.parse('1000.00', 'USD')));
    });

    test('Calculates budget progress and detects over-budget state', () {
      final budgetLimit = Money.parse('500.00', 'USD');
      final expensesUnder = [Money.parse('200.00', 'USD'), Money.parse('150.00', 'USD')];

      final underResult = FinancialCalculator.calculateBudgetProgress(
        budgetLimit: budgetLimit,
        qualifyingExpenses: expensesUnder,
      );

      expect(underResult.spent, equals(Money.parse('350.00', 'USD')));
      expect(underResult.remaining, equals(Money.parse('150.00', 'USD')));
      expect(underResult.progress, closeTo(0.70, 0.001));
      expect(underResult.isOverBudget, isFalse);

      final expensesOver = [Money.parse('400.00', 'USD'), Money.parse('250.00', 'USD')];
      final overResult = FinancialCalculator.calculateBudgetProgress(
        budgetLimit: budgetLimit,
        qualifyingExpenses: expensesOver,
      );

      expect(overResult.spent, equals(Money.parse('650.00', 'USD')));
      expect(overResult.remaining, equals(Money.parse('-150.00', 'USD')));
      expect(overResult.progress, closeTo(1.30, 0.001));
      expect(overResult.isOverBudget, isTrue);
    });

    test('Calculates savings goal progress with contributions and withdrawals', () {
      final target = Money.parse('5000.00', 'USD');
      final contributions = [Money.parse('1000.00', 'USD'), Money.parse('1500.00', 'USD')];
      final withdrawals = [Money.parse('500.00', 'USD')];

      final result = FinancialCalculator.calculateGoalProgress(
        targetAmount: target,
        contributions: contributions,
        withdrawals: withdrawals,
      );

      // 1000 + 1500 - 500 = 2000.00 (40%)
      expect(result.currentSaved, equals(Money.parse('2000.00', 'USD')));
      expect(result.remainingTarget, equals(Money.parse('3000.00', 'USD')));
      expect(result.progress, closeTo(0.40, 0.001));
      expect(result.isCompleted, isFalse);
    });

    test('Calculates category percentage distribution accurately', () {
      final totals = {
        'groceries': Money.parse('300.00', 'USD'),
        'rent': Money.parse('600.00', 'USD'),
        'utilities': Money.parse('100.00', 'USD'),
      };

      final breakdown = FinancialCalculator.calculateCategoryPercentages(categoryTotals: totals);

      expect(breakdown['groceries'], closeTo(0.30, 0.001));
      expect(breakdown['rent'], closeTo(0.60, 0.001));
      expect(breakdown['utilities'], closeTo(0.10, 0.001));
    });
  });
}
