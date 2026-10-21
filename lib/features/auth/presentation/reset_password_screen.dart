import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/hisab_logo.dart';
import '../../../shared/providers/providers.dart';
import '../data/auth_errors.dart';
import 'widgets/auth_error_banner.dart';

/// Lets the user pick a new password after following a recovery link.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
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
          .updatePassword(newPassword: _passwordController.text);
      if (mounted) {
        context.go('/welcome');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your password has been updated.')),
        );
      }
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
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                const Center(child: HisabLogo(size: 40, showText: false)),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Choose a new password',
                  style: AppTypography.displayMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pick something you have not used before. At least 8 characters.',
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
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Minimum 8 characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter a new password';
                    if (val.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Repeat the new password';
                    if (val != _passwordController.text) return 'Passwords do not match';
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
                      : const Text('Update password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
