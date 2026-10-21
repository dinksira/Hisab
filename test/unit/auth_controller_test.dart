import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/repositories/repository_interfaces.dart';
import 'package:hisab/features/auth/data/auth_controller.dart';
import 'package:hisab/features/auth/data/auth_state.dart';
import 'package:hisab/features/auth/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

/// In memory [IAuthRepository] used to drive the controller in isolation.
class FakeAuthRepository implements IAuthRepository {
  final StreamController<AuthEvent> _events = StreamController<AuthEvent>.broadcast();

  UserProfile? currentUser;
  bool confirmEmailOnSignUp = false;
  bool googleLaunches = true;
  Object? signInError;
  Object? signUpError;

  final List<String> unlinked = [];
  final List<String> sentResetEmails = [];
  final List<String> sentConfirmations = [];
  final List<String> updatedPasswords = [];

  static UserProfile profile({
    required String id,
    String? displayName,
    String? email,
  }) {
    final now = DateTime(2026, 1, 1);
    return UserProfile(
      id: id,
      displayName: displayName,
      email: email,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Stream<AuthEvent> get authStateChanges => _events.stream;

  @override
  Future<UserProfile?> getCurrentUser() async => currentUser;

  @override
  Future<UserProfile> signIn({required String email, required String password}) async {
    if (signInError != null) throw signInError!;
    currentUser = profile(id: 'user-1', displayName: 'Test User', email: email);
    _events.add(const AuthEvent(AuthEventType.signedIn, hasSession: true));
    return currentUser!;
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (signUpError != null) throw signUpError!;
    if (confirmEmailOnSignUp) {
      currentUser = null;
      return profile(id: 'user-1', displayName: displayName ?? 'Test User', email: email);
    }
    currentUser = profile(id: 'user-1', displayName: displayName ?? 'Test User', email: email);
    _events.add(const AuthEvent(AuthEventType.signedIn, hasSession: true));
    return currentUser!;
  }

  @override
  Future<bool> signInWithGoogle() async {
    if (!googleLaunches) return false;
    currentUser = profile(id: 'google-user', displayName: 'Google User');
    _events.add(const AuthEvent(AuthEventType.signedIn, hasSession: true));
    return true;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
    _events.add(const AuthEvent(AuthEventType.signedOut, hasSession: false));
  }

  @override
  Future<void> resetPassword({required String email}) async {
    sentResetEmails.add(email);
  }

  @override
  Future<void> resendConfirmation({required String email}) async {
    sentConfirmations.add(email);
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    updatedPasswords.add(newPassword);
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    currentUser = profile;
    return profile;
  }

  @override
  Future<List<AuthIdentity>> getIdentities() async => const [
        AuthIdentity(
          id: 'identity-1',
          provider: 'email',
          email: 'test@example.com',
        ),
      ];

  @override
  Future<void> unlinkIdentity(String identityId) async {
    unlinked.add(identityId);
  }

  /// Pushes a backend event into the auth stream.
  void emit(AuthEvent event) => _events.add(event);

  Future<void> dispose() => _events.close();
}

void main() {
  late FakeAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = AuthController(repository);
  });

  tearDown(() async {
    await controller.dispose();
    await repository.dispose();
  });

  group('bootstrap', () {
    test('resolves to unauthenticated when no session exists', () async {
      final state = await controller.bootstrap();

      expect(state.status, AuthStatus.unauthenticated);
      expect(state.isResolved, isTrue);
      expect(state.isAuthenticated, isFalse);
    });

    test('resolves to authenticated when a session exists', () async {
      repository.currentUser = FakeAuthRepository.profile(id: 'user-1', displayName: 'Test User');

      final state = await controller.bootstrap();

      expect(state.status, AuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
      expect(state.profile?.displayName, 'Test User');
    });

    test('only bootstraps once', () async {
      await controller.bootstrap();
      repository.currentUser = FakeAuthRepository.profile(id: 'user-1');

      final state = await controller.bootstrap();

      expect(state.status, AuthStatus.unauthenticated);
    });
  });

  group('signIn', () {
    test('emits the authenticated state', () async {
      final states = <AuthState>[];
      final subscription = controller.stream.listen(states.add);

      await controller.signIn(email: 'test@example.com', password: 'secret123');
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.status, AuthStatus.authenticated);
      expect(controller.state.profile?.email, 'test@example.com');
      expect(states.any((s) => s.status == AuthStatus.authenticating), isTrue);

      await subscription.cancel();
    });

    test('reports the failure and keeps the user signed out', () async {
      repository.signInError = const AuthException('bad', code: 'invalid_credentials');

      await expectLater(
        controller.signIn(email: 'test@example.com', password: 'wrong'),
        throwsA(isA<AuthException>()),
      );

      expect(controller.state.status, AuthStatus.unauthenticated);
      expect(controller.state.errorCode, 'invalid_credentials');
    });
  });

  group('signUp', () {
    test('becomes authenticated when the backend signs the user in', () async {
      await controller.signUp(email: 'new@example.com', password: 'secret123');

      expect(controller.state.status, AuthStatus.authenticated);
    });

    test('waits for the email confirmation when required', () async {
      repository.confirmEmailOnSignUp = true;

      await controller.signUp(email: 'new@example.com', password: 'secret123');

      expect(controller.state.status, AuthStatus.awaitingEmailConfirmation);
      expect(controller.state.pendingEmail, 'new@example.com');
      expect(controller.state.isAuthenticated, isFalse);
    });

    test('reports a failed registration', () async {
      repository.signUpError = const AuthException('bad', code: 'user_already_exists');

      await expectLater(
        controller.signUp(email: 'new@example.com', password: 'secret123'),
        throwsA(isA<AuthException>()),
      );

      expect(controller.state.errorCode, 'user_already_exists');
    });
  });

  group('signInWithGoogle', () {
    test('signs in when the browser flow succeeds', () async {
      await controller.bootstrap();

      await controller.signInWithGoogle();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.state.status, AuthStatus.authenticated);
    });

    test('throws when the browser could not be opened', () async {
      repository.googleLaunches = false;

      await expectLater(controller.signInWithGoogle(), throwsA(isA<Exception>()));
      expect(controller.state.status, AuthStatus.unauthenticated);
    });
  });

  group('signOut', () {
    test('clears the session', () async {
      await controller.signIn(email: 'test@example.com', password: 'secret123');
      await controller.signOut();

      expect(controller.state.status, AuthStatus.unauthenticated);
      expect(controller.state.profile, isNull);
    });
  });

  group('password recovery', () {
    test('requests a reset email', () async {
      await controller.resetPassword(email: 'test@example.com');

      expect(repository.sentResetEmails, ['test@example.com']);
      expect(controller.state.status, AuthStatus.unauthenticated);
    });

    test('updates the password of the recovering user', () async {
      await controller.updatePassword(newPassword: 'brandnew123');

      expect(repository.updatedPasswords, ['brandnew123']);
      expect(controller.state.status, AuthStatus.unauthenticated);
    });

    test('re-sends the confirmation email', () async {
      await controller.resendConfirmation(email: 'test@example.com');

      expect(repository.sentConfirmations, ['test@example.com']);
    });
  });

  group('linked identities', () {
    test('lists the linked identities', () async {
      final identities = await controller.getIdentities();

      expect(identities, isNotEmpty);
      expect(identities.first.isEmail, isTrue);
    });

    test('removes a linked identity', () async {
      await controller.unlinkIdentity('identity-1');

      expect(repository.unlinked, ['identity-1']);
    });
  });

  group('events', () {
    test('a password recovery event switches the state', () async {
      await controller.bootstrap();

      repository.emit(const AuthEvent(AuthEventType.passwordRecovery, hasSession: true));
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.status, AuthStatus.passwordRecovery);
    });
  });
}
