import 'package:supabase_flutter/supabase_flutter.dart';

/// Human readable messages for every authentication failure the backend can
/// produce. Codes mirror `gotrue`'s `ErrorCode` enum.
class AuthErrors {
  AuthErrors._();

  static const String _generic = 'Something went wrong. Please try again.';

  /// Maps a raw backend error onto a message that is safe to show to a user.
  ///
  /// Never distinguishes "unknown email" from "wrong password" so that the
  /// screen cannot be used to enumerate registered accounts.
  static String message(Object error) {
    final code = codeOf(error);
    if (code != null) {
      return _mapCode(code) ?? _generic;
    }
    return _fallback(error);
  }

  /// Extracts the machine readable error code from a backend exception.
  static String? codeOf(Object error) {
    if (error is AuthException) {
      final code = error.code;
      if (code != null && code.isNotEmpty) return code;
    }
    // Fall back to duck typing so the mapping keeps working for the generic
    // `Exception` wrappers thrown by the repository layer.
    if (error is Exception) {
      final text = error.toString();
      final match = RegExp(r'code:\s*(?!null\b)([a-z_]+)').firstMatch(text);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String? _mapCode(String code) {
    switch (code) {
      case 'invalid_credentials':
        return 'Incorrect email or password.';
      case 'email_exists':
      case 'user_already_exists':
        return 'An account with this email already exists. Try signing in.';
      case 'email_not_confirmed':
        return 'Please confirm your email first. Check your inbox.';
      case 'weak_password':
        return 'Please choose a stronger password (at least 8 characters).';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Too many attempts. Please wait a minute and try again.';
      case 'flow_state_expired':
      case 'flow_state_not_found':
        return 'That sign-in link has expired. Please try again.';
      case 'bad_oauth_state':
      case 'bad_oauth_callback':
        return "We couldn't complete the Google sign-in. Please try again.";
      case 'oauth_provider_not_supported':
      case 'provider_disabled':
        return 'Google sign-in is currently unavailable.';
      case 'browser_launch_failed':
        return 'Could not open the browser for Google sign-in.';
      case 'user_banned':
        return 'This account has been suspended.';
      case 'validation_failed':
        return 'Please check the details you entered.';
      case 'identity_already_exists':
        return 'That account is already linked to another user.';
      case 'email_conflict_identity_not_deletable':
      case 'single_identity_not_deletable':
        return 'You cannot remove your only sign-in method.';
      case 'session_not_found':
      case 'session_expired':
      case 'session_missing':
        return 'Your session has expired. Please sign in again.';
      case 'network_request_failed':
      case 'request_timeout':
        return 'Network error. Check your connection and try again.';
      default:
        return null;
    }
  }

  static String _fallback(Object error) {
    if (error is AuthException) {
      final message = error.message.trim();
      if (message.isNotEmpty && !message.toLowerCase().contains('error')) {
        return message;
      }
    }
    return _generic;
  }
}
