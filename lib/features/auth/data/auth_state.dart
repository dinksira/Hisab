import '../domain/user_profile.dart';

/// Lifecycle of the authenticated session as surfaced to the UI.
enum AuthStatus {
  /// The session has not been resolved yet (cold start).
  unknown,

  /// No active session; the user must sign in or register.
  unauthenticated,

  /// A sign-in / sign-up / OAuth request is in flight.
  authenticating,

  /// Registration succeeded but the email still needs to be confirmed.
  awaitingEmailConfirmation,

  /// A valid session exists and [UserProfile] is loaded.
  authenticated,

  /// The user arrived through a password recovery link.
  passwordRecovery,
}

/// Immutable snapshot of everything the UI needs to know about authentication.
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.profile,
    this.pendingEmail,
    this.errorCode,
  });

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        profile = null,
        pendingEmail = null,
        errorCode = null;

  final AuthStatus status;

  /// The profile of the signed-in user; null whenever there is no session.
  final UserProfile? profile;

  /// The email awaiting confirmation after a registration.
  final String? pendingEmail;

  /// Machine readable error identifier (see `auth_errors.dart`).
  final String? errorCode;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isBusy => status == AuthStatus.authenticating;

  bool get isResolved => status != AuthStatus.unknown;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? profile,
    String? pendingEmail,
    String? errorCode,
    bool clearProfile = false,
    bool clearPendingEmail = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      pendingEmail: clearPendingEmail ? null : (pendingEmail ?? this.pendingEmail),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          other.status == status &&
          other.profile?.id == profile?.id &&
          other.pendingEmail == pendingEmail &&
          other.errorCode == errorCode;

  @override
  int get hashCode => Object.hash(status, profile?.id, pendingEmail, errorCode);
}

/// Raw authentication events emitted by the backend.
enum AuthEventType {
  initialSession,
  signedIn,
  signedOut,
  tokenRefreshed,
  userUpdated,
  passwordRecovery,
}

/// A single event from the backend auth stream.
class AuthEvent {
  const AuthEvent(this.type, {this.hasSession = false});

  final AuthEventType type;

  /// Whether the event carries an active session.
  final bool hasSession;
}

/// A login identity linked to the account (email address, Google, ...).
class AuthIdentity {
  const AuthIdentity({
    required this.id,
    required this.provider,
    this.email,
    this.displayName,
  });

  final String id;

  /// `email`, `google`, ...
  final String provider;

  final String? email;
  final String? displayName;

  bool get isEmail => provider == 'email';

  bool get isGoogle => provider == 'google';

  String get label => switch (provider) {
        'google' => 'Google',
        'email' => 'Email',
        _ => provider,
      };
}
