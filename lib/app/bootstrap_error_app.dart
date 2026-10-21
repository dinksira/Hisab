import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_radii.dart';
import '../app/theme/app_spacing.dart';
import '../app/theme/app_typography.dart';
import '../features/auth/data/auth_errors.dart';
import 'app.dart';
import 'theme/app_theme.dart';

/// Shown instead of the app when Supabase was configured but could not start.
///
/// Running the finance screens against demo data in this situation would hide
/// a broken configuration, so the failure is surfaced immediately. The user can
/// still continue with local sample data.
class BootstrapErrorApp extends ConsumerStatefulWidget {
  final Object error;

  const BootstrapErrorApp({super.key, required this.error});

  @override
  ConsumerState<BootstrapErrorApp> createState() => _BootstrapErrorAppState();
}

class _BootstrapErrorAppState extends ConsumerState<BootstrapErrorApp> {
  bool _continueWithLocalData = false;

  @override
  Widget build(BuildContext context) {
    if (_continueWithLocalData) {
      return const HisabApp();
    }

    return MaterialApp(
      title: 'Hisab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: _ErrorView(
        error: widget.error,
        onContinue: () => setState(() => _continueWithLocalData = true),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onContinue});

  final Object error;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkExpenseOrangeLight : AppColors.expenseOrangeLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 30,
                    color: isDark ? AppColors.darkExpenseOrange : AppColors.expenseAccent,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Hisab cannot start',
                  textAlign: TextAlign.center,
                  style: AppTypography.heading1.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'The backend was configured but could not be reached. '
                  'Check your Supabase keys and network connection, then restart the app.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                    borderRadius: AppRadii.radiusMd,
                  ),
                  child: Text(
                    AuthErrors.message(error),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton(
                  onPressed: onContinue,
                  child: const Text('Continue with local data'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
