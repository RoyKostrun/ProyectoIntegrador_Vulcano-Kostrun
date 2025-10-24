//lib/screens/main_nav_screen.dart

import 'package:flutter/material.dart';
import 'jobs/navegador_trabajos_screen.dart';
import 'jobs/create_trabajo_screen.dart';
import 'user/user_menu_screen.dart';

class MainNavScreen extends StatefulWidget {
  final int initialTab; // ✅ AGREGADO
  
  const MainNavScreen({Key? key, this.initialTab = 0}) : super(key: key); // ✅ AGREGADO

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _selectedIndex; // ✅ CAMBIADO de int a late int

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab; // ✅ AGREGADO
  }

  final List<Widget> _screens = const [
    NavegadorTrabajosScreen(), // 🔍 Tab 1
    CrearTrabajoScreen(),      // ➕ Tab 2
    UserMenuScreen(),            // 👤 Tab 3
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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