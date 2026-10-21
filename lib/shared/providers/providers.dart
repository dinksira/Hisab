import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dates/date_utils.dart';
import '../../core/money/financial_calculator.dart';
import '../../core/money/money.dart';
import '../../data/remote/supabase_client.dart';
import '../../data/repositories/mock_repositories.dart';
import '../../data/repositories/repository_interfaces.dart';
import '../../data/repositories/supabase_repositories.dart';
import '../../features/accounts/domain/account.dart';
import '../../features/auth/data/auth_controller.dart';
import '../../features/auth/data/auth_state.dart';
import '../../features/auth/domain/user_profile.dart';
import '../../features/budgets/domain/budget.dart';
import '../../features/goals/domain/savings_goal.dart';
import '../../features/recurring/domain/recurring_transaction.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/transactions/domain/transfer.dart';
import '../models/category.dart';

extension AsyncValueX<T> on AsyncValue<T> {
  T? get valueOrNull => when(
        data: (data) => data,
        error: (_, _) => null,
        loading: () => null,
      );
}

// --- Repositories Providers ---
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  if (SupabaseService.isInitialized) {
    return SupabaseAuthRepository();
  }
  return MockAuthRepository();
});

final accountRepositoryProvider = Provider<IAccountRepository>((ref) {
  if (SupabaseService.isInitialized) {
    return SupabaseAccountRepository();
  }
  return MockAccountRepository();
});

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  if (SupabaseService.isInitialized) {
    return SupabaseCategoryRepository();
  }
  return MockCategoryRepository();
});

final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  if (SupabaseService.isInitialized) {
    return SupabaseTransactionRepository();
  }
  return MockTransactionRepository();
});

final budgetRepositoryProvider = Provider<IBudgetRepository>((ref) {
  if (SupabaseService.isInitialized) {
    return SupabaseBudgetRepository();
  }
  return MockBudgetRepository();
});

final goalRepositoryProvider = Provider<IGoalRepository>((ref) {
  if (SupabaseService.isInitialized) {
    return SupabaseGoalRepository();
  }
  return MockGoalRepository();
});

final recurringRepositoryProvider = Provider<IRecurringRepository>((ref) {
  if (SupabaseService.isInitialized) {
    return SupabaseRecurringRepository();
  }
  return MockRecurringRepository();
});

// --- UI Preference Providers ---
class PrivacyModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final privacyModeProvider = NotifierProvider<PrivacyModeNotifier, bool>(PrivacyModeNotifier.new);

class SelectedPeriodNotifier extends Notifier<String> {
  @override
  String build() => 'month'; // 'week' | 'month' | 'year'
  void set(String value) => state = value;
}

final selectedPeriodProvider = NotifierProvider<SelectedPeriodNotifier, String>(SelectedPeriodNotifier.new);

// --- Auth State Provider ---
/// True when the application runs against the local mock backend instead of a
/// real Supabase project.
final isDemoModeProvider = Provider<bool>((ref) => !SupabaseService.isInitialized);

/// The error that prevented Supabase from starting, if any.
final supabaseInitErrorProvider = Provider<Object?>((ref) => SupabaseService.initError);

/// Owns the authentication lifecycle and exposes it as [AuthState].
final authControllerProvider = Provider<AuthController>((ref) {
  final controller = AuthController(ref.read(authRepositoryProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

final authStateProvider =
    NotifierProvider<AuthStateNotifier, AuthState>(AuthStateNotifier.new);

class AuthStateNotifier extends Notifier<AuthState> {
  AuthState? _previous;

  @override
  AuthState build() {
    final controller = ref.watch(authControllerProvider);

    final subscription = controller.stream.listen((next) {
      if (!ref.mounted) return;
      _handleTransition(next);
      state = next;
    });
    ref.onDispose(subscription.cancel);

    unawaited(controller.bootstrap());

    return const AuthState.unknown();
  }

  /// Drops every cached value that belonged to the user who just signed out.
  void _handleTransition(AuthState next) {
    final wasSignedIn = _previous?.isAuthenticated ?? false;
    if (wasSignedIn && !next.isAuthenticated) {
      clearUserData(ref);
    }
    _previous = next;
  }
}

/// The profile of the signed-in user, or null when signed out.
final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authStateProvider).profile;
});

/// Invalidates every provider that caches data belonging to the signed-in
/// user so that no stale rows survive a sign-out or an account switch.
void clearUserData(Ref ref) {
  ref.invalidate(accountsListProvider);
  ref.invalidate(categoriesListProvider);
  ref.invalidate(transactionsListProvider);
  ref.invalidate(transfersListProvider);
  ref.invalidate(budgetsListProvider);
  ref.invalidate(savingsGoalsListProvider);
  ref.invalidate(recurringListProvider);
}

// --- Accounts Provider ---
final accountsListProvider = AsyncNotifierProvider<AccountsNotifier, List<Account>>(() {
  return AccountsNotifier();
});

class AccountsNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() async {
    return ref.read(accountRepositoryProvider).getAccounts();
  }

  Future<void> createAccount(Account account) async {
    await ref.read(accountRepositoryProvider).createAccount(account);
    ref.invalidateSelf();
  }

  Future<void> updateAccount(Account account) async {
    await ref.read(accountRepositoryProvider).updateAccount(account);
    ref.invalidateSelf();
  }

  Future<void> deleteAccount(String accountId) async {
    await ref.read(accountRepositoryProvider).deleteAccount(accountId);
    ref.invalidateSelf();
  }
}

// --- Categories Provider ---
final categoriesListProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(() {
  return CategoriesNotifier();
});

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return ref.read(categoryRepositoryProvider).getCategories();
  }

  Future<void> createCategory(Category category) async {
    await ref.read(categoryRepositoryProvider).createCategory(category);
    ref.invalidateSelf();
  }
}

// --- Transactions Provider ---
final transactionsListProvider = AsyncNotifierProvider<TransactionsNotifier, List<FinancialTransaction>>(() {
  return TransactionsNotifier();
});

class TransactionsNotifier extends AsyncNotifier<List<FinancialTransaction>> {
  @override
  Future<List<FinancialTransaction>> build() async {
    return ref.read(transactionRepositoryProvider).getTransactions();
  }

  Future<void> addTransaction(FinancialTransaction tx) async {
    await ref.read(transactionRepositoryProvider).createTransaction(tx);
    ref.invalidateSelf();
    ref.invalidate(accountsListProvider);
  }

  Future<void> updateTransaction(FinancialTransaction tx) async {
    await ref.read(transactionRepositoryProvider).updateTransaction(tx);
    ref.invalidateSelf();
    ref.invalidate(accountsListProvider);
  }

  Future<void> deleteTransaction(String id) async {
    await ref.read(transactionRepositoryProvider).deleteTransaction(id);
    ref.invalidateSelf();
    ref.invalidate(accountsListProvider);
  }
}

// --- Transfers Provider ---
final transfersListProvider = AsyncNotifierProvider<TransfersNotifier, List<AccountTransfer>>(() {
  return TransfersNotifier();
});

class TransfersNotifier extends AsyncNotifier<List<AccountTransfer>> {
  @override
  Future<List<AccountTransfer>> build() async {
    return ref.read(transactionRepositoryProvider).getTransfers();
  }

  Future<void> addTransfer(AccountTransfer transfer) async {
    await ref.read(transactionRepositoryProvider).createTransfer(transfer);
    ref.invalidateSelf();
    ref.invalidate(accountsListProvider);
  }
}

// --- Budgets Provider ---
final budgetsListProvider = AsyncNotifierProvider<BudgetsNotifier, List<Budget>>(() {
  return BudgetsNotifier();
});

class BudgetsNotifier extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    return ref.read(budgetRepositoryProvider).getBudgets();
  }

  Future<void> createBudget(Budget budget, List<BudgetCategory> allocations) async {
    await ref.read(budgetRepositoryProvider).createBudget(budget, allocations);
    ref.invalidateSelf();
  }

  Future<void> updateBudget(Budget budget) async {
    await ref.read(budgetRepositoryProvider).updateBudget(budget);
    ref.invalidateSelf();
  }

  Future<void> deleteBudget(String id) async {
    await ref.read(budgetRepositoryProvider).deleteBudget(id);
    ref.invalidateSelf();
  }
}

// --- Savings Goals Provider ---
final savingsGoalsListProvider = AsyncNotifierProvider<SavingsGoalsNotifier, List<SavingsGoal>>(() {
  return SavingsGoalsNotifier();
});

class SavingsGoalsNotifier extends AsyncNotifier<List<SavingsGoal>> {
  @override
  Future<List<SavingsGoal>> build() async {
    return ref.read(goalRepositoryProvider).getGoals();
  }

  Future<void> createGoal(SavingsGoal goal) async {
    await ref.read(goalRepositoryProvider).createGoal(goal);
    ref.invalidateSelf();
  }

  Future<void> addContribution(GoalContribution contribution) async {
    await ref.read(goalRepositoryProvider).addContribution(contribution);
    ref.invalidateSelf();
  }
}

// --- Recurring Transactions Provider ---
final recurringListProvider = AsyncNotifierProvider<RecurringNotifier, List<RecurringTransaction>>(() {
  return RecurringNotifier();
});

class RecurringNotifier extends AsyncNotifier<List<RecurringTransaction>> {
  @override
  Future<List<RecurringTransaction>> build() async {
    return ref.read(recurringRepositoryProvider).getRecurringTransactions();
  }

  Future<void> addRecurring(RecurringTransaction rec) async {
    await ref.read(recurringRepositoryProvider).createRecurringTransaction(rec);
    ref.invalidateSelf();
  }

  Future<void> deleteRecurring(String id) async {
    await ref.read(recurringRepositoryProvider).deleteRecurringTransaction(id);
    ref.invalidateSelf();
  }
}

// --- Dashboard Summary View Model ---
class DashboardSummary {
  final Money totalBalance;
  final Money periodIncome;
  final Money periodExpense;
  final Money netCashFlow;
  final List<FinancialTransaction> recentTransactions;
  final Budget? activeBudget;
  final ({Money spent, Money remaining, double progress, bool isOverBudget})? budgetProgress;
  final List<SavingsGoal> activeGoals;
  final Map<String, Money> categorySpendTotals;
  final Map<String, double> categorySpendPercentages;

  const DashboardSummary({
    required this.totalBalance,
    required this.periodIncome,
    required this.periodExpense,
    required this.netCashFlow,
    required this.recentTransactions,
    this.activeBudget,
    this.budgetProgress,
    required this.activeGoals,
    required this.categorySpendTotals,
    required this.categorySpendPercentages,
  });
}

final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final accountsAsync = ref.watch(accountsListProvider);
  final txsAsync = ref.watch(transactionsListProvider);
  final budgetsAsync = ref.watch(budgetsListProvider);
  final goalsAsync = ref.watch(savingsGoalsListProvider);
  final userProfile = ref.watch(currentUserProfileProvider);

  final currency = userProfile?.preferredCurrency ?? 'USD';

  final accounts = accountsAsync.valueOrNull ?? [];
  final transactions = txsAsync.valueOrNull ?? [];
  final budgets = budgetsAsync.valueOrNull ?? [];
  final goals = goalsAsync.valueOrNull ?? [];

  // Total balance: sum of account current balances in primary currency
  Money totalBalance = Money.zero(currency);
  for (final acc in accounts) {
    if (acc.currencyCode == currency) {
      totalBalance = totalBalance + acc.currentBalance;
    }
  }

  // Current Month Boundaries for period calculations
  final now = DateTime.now();
  final monthBounds = AppDateUtils.getMonthBoundaries(now);

  final monthTxs = transactions.where((t) =>
      !t.transactionDate.isBefore(monthBounds.start) &&
      !t.transactionDate.isAfter(monthBounds.end));

  final incomeTxs = monthTxs.where((t) => t.isIncome && t.currencyCode == currency).map((t) => t.amount);
  final expenseTxs = monthTxs.where((t) => t.isExpense && t.currencyCode == currency).map((t) => t.amount);

  Money periodIncome = Money.zero(currency);
  for (final inc in incomeTxs) {
    periodIncome = periodIncome + inc;
  }

  Money periodExpense = Money.zero(currency);
  for (final exp in expenseTxs) {
    periodExpense = periodExpense + exp;
  }

  final netCashFlow = FinancialCalculator.calculateNetCashFlow(
    currency: currency,
    incomeTransactions: incomeTxs,
    expenseTransactions: expenseTxs,
  );

  // Active budget progress
  final activeBudget = budgets.isNotEmpty ? budgets.first : null;
  ({Money spent, Money remaining, double progress, bool isOverBudget})? budgetProgress;
  if (activeBudget != null) {
    final bgtExpenses = transactions.where((t) {
      if (!t.isExpense || t.currencyCode != activeBudget.currencyCode) return false;
      if (t.transactionDate.isBefore(activeBudget.startDate)) return false;
      if (activeBudget.endDate != null && t.transactionDate.isAfter(activeBudget.endDate!)) return false;
      return true;
    }).map((t) => t.amount);

    budgetProgress = FinancialCalculator.calculateBudgetProgress(
      budgetLimit: activeBudget.amount,
      qualifyingExpenses: bgtExpenses,
    );
  }

  // Category spending breakdown for month
  final categoryTotals = <String, Money>{};
  for (final t in monthTxs.where((t) => t.isExpense && t.currencyCode == currency)) {
    final catName = t.category?.name ?? 'Other';
    categoryTotals[catName] = (categoryTotals[catName] ?? Money.zero(currency)) + t.amount;
  }

  final categoryPercentages = FinancialCalculator.calculateCategoryPercentages(categoryTotals: categoryTotals);

  return DashboardSummary(
    totalBalance: totalBalance,
    periodIncome: periodIncome,
    periodExpense: periodExpense,
    netCashFlow: netCashFlow,
    recentTransactions: transactions.take(6).toList(),
    activeBudget: activeBudget,
    budgetProgress: budgetProgress,
    activeGoals: goals.take(3).toList(),
    categorySpendTotals: categoryTotals,
    categorySpendPercentages: categoryPercentages,
  );
});
