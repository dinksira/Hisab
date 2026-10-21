import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hisab/data/repositories/repository_interfaces.dart';
import 'package:hisab/features/auth/data/auth_state.dart';
import 'package:hisab/features/auth/domain/user_profile.dart';
import 'package:hisab/features/auth/presentation/auth_screen.dart';
import 'package:hisab/shared/providers/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

/// Repository stub that records the calls made by the screen.
class StubAuthRepository implements IAuthRepository {
  final StreamController<AuthEvent> _events = StreamController<AuthEvent>.broadcast();

  Object? signInError;
  Object? signUpError;
  bool googleLaunches = true;
  int signInCalls = 0;
  int googleCalls = 0;

  @override
  Stream<AuthEvent> get authStateChanges => _events.stream;

  @override
  Future<UserProfile?> getCurrentUser() async => null;

  @override
  Future<UserProfile> signIn({required String email, required String password}) async {
    signInCalls++;
    if (signInError != null) throw signInError!;
    final now = DateTime(2026, 1, 1);
    return UserProfile(id: 'u1', email: email, createdAt: now, updatedAt: now);
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (signUpError != null) throw signUpError!;
    final now = DateTime(2026, 1, 1);
    return UserProfile(
      id: 'u1',
      displayName: displayName,
      email: email,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<bool> signInWithGoogle() async {
    googleCalls++;
    return googleLaunches;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword({required String email}) async {}

  @override
  Future<void> resendConfirmation({required String email}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async => profile;

  @override
  Future<List<AuthIdentity>> getIdentities() async => const [];

  @override
  Future<void> unlinkIdentity(String identityId) async {}

  Future<void> dispose() => _events.close();
}

Widget buildHarness(Widget child, StubAuthRepository repository) {
  final router = GoRouter(
    initialLocation: '/auth',
    routes: [
      GoRoute(path: '/auth', builder: (_, _) => child),
      GoRoute(path: '/welcome', builder: (_, _) => const Scaffold(body: Text('Welcome'))),
      GoRoute(path: '/auth/forgot-password', builder: (_, _) => const Scaffold(body: Text('Forgot'))),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late StubAuthRepository repository;

  setUp(() {
    repository = StubAuthRepository();
  });

  tearDown(() async {
    await repository.dispose();
  });

  testWidgets('renders the sign in form with a Google button', (tester) async {
    await tester.pumpWidget(
      buildHarness(const AuthScreen(initialMode: 'login'), repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('or'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('register mode asks for a name', (tester) async {
    await tester.pumpWidget(
      buildHarness(const AuthScreen(initialMode: 'register'), repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Your Name'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('rejects an invalid email address', (tester) async {
    await tester.pumpWidget(
      buildHarness(const AuthScreen(initialMode: 'login'), repository),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(repository.signInCalls, 0);
  });

  testWidgets('rejects a password shorter than eight characters', (tester) async {
    await tester.pumpWidget(
      buildHarness(const AuthScreen(initialMode: 'login'), repository),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(repository.signInCalls, 0);
  });

  testWidgets('shows a friendly message when the sign in fails', (tester) async {
    repository.signInError = const AuthException('bad', code: 'invalid_credentials');

    await tester.pumpWidget(
      buildHarness(const AuthScreen(initialMode: 'login'), repository),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
    expect(repository.signInCalls, 1);
  });

  testWidgets('the Google button triggers the OAuth flow', (tester) async {
    await tester.pumpWidget(
      buildHarness(const AuthScreen(initialMode: 'login'), repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();

    expect(repository.googleCalls, 1);
  });

  testWidgets('switching to register mode reveals the name field', (tester) async {
    await tester.pumpWidget(
      buildHarness(const AuthScreen(initialMode: 'login'), repository),
    );
    await tester.pumpAndSettle();

    final toggle = find.text("Don't have an account? Sign up");
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Your Name'), findsOneWidget);
  });
}
