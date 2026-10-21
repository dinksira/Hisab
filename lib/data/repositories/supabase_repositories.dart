import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/dates/date_utils.dart';
import '../../features/accounts/domain/account.dart';
import '../../features/auth/domain/user_profile.dart';
import '../../features/budgets/domain/budget.dart';
import '../../features/goals/domain/savings_goal.dart';
import '../../features/recurring/domain/recurring_transaction.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/transactions/domain/transfer.dart';
import '../../shared/models/category.dart';
import '../remote/supabase_client.dart';
import 'repository_interfaces.dart';

class SupabaseAuthRepository implements IAuthRepository {
  SupabaseClient get _client {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase client is not initialized.');
    return client;
  }

  @override
  Stream<bool> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) => event.session != null);

  @override
  Future<UserProfile?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      // Create initial profile if missing
      final profile = UserProfile(
        id: user.id,
        displayName: user.userMetadata?['display_name'] as String?,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _client.from('profiles').insert(profile.toJson());
      return profile;
    }

    return UserProfile.fromJson(response);
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );

    final user = authResponse.user;
    if (user == null) throw Exception('Registration failed: no user returned.');

    final profile = UserProfile(
      id: user.id,
      displayName: displayName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _client.from('profiles').upsert(profile.toJson());
    return profile;
  }

  @override
  Future<UserProfile> signIn({required String email, required String password}) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = authResponse.user;
    if (user == null) throw Exception('Sign-in failed: invalid credentials.');

    final profile = await getCurrentUser();
    return profile ??
        UserProfile(
          id: user.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final updated = profile.copyWith(updatedAt: DateTime.now());
    await _client.from('profiles').update(updated.toJson()).eq('id', updated.id);
    return updated;
  }
}

class SupabaseAccountRepository implements IAccountRepository {
  SupabaseClient get _client => SupabaseService.client!;

  @override
  Future<List<Account>> getAccounts() async {
    final data = await _client
        .from('accounts')
        .select()
        .eq('is_archived', false)
        .order('created_at', ascending: true);
    return (data as List).map((json) => Account.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<Account> createAccount(Account account) async {
    final response = await _client.from('accounts').insert(account.toJson()).select().single();
    return Account.fromJson(response);
  }

  @override
  Future<Account> updateAccount(Account account) async {
    final updated = account.copyWith(updatedAt: DateTime.now());
    final response = await _client
        .from('accounts')
        .update(updated.toJson())
        .eq('id', account.id)
        .select()
        .single();
    return Account.fromJson(response);
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    await _client.from('accounts').update({'is_archived': true}).eq('id', accountId);
  }
}

class SupabaseCategoryRepository implements ICategoryRepository {
  SupabaseClient get _client => SupabaseService.client!;

  @override
  Future<List<Category>> getCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .eq('is_archived', false)
        .order('name', ascending: true);
    return (data as List).map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<Category> createCategory(Category category) async {
    final response = await _client.from('categories').insert(category.toJson()).select().single();
    return Category.fromJson(response);
  }

  @override
  Future<Category> updateCategory(Category category) async {
    final updated = category.copyWith(updatedAt: DateTime.now());
    final response = await _client
        .from('categories')
        .update(updated.toJson())
        .eq('id', category.id)
        .select()
        .single();
    return Category.fromJson(response);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _client.from('categories').update({'is_archived': true}).eq('id', categoryId);
  }
}

class SupabaseTransactionRepository implements ITransactionRepository {
  SupabaseClient get _client => SupabaseService.client!;

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
    var query = _client.from('transactions').select('*, categories(*), accounts(*)');

    if (startDate != null) {
      query = query.gte('transaction_date', AppDateUtils.toIsoDate(startDate));
    }
    if (endDate != null) {
      query = query.lte('transaction_date', AppDateUtils.toIsoDate(endDate));
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (accountId != null) {
      query = query.eq('account_id', accountId);
    }
    if (transactionType != null) {
      query = query.eq('transaction_type', transactionType);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('description', '%$searchQuery%');
    }

    var ordered = query.order('transaction_date', ascending: false).order('created_at', ascending: false);
    if (limit != null) {
      ordered = ordered.limit(limit);
    }

    final data = await ordered;
    return (data as List)
        .map((json) => FinancialTransaction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FinancialTransaction> createTransaction(FinancialTransaction transaction) async {
    final response = await _client
        .from('transactions')
        .insert(transaction.toJson())
        .select('*, categories(*), accounts(*)')
        .single();
    return FinancialTransaction.fromJson(response);
  }

  @override
  Future<FinancialTransaction> updateTransaction(FinancialTransaction transaction) async {
    final updated = transaction.copyWith(updatedAt: DateTime.now());
    final response = await _client
        .from('transactions')
        .update(updated.toJson())
        .eq('id', transaction.id)
        .select('*, categories(*), accounts(*)')
        .single();
    return FinancialTransaction.fromJson(response);
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _client.from('transactions').delete().eq('id', transactionId);
  }

  @override
  Future<List<AccountTransfer>> getTransfers({DateTime? startDate, DateTime? endDate}) async {
    var query = _client.from('transfers').select('*, from_account:accounts!from_account_id(*), to_account:accounts!to_account_id(*)');
    if (startDate != null) {
      query = query.gte('transfer_date', AppDateUtils.toIsoDate(startDate));
    }
    if (endDate != null) {
      query = query.lte('transfer_date', AppDateUtils.toIsoDate(endDate));
    }
    final data = await query.order('transfer_date', ascending: false);
    return (data as List).map((json) => AccountTransfer.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<AccountTransfer> createTransfer(AccountTransfer transfer) async {
    final response = await _client
        .from('transfers')
        .insert(transfer.toJson())
        .select()
        .single();
    return AccountTransfer.fromJson(response);
  }

  @override
  Future<void> deleteTransfer(String transferId) async {
    await _client.from('transfers').delete().eq('id', transferId);
  }
}

class SupabaseBudgetRepository implements IBudgetRepository {
  SupabaseClient get _client => SupabaseService.client!;

  @override
  Future<List<Budget>> getBudgets() async {
    final data = await _client
        .from('budgets')
        .select('*, budget_categories(*, categories(*))')
        .eq('is_archived', false)
        .order('created_at', ascending: true);
    return (data as List).map((json) => Budget.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<Budget> createBudget(Budget budget, List<BudgetCategory> categories) async {
    final response = await _client.from('budgets').insert(budget.toJson()).select().single();
    final createdBudget = Budget.fromJson(response);

    if (categories.isNotEmpty) {
      final catInserts = categories
          .map((c) => c.toJson()..['budget_id'] = createdBudget.id)
          .toList();
      await _client.from('budget_categories').insert(catInserts);
    }

    return (await getBudgets()).firstWhere((b) => b.id == createdBudget.id);
  }

  @override
  Future<Budget> updateBudget(Budget budget) async {
    final updated = budget.copyWith(updatedAt: DateTime.now());
    await _client.from('budgets').update(updated.toJson()).eq('id', budget.id);
    return updated;
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    await _client.from('budgets').update({'is_archived': true}).eq('id', budgetId);
  }
}

class SupabaseGoalRepository implements IGoalRepository {
  SupabaseClient get _client => SupabaseService.client!;

  @override
  Future<List<SavingsGoal>> getGoals() async {
    final data = await _client
        .from('savings_goals')
        .select('*, goal_contributions(*)')
        .order('created_at', ascending: true);
    return (data as List).map((json) => SavingsGoal.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<SavingsGoal> createGoal(SavingsGoal goal) async {
    final response = await _client.from('savings_goals').insert(goal.toJson()).select().single();
    return SavingsGoal.fromJson(response);
  }

  @override
  Future<SavingsGoal> updateGoal(SavingsGoal goal) async {
    final updated = goal.copyWith(updatedAt: DateTime.now());
    final response = await _client
        .from('savings_goals')
        .update(updated.toJson())
        .eq('id', goal.id)
        .select()
        .single();
    return SavingsGoal.fromJson(response);
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    await _client.from('savings_goals').update({'status': 'archived'}).eq('id', goalId);
  }

  @override
  Future<GoalContribution> addContribution(GoalContribution contribution) async {
    final response = await _client
        .from('goal_contributions')
        .insert(contribution.toJson())
        .select()
        .single();
    return GoalContribution.fromJson(response, 'USD');
  }

  @override
  Future<void> deleteContribution(String contributionId) async {
    await _client.from('goal_contributions').delete().eq('id', contributionId);
  }
}

class SupabaseRecurringRepository implements IRecurringRepository {
  SupabaseClient get _client => SupabaseService.client!;

  @override
  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final data = await _client
        .from('recurring_transactions')
        .select('*, categories(*), accounts(*)')
        .order('next_expected_date', ascending: true);
    return (data as List)
        .map((json) => RecurringTransaction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<RecurringTransaction> createRecurringTransaction(RecurringTransaction recurring) async {
    final response = await _client
        .from('recurring_transactions')
        .insert(recurring.toJson())
        .select('*, categories(*), accounts(*)')
        .single();
    return RecurringTransaction.fromJson(response);
  }

  @override
  Future<RecurringTransaction> updateRecurringTransaction(RecurringTransaction recurring) async {
    final updated = recurring.copyWith(updatedAt: DateTime.now());
    final response = await _client
        .from('recurring_transactions')
        .update(updated.toJson())
        .eq('id', recurring.id)
        .select('*, categories(*), accounts(*)')
        .single();
    return RecurringTransaction.fromJson(response);
  }

  @override
  Future<void> deleteRecurringTransaction(String id) async {
    await _client.from('recurring_transactions').update({'status': 'cancelled'}).eq('id', id);
  }
}
