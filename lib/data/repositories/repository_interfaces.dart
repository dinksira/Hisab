import '../../features/accounts/domain/account.dart';
import '../../features/auth/data/auth_state.dart';
import '../../features/auth/domain/user_profile.dart';
import '../../features/budgets/domain/budget.dart';
import '../../features/goals/domain/savings_goal.dart';
import '../../features/recurring/domain/recurring_transaction.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/transactions/domain/transfer.dart';
import '../../shared/models/category.dart';

abstract class IAuthRepository {
  /// The profile of the currently signed-in user, or null when signed out.
  Future<UserProfile?> getCurrentUser();

  /// Registers a new account.
  ///
  /// When the backend requires email confirmation the returned profile is
  /// still valid but no session exists yet; check
  /// [SupabaseAuthRepository.hasActiveSession] or the auth stream to react.
  Future<UserProfile> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<UserProfile> signIn({required String email, required String password});

  /// Starts the browser based Google OAuth flow.
  ///
  /// The returned value only reports whether the browser was launched; the
  /// sign-in completes asynchronously through [authStateChanges].
  Future<bool> signInWithGoogle();

  Future<void> signOut();

  /// Sends a password reset link to [email].
  Future<void> resetPassword({required String email});

  /// Re-sends the email confirmation link.
  Future<void> resendConfirmation({required String email});

  /// Sets a new password for the signed-in (recovering) user.
  Future<void> updatePassword({required String newPassword});

  Future<UserProfile> updateProfile(UserProfile profile);

  /// Stream of backend authentication events.
  Stream<AuthEvent> get authStateChanges;

  /// All identities linked to the current account.
  Future<List<AuthIdentity>> getIdentities();

  /// Removes a linked identity (email or Google) from the account.
  Future<void> unlinkIdentity(String identityId);
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
