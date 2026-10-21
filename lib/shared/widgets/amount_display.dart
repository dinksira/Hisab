import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/money/money.dart';
import '../providers/providers.dart';

class AmountDisplay extends ConsumerWidget {
  final Money money;
  final TextStyle? style;
  final bool showSign;
  final bool compact;
  final Color? colorOverride;

  const AmountDisplay({
    super.key,
    required this.money,
    this.style,
    this.showSign = false,
    this.compact = false,
    this.colorOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivate = ref.watch(privacyModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color defaultColor;
    if (showSign) {
      if (money.isPositive) {
        defaultColor = isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen;
      } else if (money.isNegative) {
        defaultColor = isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange;
      } else {
        defaultColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
      }
    } else {
      defaultColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    }

    final effectiveColor = colorOverride ?? defaultColor;
    final textStyle = (style ?? AppTypography.amount(color: effectiveColor)).copyWith(color: effectiveColor);

    if (isPrivate) {
      return Text(
        '••••••',
        style: textStyle.copyWith(letterSpacing: 2.0),
      );
    }

    final formattedText = showSign
        ? money.formattedWithSign()
        : money.formatted(compact: compact);

    return Text(
      formattedText,
      style: textStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
