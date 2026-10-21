import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/hisab_logo.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/amount_display.dart';
import '../../../shared/widgets/app_progress_bar.dart';
import '../../../shared/widgets/financial_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/transaction_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = ref.watch(dashboardSummaryProvider);
    final userProfile = ref.watch(currentUserProfileProvider);
    final isPrivacy = ref.watch(privacyModeProvider);

    final displayName = userProfile?.displayName?.split(' ').first ?? 'Friend';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(accountsListProvider);
            ref.invalidate(transactionsListProvider);
            ref.invalidate(budgetsListProvider);
            ref.invalidate(savingsGoalsListProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Brand mark, Greeting & Privacy Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good day, $displayName',
                          style: AppTypography.heading2.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Know your money. Own your future.',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isPrivacy ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                            size: 22,
                          ),
                          tooltip: 'Toggle Privacy',
                          onPressed: () {
                            ref.read(privacyModeProvider.notifier).toggle();
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const HisabLogo(size: 28, showText: false),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Primary Total Balance Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? const [AppColors.deepForest, Color(0xFF1B3D33)]
                          : const [AppColors.forestPrimary, Color(0xFF1F5243)],
                    ),
                    borderRadius: AppRadii.radiusXl,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : AppColors.forestPrimary).withAlpha(40),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'NET LIQUID ASSETS',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.mintAccent,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius: AppRadii.radiusPill,
                            ),
                            child: Text(
                              'All Accounts',
                              style: AppTypography.labelSmall.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AmountDisplay(
                        money: summary.totalBalance,
                        style: AppTypography.balanceNumber(
                          color: Colors.white,
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BalanceMiniStat(
                            label: 'Monthly Inflow',
                            money: summary.periodIncome,
                            icon: Icons.south_west_rounded,
                            iconColor: AppColors.mintAccent,
                          ),
                          Container(width: 1, height: 28, color: Colors.white24),
                          _BalanceMiniStat(
                            label: 'Monthly Outflow',
                            money: summary.periodExpense,
                            icon: Icons.north_east_rounded,
                            iconColor: AppColors.expenseAccent,
                          ),
                          Container(width: 1, height: 28, color: Colors.white24),
                          _BalanceMiniStat(
                            label: 'Net Cash Flow',
                            money: summary.netCashFlow,
                            icon: Icons.trending_up_rounded,
                            iconColor: summary.netCashFlow.isNegative
                                ? AppColors.expenseAccent
                                : AppColors.mintAccent,
                            showSign: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Actionable Insight Banner
                _ActionableInsightBanner(summary: summary),

                const SizedBox(height: AppSpacing.xl),

                // Active Budget Status Card
                if (summary.activeBudget != null && summary.budgetProgress != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Budget',
                        style: AppTypography.heading2.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/budgets'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinancialCard(
                    onTap: () => context.go('/budgets'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              summary.activeBudget!.name,
                              style: AppTypography.heading3.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: summary.budgetProgress!.isOverBudget
                                    ? (isDark ? AppColors.darkExpenseOrangeLight : AppColors.expenseOrangeLight)
                                    : (isDark ? AppColors.darkIncomeGreenLight : AppColors.incomeGreenLight),
                                borderRadius: AppRadii.radiusPill,
                              ),
                              child: Text(
                                summary.budgetProgress!.isOverBudget ? 'Over Budget' : 'On Track',
                                style: AppTypography.labelSmall.copyWith(
                                  color: summary.budgetProgress!.isOverBudget
                                      ? (isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange)
                                      : (isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppProgressBar(
                          progress: summary.budgetProgress!.progress,
                          isBudget: true,
                          height: 8,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spent: ${summary.budgetProgress!.spent.formatted()}',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            Text(
                              summary.budgetProgress!.isOverBudget
                                  ? 'Exceeded: ${summary.budgetProgress!.remaining.abs().formatted()}'
                                  : 'Remaining: ${summary.budgetProgress!.remaining.formatted()}',
                              style: AppTypography.bodySmall.copyWith(
                                color: summary.budgetProgress!.isOverBudget
                                    ? (isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange)
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // Spending by Category Breakdown
                if (summary.categorySpendTotals.isNotEmpty) ...[
                  Text(
                    'Monthly Spending Breakdown',
                    style: AppTypography.heading2.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinancialCard(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 44,
                              sections: summary.categorySpendPercentages.entries.map((e) {
                                final color = _resolveCategoryChartColor(e.key);
                                return PieChartSectionData(
                                  color: color,
                                  value: e.value * 100,
                                  title: '${(e.value * 100).toInt()}%',
                                  radius: 36,
                                  titleStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: summary.categorySpendTotals.entries.map((e) {
                            final color = _resolveCategoryChartColor(e.key);
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${e.key} (${e.value.formatted()})',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // Recent Transactions Header & List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: AppTypography.heading2.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/transactions'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                if (summary.recentTransactions.isEmpty)
                  EmptyStateView(
                    icon: Icons.receipt_long_rounded,
                    title: 'No Transactions Yet',
                    subtitle: 'Tap the "+" button to record your first expense or income.',
                    actionLabel: 'Record First Expense',
                    onAction: () => context.push('/transactions/create?type=expense'),
                  )
                else
                  FinancialCard(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.sm),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: summary.recentTransactions.length,
                      separatorBuilder: (context, index) => Divider(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        indent: 56,
                      ),
                      itemBuilder: (_, index) {
                        final tx = summary.recentTransactions[index];
                        return TransactionTile(
                          transaction: tx,
                          onTap: () => context.push('/transactions/${tx.id}'),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: AppSpacing.giant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _resolveCategoryChartColor(String category) {
    switch (category.toLowerCase()) {
      case 'housing & rent':
        return const Color(0xFF173D32);
      case 'groceries & dining':
      case 'groceries & food':
        return const Color(0xFF46C89A);
      case 'transportation':
        return const Color(0xFF6C8FE8);
      case 'utilities & bills':
        return const Color(0xFFD9A441);
      case 'entertainment':
      case 'entertainment & leisure':
        return const Color(0xFFE58B68);
      default:
        return const Color(0xFF8A9A93);
    }
  }
}

class _BalanceMiniStat extends StatelessWidget {
  final String label;
  final Money money;
  final IconData icon;
  final Color iconColor;
  final bool showSign;

  const _BalanceMiniStat({
    required this.label,
    required this.money,
    required this.icon,
    required this.iconColor,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AmountDisplay(
          money: money,
          showSign: showSign,
          compact: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionableInsightBanner extends StatelessWidget {
  final DashboardSummary summary;

  const _ActionableInsightBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String insightText = 'Financial activity is on track. Keep recording your expenses.';
    IconData icon = Icons.check_circle_outline_rounded;
    Color iconColor = isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen;

    if (summary.budgetProgress != null && summary.budgetProgress!.isOverBudget) {
      insightText = 'Budget limit exceeded for ${summary.activeBudget?.name}. Review discretionary spending.';
      icon = Icons.warning_amber_rounded;
      iconColor = isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange;
    } else if (summary.netCashFlow.isPositive && !summary.netCashFlow.isZero) {
      insightText = 'Positive net flow of ${summary.netCashFlow.formatted()} this month. Consider adding to your savings goals.';
      icon = Icons.trending_up_rounded;
      iconColor = AppColors.mintAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(isDark ? 30 : 20),
        borderRadius: AppRadii.radiusMd,
        border: Border.all(color: iconColor.withAlpha(60), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              insightText,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
