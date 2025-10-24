//lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/supabase_client.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/account_type_selection_screen.dart';
import 'screens/login/register_personal_screen.dart';
import 'screens/login/register_empresarial_screen.dart';
import 'screens/login/rubros_bubbles_screen.dart'; 
import 'screens/login/role_selection_screen.dart';
import 'screens/user/user_menu_screen.dart';
import 'screens/login/forgot_password_screen.dart'; // ✅ NUEVO
import 'screens/user/trabajos_screen.dart';
import 'screens/user/perfil_screen.dart';
import 'screens/user/ubicaciones_screen.dart';
import 'screens/main_nav_screen.dart';
import 'screens/jobs/postulaciones_trabajo_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar Supabase con la clase que definiste
  await SupabaseConfig.initialize();
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
      // Delegates de localización para Material, Widgets y Cupertino
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''), // Español
        Locale('en', ''), // Inglés
      ],
      // Rutas
      initialRoute: '/login',
      routes: {
        '/login':                     (context) => const LoginScreen(),
        '/forgot-password':           (context) => const ForgotPasswordScreen(), // ✅ NUEVO
        '/account-type-selection':    (context) => const AccountTypeSelectionScreen(),
        '/register-personal':         (context) => const RegisterPersonalScreen(),
        '/register-empresarial':      (context) => const RegisterEmpresarialScreen(),
        '/rubros-bubbles':            (context) => const RubrosBubblesScreen(), 
        '/user_menu':                    (context) => const UserMenuScreen(),
        '/role-selection':            (context) => const RoleSelectionScreen(),
        '/trabajos':                  (context) => TrabajosScreen(),
        '/ubicaciones':               (context) => UbicacionesScreen(),
        '/perfil':                    (context) => const PerfilScreen(),
        '/main-nav': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final initialTab = args?['initialTab'] as int? ?? 0;
          return MainNavScreen(initialTab: initialTab);
          },
        '/postulaciones-trabajo': (context) {
          final trabajoId = ModalRoute.of(context)?.settings.arguments as int;
          return PostulacionesTrabajoScreen(trabajoId: trabajoId);
          },
      },
    );
  }
}

