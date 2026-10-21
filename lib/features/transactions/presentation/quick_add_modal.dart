import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

class QuickAddModal extends StatelessWidget {
  const QuickAddModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const QuickAddModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.sheetTopRadius,
      ),
      padding: AppSpacing.sheetPadding,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: AppRadii.radiusPill,
                ),
              ),
            ),
            Text(
              'Record Financial Activity',
              style: AppTypography.heading2.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Fast and accurate bookkeeping',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ActionOption(
              icon: Icons.arrow_outward_rounded,
              title: 'Add Expense',
              subtitle: 'Outflow, bill, purchase, or dining',
              color: isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange,
              bgColor: isDark ? AppColors.darkExpenseOrangeLight : AppColors.expenseOrangeLight,
              onTap: () {
                Navigator.pop(context);
                context.push('/transactions/create?type=expense');
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _ActionOption(
              icon: Icons.arrow_downward_rounded,
              title: 'Add Income',
              subtitle: 'Salary, payout, dividend, or freelance',
              color: isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen,
              bgColor: isDark ? AppColors.darkIncomeGreenLight : AppColors.incomeGreenLight,
              onTap: () {
                Navigator.pop(context);
                context.push('/transactions/create?type=income');
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _ActionOption(
              icon: Icons.sync_alt_rounded,
              title: 'Record Transfer',
              subtitle: 'Move funds between accounts',
              color: isDark ? AppColors.darkTransferBlue : AppColors.transferBlue,
              bgColor: isDark ? AppColors.darkTransferBlueLight : AppColors.transferBlueLight,
              onTap: () {
                Navigator.pop(context);
                context.push('/transfers/create');
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _ActionOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.radiusLg,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.radiusLg,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: AppRadii.radiusMd,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.heading3.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
