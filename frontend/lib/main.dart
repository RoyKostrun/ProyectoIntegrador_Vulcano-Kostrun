// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/account_type_selection_screen.dart';
import 'screens/register_personal_screen.dart';
import 'screens/register_empresarial_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChangApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter', // Puedes cambiar la fuente si quieres
      ),
      // Pantalla inicial: Login
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      
      // Rutas de navegación
      routes: {
        '/login': (context) => const LoginScreen(),
        '/account-type-selection': (context) => const AccountTypeSelectionScreen(),
        '/register-personal': (context) => const RegisterPersonalScreen(),
        '/register-empresarial': (context) => const RegisterEmpresarialScreen(),
      },
    );
  }
}