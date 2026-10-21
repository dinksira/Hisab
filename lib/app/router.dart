import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/accounts/presentation/accounts_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/welcome',
    redirect: (context, state) {
      final user = ref.read(currentUserProfileProvider).valueOrNull;
      final isAuthRoute = state.uri.path == '/welcome' || state.uri.path == '/auth';

      // If user is already authenticated and lands on welcome/auth, direct to dashboard
      if (user != null && isAuthRoute) {
        return '/dashboard';
      }

      return null;
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
