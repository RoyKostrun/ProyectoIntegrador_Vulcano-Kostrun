import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:changapp_client/services/trabajo_service.dart';
import 'package:changapp_client/services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Ejecuta con:
// flutter test --dart-define=RUN_SUPABASE_TESTS=true \
//   --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... \
//   --dart-define=SUPABASE_EMAIL=... --dart-define=SUPABASE_PASSWORD=...

const bool runIntegration = bool.fromEnvironment(
  'RUN_SUPABASE_TESTS',
  defaultValue: false,
);
const String testEmail = String.fromEnvironment('SUPABASE_EMAIL', defaultValue: '');
const String testPassword = String.fromEnvironment('SUPABASE_PASSWORD', defaultValue: '');

void main() {
  if (!runIntegration) {
    group('TrabajoService (integration)', () {
      test('skipped sin credenciales', () {
        expect(true, isTrue, reason: 'Set RUN_SUPABASE_TESTS=true para ejecutar');
      }, skip: 'RUN_SUPABASE_TESTS=false');
    });
    return;
  }

  group('TrabajoService (integration)', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await SupabaseConfig.initialize();
      if (testEmail.isNotEmpty && testPassword.isNotEmpty) {
        try {
          await Supabase.instance.client.auth.signInWithPassword(
            email: testEmail,
            password: testPassword,
          );
        } catch (_) {}
      }
    });

    test('getTrabajos no lanza y retorna lista', () async {
      final authed = Supabase.instance.client.auth.currentUser != null;
      if (!authed) return; // requiere sesión
      final service = TrabajoService();
      final trabajos = await service.getTrabajos(from: 0, to: 0);
      expect(trabajos, isA<List>());
    });

    test('getMisTrabajos no lanza y retorna lista', () async {
      final authed = Supabase.instance.client.auth.currentUser != null;
      if (!authed) return; // requiere sesión
      final service = TrabajoService();
      final trabajos = await service.getMisTrabajos(from: 0, to: 0);
      expect(trabajos, isA<List>());
    });
  });
}
