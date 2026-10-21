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
import '../domain/transfer.dart';

class CreateTransferScreen extends ConsumerStatefulWidget {
  const CreateTransferScreen({super.key});

  @override
  ConsumerState<CreateTransferScreen> createState() => _CreateTransferScreenState();
}

class _CreateTransferScreenState extends ConsumerState<CreateTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _fromAccountId;
  String? _toAccountId;
  final DateTime _transferDate = AppDateUtils.dateOnly(DateTime.now());
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromAccountId == null || _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both source and destination accounts.')),
      );
      return;
    }

    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and destination accounts must be different.')),
      );
      return;
    }

    final userProfile = ref.read(currentUserProfileProvider).valueOrNull;
    final currency = userProfile?.preferredCurrency ?? 'USD';
    final parsedMoney = Money.tryParse(_amountController.text, currency);

    if (parsedMoney == null || parsedMoney.isZero || parsedMoney.isNegative) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive transfer amount.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final transfer = AccountTransfer(
        id: const Uuid().v4(),
        userId: userProfile?.id ?? 'demo-user-1',
        fromAccountId: _fromAccountId!,
        toAccountId: _toAccountId!,
        amount: parsedMoney,
        currencyCode: currency,
        transferDate: _transferDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(transfersListProvider.notifier).addTransfer(transfer);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer recorded successfully.'),
            backgroundColor: AppColors.infoAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record transfer: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accounts = ref.watch(accountsListProvider).valueOrNull ?? [];
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final currency = userProfile?.preferredCurrency ?? 'USD';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Account Transfer'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Transfer Icon Banner
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkTransferBlueLight : AppColors.transferBlueLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sync_alt_rounded,
                      color: isDark ? AppColors.darkTransferBlue : AppColors.transferBlue,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Move money between accounts',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Amount Input Card
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
                    children: [
                      Text(
                        'TRANSFER AMOUNT ($currency)',
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
                          color: isDark ? AppColors.darkTransferBlue : AppColors.forestPrimary,
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
                          if (val == null || val.trim().isEmpty) return 'Enter transfer amount';
                          if (double.tryParse(val.trim()) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // From Account
                DropdownButtonFormField<String>(
                  initialValue: _fromAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Transfer From (Source Account)',
                    prefixIcon: Icon(Icons.arrow_upward_rounded, size: 20),
                  ),
                  items: accounts.map((a) {
                    return DropdownMenuItem<String>(
                      value: a.id,
                      child: Text('${a.name} (${a.currentBalance.formatted()})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _fromAccountId = val),
                ),

                const SizedBox(height: AppSpacing.md),

                // To Account
                DropdownButtonFormField<String>(
                  initialValue: _toAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Transfer To (Destination Account)',
                    prefixIcon: Icon(Icons.arrow_downward_rounded, size: 20),
                  ),
                  items: accounts.map((a) {
                    return DropdownMenuItem<String>(
                      value: a.id,
                      child: Text('${a.name} (${a.currentBalance.formatted()})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _toAccountId = val),
                ),

                const SizedBox(height: AppSpacing.md),

                // Notes (Optional)
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Transfer Memo / Notes (Optional)',
                    hintText: 'e.g. Monthly savings allocation',
                    prefixIcon: Icon(Icons.notes_rounded, size: 20),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Execute Transfer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
