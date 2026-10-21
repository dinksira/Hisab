import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/hisab_logo.dart';
import '../../../shared/providers/providers.dart';
import '../data/auth_errors.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDemoMode = ref.watch(isDemoModeProvider);
    final initError = ref.watch(supabaseInitErrorProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Configuration / demo banner
              if (initError != null)
                _Banner(
                  isDark: isDark,
                  isError: true,
                  icon: Icons.error_outline_rounded,
                  title: 'Connection problem',
                  message: 'Hisab could not reach its backend: ${AuthErrors.message(initError)}',
                )
              else if (isDemoMode)
                _Banner(
                  isDark: isDark,
                  isError: false,
                  icon: Icons.science_outlined,
                  title: 'Demo mode',
                  message: 'Running on local sample data. Nothing is saved to a server.',
                ),

              // Brand Presentation Hero
              Column(
                children: [
                  const HisabLogo(size: 64, showText: true),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Know your money.\nOwn your future.',
                    textAlign: TextAlign.center,
                    style: AppTypography.displayMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'A quiet, trustworthy personal finance engine designed to give you complete clarity over expenses, budgets, and savings.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),

              // Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => context.push('/auth?mode=register'),
                    child: const Text('Get Started'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () => context.push('/auth?mode=login'),
                    child: const Text('Sign In with Email'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: () async {
                      // Demo mode instant evaluation
                      try {
                        await ref.read(authControllerProvider).signIn(
                              email: 'demo@hisab.app',
                              password: 'demo1234',
                            );
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AuthErrors.message(error))),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.flash_on_rounded, size: 18),
                    label: const Text('Explore Demo Environment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small status banner shown above the welcome content.
class _Banner extends StatelessWidget {
  const _Banner({
    required this.isDark,
    required this.isError,
    required this.icon,
    required this.title,
    required this.message,
  });

  final bool isDark;
  final bool isError;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final accent = isError
        ? (isDark ? AppColors.darkExpenseOrange : AppColors.expenseAccent)
        : (isDark ? AppColors.darkIncomeGreen : AppColors.forestPrimary);
    final background = isError
        ? (isDark ? AppColors.darkExpenseOrangeLight : AppColors.expenseOrangeLight)
        : (isDark ? AppColors.darkIncomeGreenLight : AppColors.incomeGreenLight);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.radiusSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(color: accent),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
