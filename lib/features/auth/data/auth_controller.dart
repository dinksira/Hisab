import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../data/repositories/repository_interfaces.dart';
import '../domain/user_profile.dart';
import 'auth_errors.dart';
import 'auth_state.dart';

/// Owns the authentication lifecycle of the application.
///
/// The controller is the single source of truth for [AuthState]. It listens
/// to the backend auth stream exactly once and turns those events into
/// states the UI can render, while the explicit actions (`signIn`,
/// `signUp`, ...) drive the state machine directly.
class AuthController {
  AuthController(this._repository);

  final IAuthRepository _repository;

  final StreamController<AuthState> _stateController =
      StreamController<AuthState>.broadcast();

  StreamSubscription<AuthEvent>? _eventSubscription;
  AuthState _state = const AuthState.unknown();
  bool _bootstrapped = false;

  /// The current authentication state.
  AuthState get state => _state;

  /// Stream of authentication state changes.
  Stream<AuthState> get stream => _stateController.stream;

  /// Resolves the session that is already stored on the device and starts
  /// listening for backend events.
  ///
  /// Safe to call multiple times; only the first call does the work.
  Future<AuthState> bootstrap() async {
    if (_bootstrapped) return _state;
    _bootstrapped = true;

    _eventSubscription = _repository.authStateChanges.listen(_onEvent);

    final profile = await _repository.getCurrentUser();
    if (profile != null) {
      _emit(AuthState(status: AuthStatus.authenticated, profile: profile));
    } else if (_state.status == AuthStatus.unknown) {
      _emit(const AuthState(status: AuthStatus.unauthenticated));
    }
    return _state;
  }

  Future<void> _onEvent(AuthEvent event) async {
    switch (event.type) {
      case AuthEventType.signedIn:
        final profile = await _repository.getCurrentUser();
        _emit(AuthState(status: AuthStatus.authenticated, profile: profile));
      case AuthEventType.userUpdated:
        final profile = await _repository.getCurrentUser();
        if (profile != null) _emit(_state.copyWith(profile: profile));
      case AuthEventType.signedOut:
        _emit(const AuthState(status: AuthStatus.unauthenticated));
      case AuthEventType.passwordRecovery:
        _emit(_state.copyWith(status: AuthStatus.passwordRecovery));
      case AuthEventType.initialSession:
      case AuthEventType.tokenRefreshed:
        break;
    }
  }

  /// Signs in with an email address and password.
  Future<void> signIn({required String email, required String password}) async {
    _beginAttempt();
    try {
      final profile =
          await _repository.signIn(email: email, password: password);
      _emit(AuthState(status: AuthStatus.authenticated, profile: profile));
    } catch (error) {
      _fail(error);
      rethrow;
    }
  }

  /// Registers a new account.
  ///
  /// When the backend requires email confirmation there is no session yet;
  /// the state becomes [AuthStatus.awaitingEmailConfirmation] and the user is
  /// asked to open the link that was mailed to them.
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _beginAttempt();
    try {
      await _repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      final profile = await _repository.getCurrentUser();
      if (profile == null) {
        _emit(AuthState(
          status: AuthStatus.awaitingEmailConfirmation,
          pendingEmail: email,
        ));
      } else {
        _emit(AuthState(status: AuthStatus.authenticated, profile: profile));
      }
    } catch (error) {
      _fail(error);
      rethrow;
    }
  }

  /// Starts the Google OAuth flow.
  ///
  /// The browser is opened by the backend client; the sign-in completes
  /// asynchronously through [stream].
  Future<void> signInWithGoogle() async {
    _beginAttempt();
    try {
      final launched = await _repository.signInWithGoogle();
      if (!launched) {
        throw const AuthException(
          'The browser could not be opened.',
          code: 'browser_launch_failed',
        );
      }
    } catch (error) {
      _fail(error);
      rethrow;
    }
  }

  /// Ends the session and clears every cached value of the signed-out user.
  Future<void> signOut() async {
    await _repository.signOut();
    _emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  /// Mails a password reset link.
  Future<void> resetPassword({required String email}) async {
    _beginAttempt();
    try {
      await _repository.resetPassword(email: email);
      _emit(const AuthState(status: AuthStatus.unauthenticated));
    } catch (error) {
      _fail(error);
      rethrow;
    }
  }

  /// Re-sends the email confirmation link.
  Future<void> resendConfirmation({required String email}) async {
    try {
      await _repository.resendConfirmation(email: email);
    } catch (error) {
      _fail(error);
      rethrow;
    }
  }

  /// Sets a new password for the user that followed a recovery link.
  Future<void> updatePassword({required String newPassword}) async {
    _beginAttempt();
    try {
      await _repository.updatePassword(newPassword: newPassword);
      _emit(const AuthState(status: AuthStatus.unauthenticated));
    } catch (error) {
      _fail(error);
      rethrow;
    }
  }

  /// Persists profile changes and mirrors them into the auth state.
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final updated = await _repository.updateProfile(profile);
    _emit(_state.copyWith(profile: updated));
    return updated;
  }

  /// Identities linked to the current account.
  Future<List<AuthIdentity>> getIdentities() => _repository.getIdentities();

  /// Removes a linked identity from the account.
  Future<void> unlinkIdentity(String identityId) =>
      _repository.unlinkIdentity(identityId);

  void _beginAttempt() {
    _emit(_state.copyWith(
      status: AuthStatus.authenticating,
      clearError: true,
    ));
  }

  void _fail(Object error) {
    final code = AuthErrors.codeOf(error);
    final stillSignedIn = _state.status == AuthStatus.authenticated;
    _emit(AuthState(
      status:
          stillSignedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      profile: stillSignedIn ? _state.profile : null,
      pendingEmail: _state.pendingEmail,
      errorCode: code,
    ));
  }

  void _emit(AuthState next) {
    if (next == _state) return;
    _state = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await _stateController.close();
  }
}
