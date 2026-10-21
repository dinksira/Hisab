import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/money/money.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/amount_display.dart';
import '../../../shared/widgets/financial_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/account.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accountsAsync = ref.watch(accountsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Account',
            onPressed: () => _showCreateAccountSheet(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: accountsAsync.when(
          loading: () => const Padding(
            padding: AppSpacing.pagePadding,
            child: LoadingSkeletonList(count: 3),
          ),
          error: (err, _) => ErrorStateView(
            message: err.toString(),
            onRetry: () => ref.invalidate(accountsListProvider),
          ),
          data: (accounts) {
            if (accounts.isEmpty) {
              return EmptyStateView(
                icon: Icons.account_balance_outlined,
                title: 'No Accounts Yet',
                subtitle: 'Add your bank account, wallet, or cash fund to begin accurate tracking.',
                actionLabel: 'Add Account',
                onAction: () => _showCreateAccountSheet(context, ref),
              );
            }

            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: accounts.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final account = accounts[index];
                final icon = _getAccountIcon(account.accountType);

                return FinancialCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                          borderRadius: AppRadii.radiusMd,
                        ),
                        child: Icon(
                          icon,
                          color: isDark ? AppColors.mintAccent : AppColors.forestPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: AppTypography.heading3.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${account.accountType.toUpperCase()} • Opening: ${account.openingBalance.formatted()}',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AmountDisplay(
                        money: account.currentBalance,
                        style: AppTypography.amount(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'checking':
        return Icons.account_balance_rounded;
      case 'savings':
        return Icons.savings_outlined;
      case 'cash':
        return Icons.payments_outlined;
      case 'wallet':
        return Icons.wallet_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  void _showCreateAccountSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateAccountSheet(),
    );
  }
}

class _CreateAccountSheet extends ConsumerStatefulWidget {
  const _CreateAccountSheet();

  @override
  ConsumerState<_CreateAccountSheet> createState() => _CreateAccountSheetState();
}

class _CreateAccountSheetState extends ConsumerState<_CreateAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  String _accountType = 'checking';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userProfile = ref.read(currentUserProfileProvider);
    final currency = userProfile?.preferredCurrency ?? 'USD';
    final parsedOpening = Money.tryParse(_balanceController.text, currency);

    if (parsedOpening == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid opening balance.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final account = Account(
        id: const Uuid().v4(),
        userId: userProfile?.id ?? 'demo-user-1',
        name: _nameController.text.trim(),
        accountType: _accountType,
        currencyCode: currency,
        openingBalance: parsedOpening,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(accountsListProvider.notifier).createAccount(account);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully.'),
            backgroundColor: AppColors.incomeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create account: $e')),
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
                'Add New Account',
                style: AppTypography.heading2.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'e.g. Main Checking, Savings, Cash Pocket',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _accountType,
                decoration: const InputDecoration(labelText: 'Account Type'),
                items: const [
                  DropdownMenuItem(value: 'checking', child: Text('Checking Account')),
                  DropdownMenuItem(value: 'savings', child: Text('Savings Account')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash Wallet')),
                  DropdownMenuItem(value: 'wallet', child: Text('Digital Wallet')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => _accountType = val ?? 'checking'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Opening Balance',
                  hintText: 'e.g. 1500.00',
                  prefixText: '\$ ',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter opening balance' : null,
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
                    : const Text('Add Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
