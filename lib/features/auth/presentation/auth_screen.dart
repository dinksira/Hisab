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
import 'widgets/google_sign_in_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final String initialMode; // 'login' | 'register'

  const AuthScreen({super.key, this.initialMode = 'login'});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isLogin;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialMode == 'register' ? false : true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _setError(Object error) {
    if (!mounted) return;
    setState(() => _errorMessage = AuthErrors.message(error));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    try {
      final controller = ref.read(authControllerProvider);
      if (_isLogin) {
        await controller.signIn(email: email, password: password);
      } else {
        await controller.signUp(
          email: email,
          password: password,
          displayName: name.isEmpty ? null : name,
        );
      }
      // Navigation is owned by the router: it reacts to the auth state and
      // moves to the dashboard, the verification screen or the welcome screen.
    } catch (error) {
      _setError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authControllerProvider).signInWithGoogle();
      // The browser takes over. When the user comes back the auth stream
      // reports the new session and the router navigates to the dashboard.
    } catch (error) {
      _setError(error);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBusy = _isLoading || _isGoogleLoading;

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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                const Center(child: HisabLogo(size: 40, showText: false)),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _isLogin ? 'Welcome back' : 'Create your account',
                  style: AppTypography.displayMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _isLogin
                      ? 'Sign in to access your financial records'
                      : 'Begin your journey to financial peace of mind',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                GoogleSignInButton(
                  onPressed: isBusy ? null : _signInWithGoogle,
                  isLoading: _isGoogleLoading,
                ),

                const SizedBox(height: AppSpacing.lg),
                _OrDivider(isDark: isDark),
                const SizedBox(height: AppSpacing.lg),

                if (_errorMessage != null) ...[
                  AuthErrorBanner(
                    message: _errorMessage!,
                    onDismiss: () => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      hintText: 'e.g. Tariq Vance',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    validator: (val) {
                      if (!_isLogin && (val == null || val.trim().isEmpty)) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
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
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => isBusy ? null : _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
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
                    if (val == null || val.isEmpty) return 'Enter your password';
                    if (val.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.sm),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isBusy
                        ? null
                        : () => context.push('/auth/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                ElevatedButton(
                  onPressed: isBusy ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isLogin ? 'Sign In' : 'Create Account'),
                ),

                const SizedBox(height: AppSpacing.lg),

                TextButton(
                  onPressed: isBusy
                      ? null
                      : () => setState(() {
                            _isLogin = !_isLogin;
                            _errorMessage = null;
                          }),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign up"
                        : 'Already have an account? Sign in',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "or" separator between the Google button and the email form.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Row(
      children: [
        Expanded(child: Divider(color: color, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'or',
            style: AppTypography.bodySmall.copyWith(color: textColor),
          ),
        ),
        Expanded(child: Divider(color: color, height: 1)),
      ],
    );
  }
}
