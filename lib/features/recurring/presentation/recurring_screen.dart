import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/dates/date_utils.dart';
import '../../../core/money/money.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/amount_display.dart';
import '../../../shared/widgets/category_badge.dart';
import '../../../shared/widgets/financial_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/recurring_transaction.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recurringAsync = ref.watch(recurringListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring & Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Recurring Payment',
            onPressed: () => _showAddRecurringSheet(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: recurringAsync.when(
          loading: () => const Padding(
            padding: AppSpacing.pagePadding,
            child: LoadingSkeletonList(count: 3),
          ),
          error: (err, _) => ErrorStateView(
            message: err.toString(),
            onRetry: () => ref.invalidate(recurringListProvider),
          ),
          data: (recurringList) {
            if (recurringList.isEmpty) {
              return EmptyStateView(
                icon: Icons.repeat_rounded,
                title: 'No Recurring Activity',
                subtitle: 'Track recurring rent, subscriptions, bills, or salary payouts automatically.',
                actionLabel: 'Add Recurring Bill',
                onAction: () => _showAddRecurringSheet(context, ref),
              );
            }

            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: recurringList.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = recurringList[index];
                final cat = item.category;
                final iconKey = cat?.iconKey ?? (item.isIncome ? 'work' : 'bolt');

                return FinancialCard(
                  child: Row(
                    children: [
                      CategoryBadge(iconKey: iconKey, colorHex: cat?.colorHex),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              style: AppTypography.heading3.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.frequency.toUpperCase()} • Next: ${AppDateUtils.formatShort(item.nextExpectedDate)}',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AmountDisplay(
                        money: item.amount,
                        showSign: true,
                        style: AppTypography.amount(
                          color: item.isIncome
                              ? (isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen)
                              : (isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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

  void _showAddRecurringSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddRecurringSheet(),
    );
  }
}

class _AddRecurringSheet extends ConsumerStatefulWidget {
  const _AddRecurringSheet();

  @override
  ConsumerState<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<_AddRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _frequency = 'monthly';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userProfile = ref.read(currentUserProfileProvider).valueOrNull;
    final currency = userProfile?.preferredCurrency ?? 'USD';
    final parsedMoney = Money.tryParse(_amountController.text, currency);

    if (parsedMoney == null || parsedMoney.isZero || parsedMoney.isNegative) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final recurring = RecurringTransaction(
        id: const Uuid().v4(),
        userId: userProfile?.id ?? 'demo-user-1',
        transactionType: 'expense',
        amount: parsedMoney,
        currencyCode: currency,
        description: _descController.text.trim(),
        frequency: _frequency,
        startDate: now,
        nextExpectedDate: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(recurringListProvider.notifier).addRecurring(recurring);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring activity added.'),
            backgroundColor: AppColors.incomeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add recurring activity: $e')),
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
                'Add Recurring Schedule',
                style: AppTypography.heading2.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description / Subscription',
                  hintText: 'e.g. Netflix, Gym, Rent, Internet',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  hintText: 'e.g. 19.99',
                  prefixText: '\$ ',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                ],
                onChanged: (val) => setState(() => _frequency = val ?? 'monthly'),
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
                    : const Text('Save Recurring Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
