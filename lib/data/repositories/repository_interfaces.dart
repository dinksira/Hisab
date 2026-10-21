import '../../features/auth/domain/user_profile.dart';
import '../../features/accounts/domain/account.dart';
import '../../features/budgets/domain/budget.dart';
import '../../features/goals/domain/savings_goal.dart';
import '../../features/recurring/domain/recurring_transaction.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/transactions/domain/transfer.dart';
import '../../shared/models/category.dart';

abstract class IAuthRepository {
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> signUp({required String email, required String password, String? displayName});
  Future<UserProfile> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> resetPassword({required String email});
  Future<UserProfile> updateProfile(UserProfile profile);
  Stream<bool> get authStateChanges;
}

abstract class IAccountRepository {
  Future<List<Account>> getAccounts();
  Future<Account> createAccount(Account account);
  Future<Account> updateAccount(Account account);
  Future<void> deleteAccount(String accountId);
}

abstract class ICategoryRepository {
  Future<List<Category>> getCategories();
  Future<Category> createCategory(Category category);
  Future<Category> updateCategory(Category category);
  Future<void> deleteCategory(String categoryId);
}

abstract class ITransactionRepository {
  Future<List<FinancialTransaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
    String? transactionType,
    String? searchQuery,
    int? limit,
    int? offset,
  });
  Future<FinancialTransaction> createTransaction(FinancialTransaction transaction);
  Future<FinancialTransaction> updateTransaction(FinancialTransaction transaction);
  Future<void> deleteTransaction(String transactionId);

  Future<List<AccountTransfer>> getTransfers({DateTime? startDate, DateTime? endDate});
  Future<AccountTransfer> createTransfer(AccountTransfer transfer);
  Future<void> deleteTransfer(String transferId);
}

abstract class IBudgetRepository {
  Future<List<Budget>> getBudgets();
  Future<Budget> createBudget(Budget budget, List<BudgetCategory> categories);
  Future<Budget> updateBudget(Budget budget);
  Future<void> deleteBudget(String budgetId);
}

abstract class IGoalRepository {
  Future<List<SavingsGoal>> getGoals();
  Future<SavingsGoal> createGoal(SavingsGoal goal);
  Future<SavingsGoal> updateGoal(SavingsGoal goal);
  Future<void> deleteGoal(String goalId);
  Future<GoalContribution> addContribution(GoalContribution contribution);
  Future<void> deleteContribution(String contributionId);
}

abstract class IRecurringRepository {
  Future<List<RecurringTransaction>> getRecurringTransactions();
  Future<RecurringTransaction> createRecurringTransaction(RecurringTransaction recurring);
  Future<RecurringTransaction> updateRecurringTransaction(RecurringTransaction recurring);
  Future<void> deleteRecurringTransaction(String id);
}
