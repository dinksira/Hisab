import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_config.dart';
import 'secure_local_storage.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient? _client;
  static bool _initialized = false;
  static Object? _initError;

  static SupabaseClient? get client => _client;
  static bool get isInitialized => _initialized && _client != null;

  /// The error that prevented Supabase from starting, if any.
  ///
  /// When credentials were supplied but the client could not be created the
  /// app must surface this instead of silently falling back to demo data.
  static Object? get initError => _initError;

  static bool get hasInitError => _initError != null;

  static Future<void> initialize() async {
    if (!AppConfig.isSupabaseConfigured) {
      debugPrint('[SupabaseService] Supabase credentials not provided. Operating in local demo mode.');
      return;
    }

    try {
      final supabase = await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          persistSession: true,
          localStorage: SecureLocalStorage(_persistSessionKey),
          pkceAsyncStorage: const SecureGotrueAsyncStorage(),
        ),
      );
      _client = supabase.client;
      _initialized = true;
      debugPrint('[SupabaseService] Supabase successfully initialized.');
    } catch (e, st) {
      _initError = e;
      debugPrint('[SupabaseService] Failed to initialize Supabase: $e\n$st');
    }
  }

  /// Storage key for the persisted session.
  ///
  /// Mirrors the key Supabase uses by default so switching to secure storage
  /// keeps the same identifier.
  static String get _persistSessionKey {
    final host = Uri.parse(AppConfig.supabaseUrl).host.split('.').first;
    return 'sb-$host-auth-token';
  }
}
