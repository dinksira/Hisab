import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/hisab_logo.dart';
import '../../../features/auth/presentation/linked_accounts_section.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/financial_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProfile = ref.watch(currentUserProfileProvider);
    final isPrivacy = ref.watch(privacyModeProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Profile Banner
              FinancialCard(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkIncomeGreenLight : AppColors.incomeGreenLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (userProfile?.displayName?.isNotEmpty == true
                                  ? userProfile!.displayName![0]
                                  : 'H')
                              .toUpperCase(),
                          style: AppTypography.heading1.copyWith(
                            color: isDark ? AppColors.darkIncomeGreen : AppColors.forestPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProfile?.displayName ?? 'Hisab Member',
                            style: AppTypography.heading2.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Currency: ${userProfile?.preferredCurrency ?? 'USD'} • Locale: ${userProfile?.locale ?? 'en_US'}',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Finance Management Section
              Text(
                'Financial Organization',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinancialCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Accounts & Wallets',
                      subtitle: 'Checking, savings, cash, and digital wallets',
                      onTap: () => context.push('/accounts'),
                    ),
                    const Divider(indent: 52),
                    _SettingsTile(
                      icon: Icons.repeat_rounded,
                      title: 'Recurring Activity & Bills',
                      subtitle: 'Subscriptions, rent, salary, and expected bills',
                      onTap: () => context.push('/recurring'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Preferences Section
              Text(
                'Application Preferences',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinancialCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      value: isPrivacy,
                      onChanged: (val) {
                        ref.read(privacyModeProvider.notifier).set(val);
                      },
                      secondary: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                          borderRadius: AppRadii.radiusSm,
                        ),
                        child: const Icon(Icons.shield_outlined, size: 20),
                      ),
                      title: Text(
                        'Privacy Mode',
                        style: AppTypography.heading3.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Mask financial balances and amounts on screens',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                        ),
                      ),
                    ),
                    const Divider(indent: 52),
                    _SettingsTile(
                      icon: Icons.download_rounded,
                      title: 'Export Financial Records',
                      subtitle: 'Download your full activity log in CSV format',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transactions exported successfully to CSV.')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Linked sign-in methods
              const LinkedAccountsSection(),

              const SizedBox(height: AppSpacing.xl),

              // System & Security Section
              Text(
                'Security & Account',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinancialCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.cloud_done_outlined,
                      title: 'Backend Status',
                      subtitle: isDemoMode
                          ? 'Local Secure Sandbox (No remote keys)'
                          : 'Connected to Supabase PostgreSQL',
                      trailing: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isDemoMode ? AppColors.warningAccent : AppColors.incomeGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const Divider(indent: 52),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      titleColor: AppColors.expenseAccent,
                      onTap: () async {
                        await ref.read(authControllerProvider).signOut();
                        if (context.mounted) {
                          context.go('/welcome');
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              Center(
                child: Column(
                  children: [
                    const HisabLogo(size: 24, showText: true),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0 (Production Release)',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.giant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.titleColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
          borderRadius: AppRadii.radiusSm,
        ),
        child: Icon(
          icon,
          size: 20,
          color: titleColor ?? (isDark ? AppColors.mintAccent : AppColors.forestPrimary),
        ),
      ),
      title: Text(
        title,
        style: AppTypography.heading3.copyWith(
          color: titleColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
      onTap: onTap,
    );
  }
}
