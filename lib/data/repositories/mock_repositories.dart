import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/dates/date_utils.dart';
import '../../core/money/financial_calculator.dart';
import '../../core/money/money.dart';
import '../../features/accounts/domain/account.dart';
import '../../features/auth/domain/user_profile.dart';
import '../../features/budgets/domain/budget.dart';
import '../../features/goals/domain/savings_goal.dart';
import '../../features/recurring/domain/recurring_transaction.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/transactions/domain/transfer.dart';
import '../../shared/models/category.dart';
import 'repository_interfaces.dart';

/// In-memory mock repository used for preview/testing or when Supabase credentials are not set.
class MockDataStore {
  static final MockDataStore instance = MockDataStore._();
  MockDataStore._() {
    _seed();
  }

  UserProfile? currentUser;
  final List<Account> accounts = [];
  final List<Category> categories = [];
  final List<FinancialTransaction> transactions = [];
  final List<AccountTransfer> transfers = [];
  final List<Budget> budgets = [];
  final List<SavingsGoal> goals = [];
  final List<GoalContribution> contributions = [];
  final List<RecurringTransaction> recurring = [];

  final _authStreamController = StreamController<bool>.broadcast();
  Stream<bool> get authStateChanges => _authStreamController.stream;

  void _seed() {
    final now = DateTime.now();
    currentUser = UserProfile(
      id: 'demo-user-1',
      displayName: 'Zaid Al-Mansoor',
      preferredCurrency: 'USD',
      locale: 'en_US',
      themePreference: 'system',
      weekStartsOn: 1,
      createdAt: now.subtract(const Duration(days: 90)),
      updatedAt: now,
    );

    // Seed Categories
    categories.addAll([
      Category(
        id: 'cat-housing',
        name: 'Housing & Rent',
        transactionType: 'expense',
        iconKey: 'home',
        colorHex: '#173D32',
        isSystem: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat-groceries',
        name: 'Groceries & Dining',
        transactionType: 'expense',
        iconKey: 'restaurant',
        colorHex: '#46C89A',
        isSystem: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat-transport',
        name: 'Transportation',
        transactionType: 'expense',
        iconKey: 'directions_car',
        colorHex: '#6C8FE8',
        isSystem: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat-utilities',
        name: 'Utilities & Bills',
        transactionType: 'expense',
        iconKey: 'bolt',
        colorHex: '#D9A441',
        isSystem: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat-leisure',
        name: 'Entertainment',
        transactionType: 'expense',
        iconKey: 'movie',
        colorHex: '#E58B68',
        isSystem: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat-salary',
        name: 'Salary & Income',
        transactionType: 'income',
        iconKey: 'work',
        colorHex: '#2E9F75',
        isSystem: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'cat-investment',
        name: 'Dividends & Yield',
        transactionType: 'income',
        iconKey: 'trending_up',
        colorHex: '#46C89A',
        isSystem: true,
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    // Seed Accounts
    accounts.addAll([
      Account(
        id: 'acc-checking',
        userId: 'demo-user-1',
        name: 'Primary Checking',
        accountType: 'checking',
        currencyCode: 'USD',
        openingBalance: Money.parse('3500.00', 'USD'),
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
      Account(
        id: 'acc-savings',
        userId: 'demo-user-1',
        name: 'High-Yield Savings',
        accountType: 'savings',
        currencyCode: 'USD',
        openingBalance: Money.parse('12000.00', 'USD'),
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
      Account(
        id: 'acc-cash',
        userId: 'demo-user-1',
        name: 'Cash Wallet',
        accountType: 'cash',
        currencyCode: 'USD',
        openingBalance: Money.parse('350.00', 'USD'),
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
    ]);

    // Seed Transactions
    transactions.addAll([
      FinancialTransaction(
        id: 'tx-1',
        userId: 'demo-user-1',
        accountId: 'acc-checking',
        categoryId: 'cat-salary',
        transactionType: 'income',
        amount: Money.parse('4200.00', 'USD'),
        currencyCode: 'USD',
        description: 'Monthly Salary',
        transactionDate: AppDateUtils.dateOnly(now.subtract(const Duration(days: 2))),
        merchant: 'Apex Tech Corp',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        category: categories.firstWhere((c) => c.id == 'cat-salary'),
        account: accounts.firstWhere((a) => a.id == 'acc-checking'),
      ),
      FinancialTransaction(
        id: 'tx-2',
        userId: 'demo-user-1',
        accountId: 'acc-checking',
        categoryId: 'cat-housing',
        transactionType: 'expense',
        amount: Money.parse('1450.00', 'USD'),
        currencyCode: 'USD',
        description: 'Apartment Rent',
        transactionDate: AppDateUtils.dateOnly(now.subtract(const Duration(days: 3))),
        merchant: 'Green Heights Properties',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        category: categories.firstWhere((c) => c.id == 'cat-housing'),
        account: accounts.firstWhere((a) => a.id == 'acc-checking'),
      ),
      FinancialTransaction(
        id: 'tx-3',
        userId: 'demo-user-1',
        accountId: 'acc-checking',
        categoryId: 'cat-groceries',
        transactionType: 'expense',
        amount: Money.parse('164.25', 'USD'),
        currencyCode: 'USD',
        description: 'Organic Market & Provisions',
        transactionDate: AppDateUtils.dateOnly(now.subtract(const Duration(days: 1))),
        merchant: 'Whole Foods Market',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        category: categories.firstWhere((c) => c.id == 'cat-groceries'),
        account: accounts.firstWhere((a) => a.id == 'acc-checking'),
      ),
      FinancialTransaction(
        id: 'tx-4',
        userId: 'demo-user-1',
        accountId: 'acc-checking',
        categoryId: 'cat-transport',
        transactionType: 'expense',
        amount: Money.parse('42.50', 'USD'),
        currencyCode: 'USD',
        description: 'Metro Monthly Transit Pass',
        transactionDate: AppDateUtils.dateOnly(now.subtract(const Duration(days: 4))),
        merchant: 'City Transit Authority',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
        category: categories.firstWhere((c) => c.id == 'cat-transport'),
        account: accounts.firstWhere((a) => a.id == 'acc-checking'),
      ),
      FinancialTransaction(
        id: 'tx-5',
        userId: 'demo-user-1',
        accountId: 'acc-cash',
        categoryId: 'cat-leisure',
        transactionType: 'expense',
        amount: Money.parse('18.00', 'USD'),
        currencyCode: 'USD',
        description: 'Artisanal Coffee & Pastry',
        transactionDate: AppDateUtils.dateOnly(now),
        merchant: 'Blue Bottle Coffee',
        createdAt: now,
        updatedAt: now,
        category: categories.firstWhere((c) => c.id == 'cat-leisure'),
        account: accounts.firstWhere((a) => a.id == 'acc-cash'),
      ),
    ]);

    // Seed Budgets
    final monthBounds = AppDateUtils.getMonthBoundaries(now);
    budgets.add(
      Budget(
        id: 'bgt-monthly',
        userId: 'demo-user-1',
        name: 'October Living Budget',
        amount: Money.parse('2800.00', 'USD'),
        currencyCode: 'USD',
        periodType: 'monthly',
        startDate: monthBounds.start,
        endDate: monthBounds.end,
        alertThresholds: [0.8, 1.0],
        createdAt: monthBounds.start,
        updatedAt: now,
        categories: [
          BudgetCategory(
            id: 'bcat-1',
            userId: 'demo-user-1',
            budgetId: 'bgt-monthly',
            categoryId: 'cat-groceries',
            allocatedAmount: Money.parse('600.00', 'USD'),
            createdAt: monthBounds.start,
            updatedAt: now,
            category: categories.firstWhere((c) => c.id == 'cat-groceries'),
          ),
          BudgetCategory(
            id: 'bcat-2',
            userId: 'demo-user-1',
            budgetId: 'bgt-monthly',
            categoryId: 'cat-housing',
            allocatedAmount: Money.parse('1500.00', 'USD'),
            createdAt: monthBounds.start,
            updatedAt: now,
            category: categories.firstWhere((c) => c.id == 'cat-housing'),
          ),
        ],
      ),
    );

    // Seed Savings Goals
    final goal1 = SavingsGoal(
      id: 'goal-emergency',
      userId: 'demo-user-1',
      name: 'Emergency Fund (6 Months)',
      description: 'Peace of mind liquidity cushion',
      targetAmount: Money.parse('15000.00', 'USD'),
      currencyCode: 'USD',
      targetDate: now.add(const Duration(days: 180)),
      iconKey: 'shield',
      status: 'active',
      createdAt: now.subtract(const Duration(days: 45)),
      updatedAt: now,
      computedSaved: Money.parse('11250.00', 'USD'),
    );

    final goal2 = SavingsGoal(
      id: 'goal-vacation',
      userId: 'demo-user-1',
      name: 'Nordic Summer Voyage',
      description: 'Fjords and Scandinavian retreat',
      targetAmount: Money.parse('4500.00', 'USD'),
      currencyCode: 'USD',
      targetDate: now.add(const Duration(days: 120)),
      iconKey: 'flight',
      status: 'active',
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now,
      computedSaved: Money.parse('2100.00', 'USD'),
    );

    goals.addAll([goal1, goal2]);

    // Seed Recurring Transactions
    recurring.addAll([
      RecurringTransaction(
        id: 'rec-rent',
        userId: 'demo-user-1',
        accountId: 'acc-checking',
        categoryId: 'cat-housing',
        transactionType: 'expense',
        amount: Money.parse('1450.00', 'USD'),
        currencyCode: 'USD',
        description: 'Apartment Lease Payment',
        frequency: 'monthly',
        startDate: DateTime(now.year, now.month, 1),
        nextExpectedDate: DateTime(now.year, now.month + 1, 1),
        status: 'active',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
        category: categories.firstWhere((c) => c.id == 'cat-housing'),
        account: accounts.firstWhere((a) => a.id == 'acc-checking'),
      ),
      RecurringTransaction(
        id: 'rec-sub',
        userId: 'demo-user-1',
        accountId: 'acc-checking',
        categoryId: 'cat-leisure',
        transactionType: 'expense',
        amount: Money.parse('14.99', 'USD'),
        currencyCode: 'USD',
        description: 'Cloud Streaming & Music',
        frequency: 'monthly',
        startDate: DateTime(now.year, now.month, 15),
        nextExpectedDate: DateTime(now.year, now.month + 1, 15),
        status: 'active',
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now,
        category: categories.firstWhere((c) => c.id == 'cat-leisure'),
        account: accounts.firstWhere((a) => a.id == 'acc-checking'),
      ),
    ]);
  }
}

class MockAuthRepository implements IAuthRepository {
  final MockDataStore _store = MockDataStore.instance;

  @override
  Stream<bool> get authStateChanges => _store.authStateChanges;

  @override
  Future<UserProfile?> getCurrentUser() async => _store.currentUser;

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final user = UserProfile(
      id: const Uuid().v4(),
      displayName: displayName ?? email.split('@').first,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _store.currentUser = user;
    _store._authStreamController.add(true);
    return user;
  }

  @override
  Future<UserProfile> signIn({required String email, required String password}) async {
    final user = _store.currentUser ??
        UserProfile(
          id: 'demo-user-1',
          displayName: 'Zaid Al-Mansoor',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    _store.currentUser = user;
    _store._authStreamController.add(true);
    return user;
  }

  @override
  Future<void> signOut() async {
    _store.currentUser = null;
    _store._authStreamController.add(false);
  }

  @override
  Future<void> resetPassword({required String email}) async {}

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    _store.currentUser = profile;
    return profile;
  }
}

class MockAccountRepository implements IAccountRepository {
  final MockDataStore _store = MockDataStore.instance;

  @override
  Future<List<Account>> getAccounts() async {
    // Recompute current balances based on transactions and transfers
    return _store.accounts.where((a) => !a.isArchived).map((account) {
      final accountTxs = _store.transactions.where((t) => t.accountId == account.id);
      final inc = accountTxs.where((t) => t.isIncome).map((t) => t.amount);
      final exp = accountTxs.where((t) => t.isExpense).map((t) => t.amount);
      final inTransfers = _store.transfers.where((t) => t.toAccountId == account.id).map((t) => t.amount);
      final outTransfers = _store.transfers.where((t) => t.fromAccountId == account.id).map((t) => t.amount);

      final balance = FinancialCalculator.calculateAccountBalance(
        openingBalance: account.openingBalance,
        incomeTransactions: inc,
        expenseTransactions: exp,
        incomingTransfers: inTransfers,
        outgoingTransfers: outTransfers,
      );

      return account.copyWith(computedBalance: balance);
    }).toList();
  }

  @override
  Future<Account> createAccount(Account account) async {
    _store.accounts.add(account);
    return account;
  }

  @override
  Future<Account> updateAccount(Account account) async {
    final idx = _store.accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) {
      _store.accounts[idx] = account;
    }
    return account;
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    final idx = _store.accounts.indexWhere((a) => a.id == accountId);
    if (idx != -1) {
      _store.accounts[idx] = _store.accounts[idx].copyWith(isArchived: true);
    }
  }
}

class MockCategoryRepository implements ICategoryRepository {
  final MockDataStore _store = MockDataStore.instance;

  @override
  Future<List<Category>> getCategories() async {
    return _store.categories.where((c) => !c.isArchived).toList();
  }

  @override
  Future<Category> createCategory(Category category) async {
    _store.categories.add(category);
    return category;
  }

  @override
  Future<Category> updateCategory(Category category) async {
    final idx = _store.categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) {
      _store.categories[idx] = category;
    }
    return category;
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    _store.categories.removeWhere((c) => c.id == categoryId && !c.isSystem);
  }
}

class MockTransactionRepository implements ITransactionRepository {
  final MockDataStore _store = MockDataStore.instance;

  @override
  Future<List<FinancialTransaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
    String? transactionType,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    var list = _store.transactions.toList();

    if (startDate != null) {
      list = list.where((t) => !t.transactionDate.isBefore(startDate)).toList();
    }
    if (endDate != null) {
      list = list.where((t) => !t.transactionDate.isAfter(endDate)).toList();
    }
    if (categoryId != null) {
      list = list.where((t) => t.categoryId == categoryId).toList();
    }
    if (accountId != null) {
      list = list.where((t) => t.accountId == accountId).toList();
    }
    if (transactionType != null) {
      list = list.where((t) => t.transactionType == transactionType).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((t) =>
          t.description.toLowerCase().contains(q) ||
          (t.merchant?.toLowerCase().contains(q) ?? false)).toList();
    }

    list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    if (limit != null && list.length > limit) {
      list = list.sublist(0, limit);
    }
    return list;
  }

  @override
  Future<FinancialTransaction> createTransaction(FinancialTransaction transaction) async {
    final category = _store.categories.cast<Category?>().firstWhere(
          (c) => c?.id == transaction.categoryId,
          orElse: () => null,
        );
    final account = _store.accounts.cast<Account?>().firstWhere(
          (a) => a?.id == transaction.accountId,
          orElse: () => null,
        );

    final resolved = transaction.copyWith(
      category: category,
      account: account,
    );
    _store.transactions.insert(0, resolved);
    return resolved;
  }

  @override
  Future<FinancialTransaction> updateTransaction(FinancialTransaction transaction) async {
    final idx = _store.transactions.indexWhere((t) => t.id == transaction.id);
    if (idx != -1) {
      final category = _store.categories.cast<Category?>().firstWhere(
            (c) => c?.id == transaction.categoryId,
            orElse: () => null,
          );
      final account = _store.accounts.cast<Account?>().firstWhere(
            (a) => a?.id == transaction.accountId,
            orElse: () => null,
          );
      final updated = transaction.copyWith(
        updatedAt: DateTime.now(),
        category: category,
        account: account,
      );
      _store.transactions[idx] = updated;
      return updated;
    }
    return transaction;
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    _store.transactions.removeWhere((t) => t.id == transactionId);
  }

  @override
  Future<List<AccountTransfer>> getTransfers({DateTime? startDate, DateTime? endDate}) async {
    return _store.transfers;
  }

  @override
  Future<AccountTransfer> createTransfer(AccountTransfer transfer) async {
    _store.transfers.insert(0, transfer);
    return transfer;
  }

  @override
  Future<void> deleteTransfer(String transferId) async {
    _store.transfers.removeWhere((t) => t.id == transferId);
  }
}

class MockBudgetRepository implements IBudgetRepository {
  final MockDataStore _store = MockDataStore.instance;

  @override
  Future<List<Budget>> getBudgets() async {
    return _store.budgets.where((b) => !b.isArchived).toList();
  }

  @override
  Future<Budget> createBudget(Budget budget, List<BudgetCategory> categories) async {
    final full = budget.copyWith(categories: categories);
    _store.budgets.add(full);
    return full;
  }

  @override
  Future<Budget> updateBudget(Budget budget) async {
    final idx = _store.budgets.indexWhere((b) => b.id == budget.id);
    if (idx != -1) {
      _store.budgets[idx] = budget;
    }
    return budget;
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    _store.budgets.removeWhere((b) => b.id == budgetId);
  }
}

class MockGoalRepository implements IGoalRepository {
  final MockDataStore _store = MockDataStore.instance;

  @override
  Future<List<SavingsGoal>> getGoals() async {
    return _store.goals.where((g) => g.status != 'archived').toList();
  }

  @override
  Future<SavingsGoal> createGoal(SavingsGoal goal) async {
    _store.goals.add(goal);
    return goal;
  }

  @override
  Future<SavingsGoal> updateGoal(SavingsGoal goal) async {
    final idx = _store.goals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) {
      _store.goals[idx] = goal;
    }
    return goal;
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    _store.goals.removeWhere((g) => g.id == goalId);
  }

  @override
  Future<GoalContribution> addContribution(GoalContribution contribution) async {
    _store.contributions.add(contribution);
    final goalIdx = _store.goals.indexWhere((g) => g.id == contribution.goalId);
    if (goalIdx != -1) {
      final goal = _store.goals[goalIdx];
      final newSaved = contribution.isContribution
          ? goal.currentSaved + contribution.amount
          : goal.currentSaved - contribution.amount;
      _store.goals[goalIdx] = goal.copyWith(computedSaved: newSaved);
    }
    return contribution;
  }

  @override
  Future<void> deleteContribution(String contributionId) async {
    _store.contributions.removeWhere((c) => c.id == contributionId);
  }
}

class MockRecurringRepository implements IRecurringRepository {
  final MockDataStore _store = MockDataStore.instance;

  @override
  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    return _store.recurring.where((r) => r.status != 'cancelled').toList();
  }

  @override
  Future<RecurringTransaction> createRecurringTransaction(RecurringTransaction recurring) async {
    _store.recurring.add(recurring);
    return recurring;
  }

  @override
  Future<RecurringTransaction> updateRecurringTransaction(RecurringTransaction recurring) async {
    final idx = _store.recurring.indexWhere((r) => r.id == recurring.id);
    if (idx != -1) {
      _store.recurring[idx] = recurring;
    }
    return recurring;
  }

  @override
  Future<void> deleteRecurringTransaction(String id) async {
    final idx = _store.recurring.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _store.recurring[idx] = _store.recurring[idx].copyWith(status: 'cancelled');
    }
  }
}
