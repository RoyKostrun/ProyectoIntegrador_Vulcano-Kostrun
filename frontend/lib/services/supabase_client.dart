// lib/services/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Permite inyectar claves en tiempo de build con --dart-define.
  // Si no se proveen, usa estos valores por defecto (útiles en dev local).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zxegukhnqpdjqosmcgwi.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp4ZWd1a2hucXBkanFvc21jZ3dpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM5NzY1MTMsImV4cCI6MjA2OTU1MjUxM30.APodvvXfDubEIY9ILlPXw3BPqLCfPZ2xXatXKMbmQPg',
  );
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );
  }
}

final supabase = SupabaseConfig.client;
