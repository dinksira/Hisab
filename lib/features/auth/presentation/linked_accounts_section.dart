import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/financial_card.dart';
import '../data/auth_errors.dart';
import '../data/auth_state.dart';

/// Lists the login identities (email, Google, ...) that are linked to the
/// signed-in account and lets the user remove the ones they no longer use.
class LinkedAccountsSection extends ConsumerStatefulWidget {
  const LinkedAccountsSection({super.key});

  @override
  ConsumerState<LinkedAccountsSection> createState() => _LinkedAccountsSectionState();
}

class _LinkedAccountsSectionState extends ConsumerState<LinkedAccountsSection> {
  List<AuthIdentity>? _identities;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final identities = await ref.read(authControllerProvider).getIdentities();
      if (!mounted) return;
      setState(() {
        _identities = identities;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AuthErrors.message(error);
      });
    }
  }

  Future<void> _unlink(AuthIdentity identity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove sign-in method?'),
        content: Text(
          'You will no longer be able to sign in with ${identity.label}. '
          'Make sure you keep at least one way to sign in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authControllerProvider).unlinkIdentity(identity.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthErrors.message(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final identities = _identities ?? const <AuthIdentity>[];
    final canRemove = identities.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign-in Methods',
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
              if (_isLoading)
                const Padding(
                  padding: AppSpacing.cardPadding,
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: AppSpacing.cardPadding,
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkExpenseOrange : AppColors.expenseAccent,
                    ),
                  ),
                )
              else if (identities.isEmpty)
                Padding(
                  padding: AppSpacing.cardPadding,
                  child: Text(
                    'No sign-in methods are linked to this account yet.',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
                    ),
                  ),
                )
              else
                for (var index = 0; index < identities.length; index++) ...[
                  if (index > 0) const Divider(indent: 52),
                  _IdentityTile(
                    identity: identities[index],
                    canRemove: canRemove,
                    onRemove: () => _unlink(identities[index]),
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IdentityTile extends StatelessWidget {
  const _IdentityTile({
    required this.identity,
    required this.canRemove,
    required this.onRemove,
  });

  final AuthIdentity identity;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subtitle = identity.email ??
        identity.displayName ??
        (identity.isGoogle ? 'Google account' : 'Email address');

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
          borderRadius: AppRadii.radiusSm,
        ),
        child: Icon(
          identity.isGoogle ? Icons.g_mobiledata_rounded : Icons.mail_outline_rounded,
          size: 20,
          color: isDark ? AppColors.mintAccent : AppColors.forestPrimary,
        ),
      ),
      title: Text(
        identity.label,
        style: AppTypography.heading3.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.secondaryText,
        ),
      ),
      trailing: canRemove
          ? IconButton(
              tooltip: 'Remove ${identity.label}',
              onPressed: onRemove,
              icon: Icon(
                Icons.link_off_rounded,
                size: 18,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            )
          : Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: isDark ? AppColors.darkIncomeGreen : AppColors.incomeGreen,
            ),
    );
  }
}
