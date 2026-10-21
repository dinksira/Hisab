import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/money/financial_calculator.dart';
import '../../../core/money/money.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/app_progress_bar.dart';
import '../../../shared/widgets/financial_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/savings_goal.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goalsAsync = ref.watch(savingsGoalsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Savings Goal',
            onPressed: () => _showCreateGoalSheet(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: goalsAsync.when(
          loading: () => const Padding(
            padding: AppSpacing.pagePadding,
            child: LoadingSkeletonList(count: 3),
          ),
          error: (err, _) => ErrorStateView(
            message: err.toString(),
            onRetry: () => ref.invalidate(savingsGoalsListProvider),
          ),
          data: (goals) {
            if (goals.isEmpty) {
              return EmptyStateView(
                icon: Icons.flag_outlined,
                title: 'No Goals Created',
                subtitle: 'Track your dreams and build safety cushions with dedicated savings targets.',
                actionLabel: 'Create First Goal',
                onAction: () => _showCreateGoalSheet(context, ref),
              );
            }

            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: goals.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, index) {
                final goal = goals[index];
                final progress = FinancialCalculator.calculateGoalProgress(
                  targetAmount: goal.targetAmount,
                  contributions: [goal.currentSaved],
                  withdrawals: [],
                );

                return FinancialCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkIncomeGreenLight : AppColors.incomeGreenLight,
                                  borderRadius: AppRadii.radiusMd,
                                ),
                                child: Icon(
                                  Icons.shield_outlined,
                                  color: isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.name,
                                    style: AppTypography.heading3.copyWith(
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  if (goal.description != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      goal.description!,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.mintAccent.withAlpha(40) : AppColors.paleMint,
                              borderRadius: AppRadii.radiusPill,
                            ),
                            child: Text(
                              '${(progress.progress * 100).toInt()}%',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.mintAccent : AppColors.forestPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppProgressBar(
                        progress: progress.progress,
                        isBudget: false,
                        height: 8,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saved: ${progress.currentSaved.formatted()}',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Target: ${goal.targetAmount.formatted()}',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _showAddContributionDialog(context, ref, goal),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: const Text('Add Contribution'),
                        ),
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

  void _showCreateGoalSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateGoalSheet(),
    );
  }

  void _showAddContributionDialog(BuildContext context, WidgetRef ref, SavingsGoal goal) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Contribute to ${goal.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Contribution Amount (${goal.currencyCode})',
            hintText: 'e.g. 100.00',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final parsed = Money.tryParse(controller.text, goal.currencyCode);
              if (parsed != null && !parsed.isZero && !parsed.isNegative) {
                final contrib = GoalContribution(
                  id: const Uuid().v4(),
                  userId: goal.userId,
                  goalId: goal.id,
                  amount: parsed,
                  contributionType: 'contribution',
                  contributionDate: DateTime.now(),
                  createdAt: DateTime.now(),
                );
                await ref.read(savingsGoalsListProvider.notifier).addContribution(contrib);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _CreateGoalSheet extends ConsumerStatefulWidget {
  const _CreateGoalSheet();

  @override
  ConsumerState<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends ConsumerState<_CreateGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userProfile = ref.read(currentUserProfileProvider);
    final currency = userProfile?.preferredCurrency ?? 'USD';
    final parsedTarget = Money.tryParse(_targetController.text, currency);

    if (parsedTarget == null || parsedTarget.isZero || parsedTarget.isNegative) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target amount.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: const Uuid().v4(),
        userId: userProfile?.id ?? 'demo-user-1',
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        targetAmount: parsedTarget,
        currencyCode: currency,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(savingsGoalsListProvider.notifier).createGoal(goal);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Savings goal created!'),
            backgroundColor: AppColors.incomeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create goal: $e')),
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
                'New Savings Goal',
                style: AppTypography.heading2.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal Title',
                  hintText: 'e.g. Emergency Fund, New Car, Vacation',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  hintText: 'e.g. 5000.00',
                  prefixText: '\$ ',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter target amount' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Why are you saving for this?',
                ),
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
                    : const Text('Create Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
