import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/dates/date_utils.dart';
import '../../../core/money/money.dart';
import '../../../shared/providers/providers.dart';
import '../domain/transaction.dart';

class CreateEditTransactionScreen extends ConsumerStatefulWidget {
  final String? initialType; // 'expense' | 'income'
  final String? transactionId; // for editing

  const CreateEditTransactionScreen({
    super.key,
    this.initialType,
    this.transactionId,
  });

  @override
  ConsumerState<CreateEditTransactionScreen> createState() =>
      _CreateEditTransactionScreenState();
}

class _CreateEditTransactionScreenState
    extends ConsumerState<CreateEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = AppDateUtils.dateOnly(DateTime.now());
  String? _selectedCategoryId;
  String? _selectedAccountId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'expense';

    if (widget.transactionId != null) {
      // Pre-fill existing transaction data if editing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final txs = ref.read(transactionsListProvider).valueOrNull ?? [];
        final found = txs.cast<FinancialTransaction?>().firstWhere(
              (t) => t?.id == widget.transactionId,
              orElse: () => null,
            );
        if (found != null && mounted) {
          setState(() {
            _type = found.transactionType;
            _amountController.text = found.amount.amount.toString();
            _descController.text = found.description;
            _merchantController.text = found.merchant ?? '';
            _notesController.text = found.notes ?? '';
            _selectedDate = found.transactionDate;
            _selectedCategoryId = found.categoryId;
            _selectedAccountId = found.accountId;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = AppDateUtils.dateOnly(picked));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userProfile = ref.read(currentUserProfileProvider);
    final currency = userProfile?.preferredCurrency ?? 'USD';
    final parsedMoney = Money.tryParse(_amountController.text, currency);

    if (parsedMoney == null || parsedMoney.isZero || parsedMoney.isNegative) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final tx = FinancialTransaction(
        id: widget.transactionId ?? const Uuid().v4(),
        userId: userProfile?.id ?? 'demo-user-1',
        accountId: _selectedAccountId,
        categoryId: _selectedCategoryId,
        transactionType: _type,
        amount: parsedMoney,
        currencyCode: currency,
        description: _descController.text.trim(),
        merchant: _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        transactionDate: _selectedDate,
        createdAt: now,
        updatedAt: now,
      );

      if (widget.transactionId != null) {
        await ref.read(transactionsListProvider.notifier).updateTransaction(tx);
      } else {
        await ref.read(transactionsListProvider.notifier).addTransaction(tx);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transactionId != null
                ? 'Transaction updated successfully.'
                : 'Transaction recorded successfully.'),
            backgroundColor: _type == 'expense' ? AppColors.expenseAccent : AppColors.incomeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save transaction: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This will permanently delete this transaction and recalculate all balances.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && widget.transactionId != null) {
      await ref.read(transactionsListProvider.notifier).deleteTransaction(widget.transactionId!);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.watch(categoriesListProvider).valueOrNull ?? [];
    final accounts = ref.watch(accountsListProvider).valueOrNull ?? [];
    final userProfile = ref.watch(currentUserProfileProvider);
    final currency = userProfile?.preferredCurrency ?? 'USD';

    final filteredCategories = categories.where((c) => c.transactionType == _type).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionId != null ? 'Edit Transaction' : 'Record Transaction'),
        actions: [
          if (widget.transactionId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expenseAccent),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type Switcher Tabs (Expense / Income)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceSubtle,
                    borderRadius: AppRadii.radiusMd,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Expense',
                          isSelected: _type == 'expense',
                          color: isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange,
                          onTap: () {
                            setState(() {
                              _type = 'expense';
                              _selectedCategoryId = null;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'Income',
                          isSelected: _type == 'income',
                          color: isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen,
                          onTap: () {
                            setState(() {
                              _type = 'income';
                              _selectedCategoryId = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Amount Large Numeric Input Card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: AppRadii.radiusLg,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'AMOUNT ($currency)',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: AppTypography.balanceNumber(
                          color: _type == 'expense'
                              ? (isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange)
                              : (isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen),
                          fontSize: 38,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter amount';
                          if (double.tryParse(val.trim()) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Description
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'e.g. Weekly Groceries, Rent, Salary',
                    prefixIcon: Icon(Icons.description_outlined, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter a description';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Category Selection
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined, size: 20),
                  ),
                  items: filteredCategories.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                ),

                const SizedBox(height: AppSpacing.md),

                // Account Selection
                DropdownButtonFormField<String>(
                  initialValue: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Account',
                    prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
                  ),
                  items: accounts.map((a) {
                    return DropdownMenuItem<String>(
                      value: a.id,
                      child: Text('${a.name} (${a.currentBalance.formatted()})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                ),

                const SizedBox(height: AppSpacing.md),

                // Date Picker Tile
                InkWell(
                  onTap: _pickDate,
                  borderRadius: AppRadii.radiusMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: AppRadii.radiusMd,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              AppDateUtils.formatShort(_selectedDate),
                              style: AppTypography.bodyMedium.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Change',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.mintAccent : AppColors.forestPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Merchant (Optional)
                TextFormField(
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Merchant / Payee (Optional)',
                    hintText: 'e.g. Target, Uber, Apple',
                    prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Notes (Optional)
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Additional details or context...',
                    prefixIcon: Icon(Icons.notes_rounded, size: 20),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Save Action Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == 'expense'
                        ? (isDark ? AppColors.darkExpenseOrange : AppColors.forestPrimary)
                        : (isDark ? AppColors.darkIncomeGreen : AppColors.forestPrimary),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.transactionId != null ? 'Update Transaction' : 'Save Transaction'),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.radiusSm,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: AppRadii.radiusSm,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.secondaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
