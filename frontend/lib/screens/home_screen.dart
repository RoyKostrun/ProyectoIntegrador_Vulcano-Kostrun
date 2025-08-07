// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Botón de volver atrás
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Reemplaza la ruta actual por la de login
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
        title: const Text('Inicio'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          '¡Inicio de sesión exitoso! 🎉',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
