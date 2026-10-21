import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_config.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient? _client;
  static bool _initialized = false;

  static SupabaseClient? get client => _client;
  static bool get isInitialized => _initialized && _client != null;

  static Future<void> initialize() async {
    if (!AppConfig.isSupabaseConfigured) {
      debugPrint('[SupabaseService] Supabase credentials not provided. Operating in local demo mode.');
      return;
    }

    try {
      final supabase = await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _client = supabase.client;
      _initialized = true;
      debugPrint('[SupabaseService] Supabase successfully initialized.');
    } catch (e, st) {
      debugPrint('[SupabaseService] Failed to initialize Supabase: $e\n$st');
    }
  }
}
