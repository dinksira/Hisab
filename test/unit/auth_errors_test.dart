import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/auth/data/auth_errors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthErrors.codeOf', () {
    test('reads the code from a Supabase AuthException', () {
      expect(
        AuthErrors.codeOf(const AuthException('bad', statusCode: '400', code: 'invalid_credentials')),
        'invalid_credentials',
      );
    });

    test('returns null when the exception carries no code', () {
      expect(AuthErrors.codeOf(const AuthException('bad', statusCode: '500')), isNull);
    });

    test('returns null for unknown error types', () {
      expect(AuthErrors.codeOf(Exception('boom')), isNull);
    });
  });

  group('AuthErrors.message', () {
    test('maps invalid credentials to a friendly message', () {
      final message =
          AuthErrors.message(const AuthException('bad', code: 'invalid_credentials'));
      expect(message, isNot(contains('invalid_credentials')));
      expect(message.toLowerCase(), contains('email'));
    });

    test('maps user already registered without revealing the account', () {
      final message =
          AuthErrors.message(const AuthException('bad', code: 'user_already_exists'));
      expect(message, isNot(contains('user_already_exists')));
      expect(message, isNotEmpty);
    });

    test('maps weak password to a hint about the requirements', () {
      final message = AuthErrors.message(const AuthException('bad', code: 'weak_password'));
      expect(message, contains('8'));
    });

    test('maps email not confirmed to a verification hint', () {
      final message =
          AuthErrors.message(const AuthException('bad', code: 'email_not_confirmed'));
      expect(message.toLowerCase(), contains('confirm'));
    });

    test('maps rate limit errors to a retry hint', () {
      final message =
          AuthErrors.message(const AuthException('bad', code: 'over_request_rate_limit'));
      expect(message.toLowerCase(), contains('wait'));
    });

    test('maps session errors to a sign in hint', () {
      final message =
          AuthErrors.message(const AuthException('bad', code: 'session_not_found'));
      expect(message.toLowerCase(), contains('sign in'));
    });

    test('falls back to a generic message for unknown codes', () {
      final message = AuthErrors.message(const AuthException('bad', code: 'some_new_code'));
      expect(message, isNotEmpty);
      expect(message, isNot(contains('some_new_code')));
      expect(message, isNot(contains('bad')));
    });

    test('falls back to a generic message for plain exceptions', () {
      final message = AuthErrors.message(Exception('network exploded'));
      expect(message, isNotEmpty);
      expect(message, isNot(contains('network exploded')));
    });
  });
}
