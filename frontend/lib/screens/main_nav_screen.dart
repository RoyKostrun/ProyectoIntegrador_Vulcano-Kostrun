//lib/screens/main_nav_screen.dart
// ✅ ACTUALIZADO - Llama actualización de estados al iniciar

import 'package:flutter/material.dart';
import 'jobs/navegador_trabajos_screen.dart';
import 'jobs/create_trabajo_screen.dart';
import 'user/menu_perfil/user_menu_screen.dart';
import '../services/trabajo_service.dart'; // ✅ AGREGAR

class MainNavScreen extends StatefulWidget {
  final int initialTab;

  const MainNavScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _selectedIndex;
  final _trabajoService = TrabajoService(); // ✅ AGREGAR

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _actualizarEstados(); // ✅ AGREGAR
  }

  // ✅ NUEVO - Actualizar estados al iniciar
  Future<void> _actualizarEstados() async {
    try {
      await _trabajoService.actualizarEstadosTrabajos();
      print('✅ Estados actualizados en MainNavScreen');
    } catch (e) {
      print('⚠️ Error actualizando estados: $e');
      // No mostrar error al usuario, es background
    }
  }

  final List<Widget> _screens = const [
    NavegadorTrabajosScreen(), // 🔍 Tab 1
    CrearTrabajoScreen(), // ➕ Tab 2
    UserMenuScreen(), // 👤 Tab 3
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    // ✅ NUEVO - Actualizar estados cuando vuelven a tab de trabajos
    if (index == 0) {
      _actualizarEstados();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFC5414B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Trabajos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Crear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
