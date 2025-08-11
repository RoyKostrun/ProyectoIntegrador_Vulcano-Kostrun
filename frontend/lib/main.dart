//lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/supabase_client.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/account_type_selection_screen.dart';
import 'screens/register_personal_screen.dart';
import 'screens/register_empresarial_screen.dart';
import 'screens/rubros_bubbles_screen.dart'; 
import 'screens/role_selection_screen.dart';
import 'screens/inicio_screen.dart';

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
        '/login':                    (context) => const LoginScreen(),
        '/home':                     (context) => const HomeScreen(),
        '/account-type-selection':   (context) => const AccountTypeSelectionScreen(),
        '/register-personal':        (context) => const RegisterPersonalScreen(),
        '/register-empresarial':     (context) => const RegisterEmpresarialScreen(),
        '/rubros-bubbles':           (context) => const RubrosBubblesScreen(), 
        '/inicio':                   (context) => const InicioScreen(),
        '/role-selection':           (context) => const RoleSelectionScreen(),
      },
    );
  }
}
