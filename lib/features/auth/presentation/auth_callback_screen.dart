import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

/// Landing route for the OAuth callback on the web build.
///
/// `supabase_flutter` extracts the session from the URL and removes the
/// authentication parameters from the address bar. Once the session exists the
/// router redirects to the dashboard, so this screen only has to wait.
class AuthCallbackScreen extends StatelessWidget {
  const AuthCallbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Finishing sign in',
                  style: AppTypography.heading2.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'One moment while we complete your sign in.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                TextButton(
                  onPressed: () => context.go('/welcome'),
                  child: const Text('Cancel and return to welcome'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
