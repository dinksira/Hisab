import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/dates/date_utils.dart';
import '../../features/transactions/domain/transaction.dart';
import 'amount_display.dart';
import 'category_badge.dart';

class TransactionTile extends StatelessWidget {
  final FinancialTransaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cat = transaction.category;
    final iconKey = cat?.iconKey ?? (transaction.isIncome ? 'work' : 'category');
    final colorHex = cat?.colorHex;

    final subtitleParts = <String>[];
    if (transaction.account != null) {
      subtitleParts.add(transaction.account!.name);
    }
    subtitleParts.add(AppDateUtils.formatRelative(transaction.transactionDate));
    if (transaction.merchant != null && transaction.merchant!.isNotEmpty) {
      subtitleParts.add(transaction.merchant!);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.radiusMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
          child: Row(
            children: [
              CategoryBadge(
                iconKey: iconKey,
                colorHex: colorHex,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction.description,
                      style: AppTypography.heading3.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitleParts.join(' • '),
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AmountDisplay(
                money: transaction.isExpense ? -transaction.amount : transaction.amount,
                showSign: true,
                style: AppTypography.amount(
                  color: transaction.isIncome
                      ? (isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen)
                      : (isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
