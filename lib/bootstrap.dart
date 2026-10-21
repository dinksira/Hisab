import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/bootstrap_error_app.dart';
import 'data/remote/supabase_client.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if credentials are provided in build config
  await SupabaseService.initialize();

  final initError = SupabaseService.initError;

  runApp(
    ProviderScope(
      child: initError == null
          ? const HisabApp()
          : BootstrapErrorApp(error: initError),
    ),
  );
}
