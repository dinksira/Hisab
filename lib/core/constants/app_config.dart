import 'package:flutter/foundation.dart';

/// Application configuration loaded from environment or --dart-define.
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Returns true if valid Supabase connection credentials have been provided.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const String appName = 'Hisab';
  static const String defaultCurrency = 'USD';
  static const String defaultLocale = 'en_US';

  // --- OAuth / deep link configuration ---

  /// Custom URL scheme registered by the Android and iOS builds.
  ///
  /// Must match the `android:scheme` intent filter and the `CFBundleURLSchemes`
  /// entry, and must be listed as a redirect URL in the Supabase dashboard.
  static const String appScheme = 'com.hisab.hisab';

  /// Host segment of the OAuth callback deep link.
  static const String authCallbackHost = 'login-callback';

  /// Optional explicit callback for the web build.
  ///
  /// The web bundle is usually served from a path that the backend does not
  /// know about, so the exact URL can be pinned at build time:
  /// `--dart-define=WEB_AUTH_CALLBACK=https://app.hisab.app/auth/callback`.
  static const String webAuthCallback = String.fromEnvironment(
    'WEB_AUTH_CALLBACK',
    defaultValue: '',
  );

  /// The `redirectTo` value handed to Supabase when starting an OAuth flow.
  ///
  /// * Native platforms use the custom scheme so the browser hands control
  ///   back to the app.
  /// * Web uses the current origin so the browser returns to the SPA.
  static String get authRedirectUrl {
    if (kIsWeb) {
      if (webAuthCallback.isNotEmpty) return webAuthCallback;
      return Uri.base.resolve('/auth/callback').toString();
    }
    return '$appScheme://$authCallbackHost';
  }
}
