import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/dates/date_utils.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/financial_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _selectedFilter = 'all'; // 'all' | 'expense' | 'income'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactionsAsync = ref.watch(transactionsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity & History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Transaction',
            onPressed: () => context.push('/transactions/create?type=expense'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search descriptions, merchants...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Type Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Activity',
                    isSelected: _selectedFilter == 'all',
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Expenses',
                    isSelected: _selectedFilter == 'expense',
                    color: isDark ? AppColors.darkExpenseOrange : AppColors.expenseOrange,
                    onTap: () => setState(() => _selectedFilter = 'expense'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Income',
                    isSelected: _selectedFilter == 'income',
                    color: isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen,
                    onTap: () => setState(() => _selectedFilter = 'income'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Transaction List
            Expanded(
              child: transactionsAsync.when(
                loading: () => const Padding(
                  padding: AppSpacing.pagePadding,
                  child: LoadingSkeletonList(count: 6),
                ),
                error: (err, _) => ErrorStateView(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(transactionsListProvider),
                ),
                data: (allTransactions) {
                  var filtered = allTransactions;

                  if (_selectedFilter != 'all') {
                    filtered = filtered.where((t) => t.transactionType == _selectedFilter).toList();
                  }

                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    filtered = filtered.where((t) =>
                        t.description.toLowerCase().contains(q) ||
                        (t.merchant?.toLowerCase().contains(q) ?? false)).toList();
                  }

                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.receipt_long_rounded,
                      title: 'No Matching Activity',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'No transactions match "$_searchQuery".'
                          : 'You have not recorded any ${_selectedFilter != 'all' ? _selectedFilter : ''} transactions yet.',
                      actionLabel: 'Add Transaction',
                      onAction: () => context.push('/transactions/create?type=expense'),
                    );
                  }

                  // Group transactions by date
                  final grouped = <DateTime, List<dynamic>>{};
                  for (final tx in filtered) {
                    final dateKey = AppDateUtils.dateOnly(tx.transactionDate);
                    grouped.putIfAbsent(dateKey, () => []).add(tx);
                  }

                  final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final dayTxs = grouped[date]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
                            child: Text(
                              AppDateUtils.formatRelative(date).toUpperCase(),
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          FinancialCard(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dayTxs.length,
                              separatorBuilder: (context, index) => Divider(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                indent: 56,
                              ),
                              itemBuilder: (_, txIndex) {
                                final tx = dayTxs[txIndex];
                                return TransactionTile(
                                  transaction: tx,
                                  onTap: () => context.push('/transactions/${tx.id}'),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = color ?? (isDark ? AppColors.mintAccent : AppColors.forestPrimary);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.radiusPill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withAlpha(isDark ? 50 : 30)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: AppRadii.radiusPill,
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected
                ? activeColor
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
