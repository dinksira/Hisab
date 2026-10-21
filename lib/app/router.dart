import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/accounts/presentation/accounts_screen.dart';
import '../features/auth/data/auth_state.dart';
import '../features/auth/presentation/auth_callback_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/budgets/presentation/budgets_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/goals/presentation/goals_screen.dart';
import '../features/recurring/presentation/recurring_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/transactions/presentation/create_edit_transaction_screen.dart';
import '../features/transactions/presentation/create_transfer_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../shared/providers/providers.dart';
import 'scaffold_with_nav_bar.dart';

/// The location the app starts at.
///
/// On the web the browser URL wins, so that the OAuth callback route is
/// actually shown when the user comes back from Google.
String get _initialLocation {
  if (kIsWeb) {
    final path = Uri.base.path;
    if (path.startsWith('/auth')) return path;
  }
  return '/welcome';
}

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  // GoRouter only re-evaluates `redirect` when it is notified, so the auth
  // state is bridged into a listenable that the router subscribes to.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<AuthState>(authStateProvider, (previous, next) {
    refresh.value++;
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: _initialLocation,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);

      // The session has not been resolved yet; do not bounce the user around
      // while the stored session is being restored.
      if (!auth.isResolved) return null;

      final path = state.uri.path;
      final isAuthRoute = path == '/welcome' || path.startsWith('/auth');

      // A registration that still needs an email confirmation.
      if (auth.status == AuthStatus.awaitingEmailConfirmation) {
        if (path == '/auth/verify-email') return null;
        final email = auth.pendingEmail ?? '';
        return '/auth/verify-email?email=${Uri.encodeComponent(email)}';
      }

      // The user followed a password recovery link.
      if (auth.status == AuthStatus.passwordRecovery) {
        return path == '/auth/reset-password' ? null : '/auth/reset-password';
      }

      if (!auth.isAuthenticated) {
        return isAuthRoute ? null : '/welcome';
      }

      // The verification and recovery screens must stay reachable even though
      // a session may already exist.
      if (path == '/auth/verify-email' || path == '/auth/reset-password') {
        return null;
      }

      return isAuthRoute ? '/dashboard' : null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'login';
          return AuthScreen(initialMode: mode);
        },
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/verify-email',
        builder: (context, state) => VerifyEmailScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => const AuthCallbackScreen(),
      ),

      // Main Navigation Shell with 5 branches
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard (Home)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 1: Transactions (Activity)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),

          // Branch 2: Budgets
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/budgets',
                builder: (context, state) => const BudgetsScreen(),
              ),
            ],
          ),

          // Branch 3: Goals
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/goals',
                builder: (context, state) => const GoalsScreen(),
              ),
            ],
          ),

          // Branch 4: Profile / Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Modal / Subroute Flows
      GoRoute(
        path: '/transactions/create',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final type = state.uri.queryParameters['type'];
          return CreateEditTransactionScreen(initialType: type);
        },
      ),
      GoRoute(
        path: '/transactions/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return CreateEditTransactionScreen(transactionId: id);
        },
      ),
      GoRoute(
        path: '/transfers/create',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateTransferScreen(),
      ),
      GoRoute(
        path: '/accounts',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: '/recurring',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RecurringScreen(),
      ),
    ],
  );
});
