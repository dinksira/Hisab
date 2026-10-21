import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/providers/providers.dart';
import '../data/auth_errors.dart';
import 'widgets/auth_error_banner.dart';

/// Confirms that a registration was completed and the email still has to be
/// verified before the account can be used.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const int _cooldownSeconds = 60;

  Timer? _cooldownTimer;
  int _secondsLeft = 0;
  bool _isSending = false;
  bool _resent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    if (widget.email.isEmpty) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authControllerProvider)
          .resendConfirmation(email: widget.email);
      if (mounted) {
        setState(() => _resent = true);
        _startCooldown();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = AuthErrors.message(error));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canResend = _secondsLeft <= 0 && !_isSending;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.giant),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkIncomeGreenLight : AppColors.incomeGreenLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 32,
                    color: isDark ? AppColors.darkIncomeGreen : AppColors.forestPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Verify your email',
                style: AppTypography.displayMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.email.isEmpty
                    ? 'We sent a confirmation link to your email address.'
                    : 'We sent a confirmation link to\n${widget.email}',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              if (_errorMessage != null) ...[
                AuthErrorBanner(
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (_resent) ...[
                Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkIncomeGreenLight : AppColors.incomeGreenLight,
                    borderRadius: AppRadii.radiusMd,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: isDark ? AppColors.darkIncomeGreen : AppColors.forestPrimary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'A new confirmation link is on its way.',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                  borderRadius: AppRadii.radiusMd,
                ),
                child: Text(
                  'Open the link on this device to activate your account. You can close this screen in the meantime.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              OutlinedButton(
                onPressed: canResend ? _resend : null,
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _secondsLeft > 0
                            ? 'Resend in ${_secondsLeft}s'
                            : 'Resend confirmation email',
                      ),
              ),

              const SizedBox(height: AppSpacing.sm),

              TextButton(
                onPressed: _isSending ? null : () => context.go('/auth?mode=register'),
                child: const Text('Use a different email'),
              ),

              const SizedBox(height: AppSpacing.sm),

              TextButton(
                onPressed: () => context.go('/welcome'),
                child: const Text('Back to welcome'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
