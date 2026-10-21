import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app/router.dart';
import 'package:hisab/data/repositories/repository_interfaces.dart';
import 'package:hisab/features/auth/data/auth_state.dart';
import 'package:hisab/features/auth/domain/user_profile.dart';
import 'package:hisab/shared/providers/providers.dart';

/// Repository stub whose session state is controlled by the test.
class RouterAuthRepository implements IAuthRepository {
  final StreamController<AuthEvent> _events = StreamController<AuthEvent>.broadcast();

  UserProfile? currentUser;

  @override
  Stream<AuthEvent> get authStateChanges => _events.stream;

  @override
  Future<UserProfile?> getCurrentUser() async => currentUser;

  @override
  Future<UserProfile> signIn({required String email, required String password}) async =>
      currentUser!;

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async =>
      currentUser!;

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<void> signOut() async => currentUser = null;

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

void main() {
  late RouterAuthRepository repository;

  setUp(() {
    repository = RouterAuthRepository();
  });

  tearDown(() async {
    await repository.dispose();
  });

  Future<String> pumpApp(
    WidgetTester tester,
    String location,
  ) async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    router.go(location);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    return router.routerDelegate.currentConfiguration.uri.path;
  }

  testWidgets('an anonymous visitor is sent to the welcome screen', (tester) async {
    final path = await pumpApp(tester, '/dashboard');

    expect(path, '/welcome');
  });

  testWidgets('the welcome screen stays reachable while signed out', (tester) async {
    final path = await pumpApp(tester, '/welcome');

    expect(path, '/welcome');
  });

  testWidgets('a signed in user is sent to the dashboard', (tester) async {
    final now = DateTime(2026, 1, 1);
    repository.currentUser = UserProfile(id: 'u1', createdAt: now, updatedAt: now);

    final path = await pumpApp(tester, '/welcome');

    expect(path, '/dashboard');
  });

  testWidgets('a signed in user keeps access to the dashboard', (tester) async {
    final now = DateTime(2026, 1, 1);
    repository.currentUser = UserProfile(id: 'u1', createdAt: now, updatedAt: now);

    final path = await pumpApp(tester, '/dashboard');

    expect(path, '/dashboard');
  });
}
