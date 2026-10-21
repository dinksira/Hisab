import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Inline, dismissable error banner used across the authentication screens.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkExpenseOrangeLight : AppColors.expenseOrangeLight,
        borderRadius: AppRadii.radiusSm,
        border: Border.all(
          color: isDark ? AppColors.darkExpenseOrange : AppColors.expenseAccent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: isDark ? AppColors.darkExpenseOrange : AppColors.expenseAccent,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
              ),
            ),
        ],
      ),
    );
  }
}
