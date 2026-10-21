import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/repositories/mock_repositories.dart';
import 'package:hisab/features/auth/data/auth_state.dart';

void main() {
  group('MockAuthRepository', () {
    test('starts signed out', () async {
      final repository = MockAuthRepository();

      expect(await repository.getCurrentUser(), isNull);
    });

    test('sign in produces a session event', () async {
      final repository = MockAuthRepository();

      final events = <AuthEvent>[];
      final subscription = repository.authStateChanges.listen(events.add);

      final profile = await repository.signIn(
        email: 'demo@hisab.app',
        password: 'demo1234',
      );

      await Future<void>.delayed(Duration.zero);

      expect(profile.id, isNotEmpty);
      expect(await repository.getCurrentUser(), isNotNull);
      expect(events.any((e) => e.type == AuthEventType.signedIn), isTrue);

      await subscription.cancel();
    });

    test('sign out clears the session', () async {
      final repository = MockAuthRepository();
      await repository.signIn(email: 'demo@hisab.app', password: 'demo1234');

      await repository.signOut();

      expect(await repository.getCurrentUser(), isNull);
    });

    test('the Google flow signs the user in', () async {
      final repository = MockAuthRepository();

      await repository.signInWithGoogle();

      expect(await repository.getCurrentUser(), isNotNull);
    });

    test('sign up creates a profile', () async {
      final repository = MockAuthRepository();

      final profile = await repository.signUp(
        email: 'new@hisab.app',
        password: 'secret123',
        displayName: 'New User',
      );

      expect(profile.displayName, 'New User');
      expect(await repository.getCurrentUser(), isNotNull);
    });

    test('reports the linked identities of the signed in user', () async {
      final repository = MockAuthRepository();
      await repository.signIn(email: 'demo@hisab.app', password: 'demo1234');

      final identities = await repository.getIdentities();

      expect(identities, isNotEmpty);
      expect(identities.first.isEmail, isTrue);
    });
  });
}
