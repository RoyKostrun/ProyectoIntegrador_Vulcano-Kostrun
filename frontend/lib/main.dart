//lib/main.dart
// ✅ ACTUALIZADO - Llama actualización de estados al iniciar app

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/supabase_client.dart';
import 'services/trabajo_service.dart'; // ✅ AGREGAR
import 'screens/login/login_screen.dart';
import 'screens/login/account_type_selection_screen.dart';
import 'screens/login/register_personal_screen.dart';
import 'screens/login/register_empresarial_screen.dart';
import 'screens/login/rubros_bubbles_screen.dart';
import 'screens/login/role_selection_screen.dart';
import 'screens/user/user_menu_screen.dart';
import 'screens/login/forgot_password_screen.dart';
import 'screens/user/trabajos_screen.dart';
import 'screens/user/perfil_privado_screen.dart';
import 'screens/user/perfil_publico_screen.dart';
import 'screens/user/ubicaciones_screen.dart';
import 'screens/main_nav_screen.dart';
import 'screens/jobs/postulaciones_trabajo_screen.dart';
import 'screens/jobs/create_trabajo_screen.dart';
import 'screens/user/unirse_empleadores_screen.dart';
import 'package:changapp_client/screens/user/unirse_empleados_screen.dart';
import 'screens/user/crear_ubicaciones_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await SupabaseConfig.initialize();

  // ✅ NUEVO - Actualizar estados de trabajos al iniciar app
  try {
    final trabajoService = TrabajoService();
    await trabajoService.actualizarEstadosTrabajos();
    print('✅ Estados de trabajos actualizados al iniciar app');
  } catch (e) {
    print('⚠️ Error actualizando estados al iniciar: $e');
    // No detener la app si falla
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChangApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''),
        Locale('en', ''),
      ],
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/account-type-selection': (context) =>
            const AccountTypeSelectionScreen(),
        '/register-personal': (context) => const RegisterPersonalScreen(),
        '/register-empresarial': (context) => const RegisterEmpresarialScreen(),
        '/rubros-bubbles': (context) => const RubrosBubblesScreen(),
        '/user_menu': (context) => const UserMenuScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/trabajos': (context) => TrabajosScreen(),
        '/ubicaciones': (context) => UbicacionesScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/main-nav': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final initialTab = args?['initialTab'] as int? ?? 0;
          return MainNavScreen(initialTab: initialTab);
        },
        '/postulaciones-trabajo': (context) {
          final trabajoId = ModalRoute.of(context)?.settings.arguments as int;
          return PostulacionesTrabajoScreen(trabajoId: trabajoId);
        },
        '/crear-trabajo': (context) => const CrearTrabajoScreen(),
        '/unirse-empleadores': (context) => const UnirseEmpleadoresScreen(),
        '/unirse-empleados': (context) => const UnirseEmpleadosScreen(),
        '/perfil-compartido': (context) {
          final userId = ModalRoute.of(context)?.settings.arguments as int;
          return PerfilCompartidoScreen(userId: userId);
        },
        '/crear-ubicacion': (context) => const CrearUbicacionScreen(),
      },
    );
  }
}
