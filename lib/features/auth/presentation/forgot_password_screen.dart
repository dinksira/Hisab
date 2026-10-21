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
import 'widgets/auth_error_banner.dart';

/// Asks for the email address so that a password reset link can be sent.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authControllerProvider)
          .resetPassword(email: _emailController.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = AuthErrors.message(error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: _sent ? _buildSentState(isDark) : _buildForm(isDark),
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          const Center(child: HisabLogo(size: 40, showText: false)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Reset your password',
            style: AppTypography.displayMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter the email address you use for Hisab and we will send you a link to choose a new password.',
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

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _isLoading ? null : _submit(),
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'name@example.com',
              prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter email';
              if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email';
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Send reset link'),
          ),

          const SizedBox(height: AppSpacing.lg),

          TextButton(
            onPressed: _isLoading ? null : () => context.pop(),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }

  Widget _buildSentState(bool isDark) {
    final email = _emailController.text.trim();

    return Column(
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
          'Check your inbox',
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'We sent a password reset link to\n$email',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
            borderRadius: AppRadii.radiusMd,
          ),
          child: Text(
            'The link expires shortly. If it does not arrive, check your spam folder or request a new one.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: () => context.go('/auth?mode=login'),
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }
}
