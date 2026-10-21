import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';

class AppProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0+
  final double height;
  final Color? colorOverride;
  final bool isBudget;

  const AppProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.colorOverride,
    this.isBudget = false,
  });

  Color _resolveColor(BuildContext context) {
    if (colorOverride != null) return colorOverride!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isBudget) {
      if (progress >= 1.0) {
        return isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange;
      } else if (progress >= 0.8) {
        return AppColors.warningAccent;
      } else {
        return isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen;
      }
    } else {
      // For Savings Goals
      if (progress >= 1.0) {
        return isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen;
      }
      return isDark ? AppColors.mintAccent : AppColors.forestPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedRatio = progress.clamp(0.0, 1.0);
    final barColor = _resolveColor(context);
    final trackColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: AppRadii.radiusPill,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clampedRatio,
        child: Container(
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: AppRadii.radiusPill,
          ),
        ),
      ),
    );
  }
}
