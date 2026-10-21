import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/hisab_logo.dart';
import '../../../shared/providers/providers.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: AppSpacing.md),
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
                      await ref.read(currentUserProfileProvider.notifier).signIn('demo@hisab.app', 'demo1234');
                      if (context.mounted) {
                        context.go('/dashboard');
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
