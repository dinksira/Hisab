import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the Supabase session in the platform keystore instead of the
/// default plaintext `shared_preferences` store.
///
/// * Android: AES-GCM encrypted values, key wrapped by the Android KeyStore.
/// * iOS/macOS: Keychain.
/// * Windows: DPAPI.
/// * Linux: libsecret.
/// * Web: WebCrypto encrypted `localStorage`.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage(this.persistSessionKey);

  /// Key under which the serialized session is stored.
  final String persistSessionKey;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      await _storage.read(key: persistSessionKey) != null;

  @override
  Future<String?> accessToken() => _storage.read(key: persistSessionKey);

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: persistSessionKey, value: persistSessionString);
}

/// Stores the PKCE code verifier in the platform keystore.
///
/// The default implementation writes it to `shared_preferences`, which would
/// leave the OAuth code verifier in plaintext on disk.
class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  const SecureGotrueAsyncStorage();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Prefix that keeps the PKCE entries separate from the session entry.
  static const String _keyPrefix = 'supabase-pkce-';

  @override
  Future<String?> getItem({required String key}) =>
      _storage.read(key: '$_keyPrefix$key');

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: '$_keyPrefix$key', value: value);

  @override
  Future<void> removeItem({required String key}) =>
      _storage.delete(key: '$_keyPrefix$key');
}
