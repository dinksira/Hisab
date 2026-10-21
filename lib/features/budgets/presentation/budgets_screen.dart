import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/dates/date_utils.dart';
import '../../../core/money/financial_calculator.dart';
import '../../../core/money/money.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/app_progress_bar.dart';
import '../../../shared/widgets/financial_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/budget.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgetsAsync = ref.watch(budgetsListProvider);
    final transactionsAsync = ref.watch(transactionsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Allowances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create Budget',
            onPressed: () => _showCreateBudgetSheet(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: budgetsAsync.when(
          loading: () => const Padding(
            padding: AppSpacing.pagePadding,
            child: LoadingSkeletonList(count: 3),
          ),
          error: (err, _) => ErrorStateView(
            message: err.toString(),
            onRetry: () => ref.invalidate(budgetsListProvider),
          ),
          data: (budgets) {
            if (budgets.isEmpty) {
              return EmptyStateView(
                icon: Icons.pie_chart_outline_rounded,
                title: 'No Budgets Configured',
                subtitle: 'Take control of your spending by setting monthly or weekly allowances.',
                actionLabel: 'Create First Budget',
                onAction: () => _showCreateBudgetSheet(context, ref),
              );
            }

            final transactions = transactionsAsync.valueOrNull ?? [];

            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: budgets.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, index) {
                final budget = budgets[index];

                // Calculate real spending from qualifying transactions in period
                final qualifyingExpenses = transactions.where((t) {
                  if (!t.isExpense || t.currencyCode != budget.currencyCode) return false;
                  if (t.transactionDate.isBefore(budget.startDate)) return false;
                  if (budget.endDate != null && t.transactionDate.isAfter(budget.endDate!)) return false;
                  return true;
                }).map((t) => t.amount);

                final progress = FinancialCalculator.calculateBudgetProgress(
                  budgetLimit: budget.amount,
                  qualifyingExpenses: qualifyingExpenses,
                );

                return FinancialCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                budget.name,
                                style: AppTypography.heading2.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${budget.periodType.toUpperCase()} • ${AppDateUtils.formatDayMonth(budget.startDate)} - ${budget.endDate != null ? AppDateUtils.formatDayMonth(budget.endDate!) : 'Ongoing'}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: progress.isOverBudget
                                  ? (isDark ? AppColors.darkExpenseOrangeLight : AppColors.expenseOrangeLight)
                                  : (isDark ? AppColors.darkIncomeGreenLight : AppColors.incomeGreenLight),
                              borderRadius: AppRadii.radiusPill,
                            ),
                            child: Text(
                              progress.isOverBudget
                                  ? 'Exceeded (${(progress.progress * 100).toInt()}%)'
                                  : '${(progress.progress * 100).toInt()}% Used',
                              style: AppTypography.labelSmall.copyWith(
                                color: progress.isOverBudget
                                    ? (isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange)
                                    : (isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppProgressBar(
                        progress: progress.progress,
                        isBudget: true,
                        height: 10,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SPENT',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                progress.spent.formatted(),
                                style: AppTypography.heading3.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                progress.isOverBudget ? 'OVERSPENT' : 'REMAINING',
                                style: AppTypography.labelSmall.copyWith(
                                  color: progress.isOverBudget
                                      ? (isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange)
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.secondaryText),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                progress.isOverBudget
                                    ? '+${progress.remaining.abs().formatted()}'
                                    : progress.remaining.formatted(),
                                style: AppTypography.heading3.copyWith(
                                  color: progress.isOverBudget
                                      ? (isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange)
                                      : (isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showCreateBudgetSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateBudgetSheet(),
    );
  }
}

class _CreateBudgetSheet extends ConsumerStatefulWidget {
  const _CreateBudgetSheet();

  @override
  ConsumerState<_CreateBudgetSheet> createState() => _CreateBudgetSheetState();
}

class _CreateBudgetSheetState extends ConsumerState<_CreateBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _periodType = 'monthly';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userProfile = ref.read(currentUserProfileProvider);
    final currency = userProfile?.preferredCurrency ?? 'USD';
    final parsedMoney = Money.tryParse(_amountController.text, currency);

    if (parsedMoney == null || parsedMoney.isZero || parsedMoney.isNegative) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive budget amount.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final bounds = AppDateUtils.getMonthBoundaries(now);

      final budget = Budget(
        id: const Uuid().v4(),
        userId: userProfile?.id ?? 'demo-user-1',
        name: _nameController.text.trim(),
        amount: parsedMoney,
        currencyCode: currency,
        periodType: _periodType,
        startDate: bounds.start,
        endDate: bounds.end,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(budgetsListProvider.notifier).createBudget(budget, []);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget created successfully.'),
            backgroundColor: AppColors.incomeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create budget: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadii.sheetTopRadius,
        ),
        padding: AppSpacing.sheetPadding,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create New Budget',
                style: AppTypography.heading2.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Budget Name',
                  hintText: 'e.g. Monthly Living, Discretionary, Groceries',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter budget name' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Spending Limit',
                  hintText: 'e.g. 2500.00',
                  prefixText: '\$ ',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter limit amount' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _periodType,
                decoration: const InputDecoration(labelText: 'Period'),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (val) => setState(() => _periodType = val ?? 'monthly'),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
