//lib/screens/main_nav_screen.dart

import 'package:flutter/material.dart';
import 'jobs/navegador_trabajos_screen.dart';
import 'jobs/create_trabajo_screen.dart';
import 'menu_perfil/user_menu_screen.dart';
import 'menu_perfil/chat/conversaciones_screen.dart';
import 'menu_perfil/notificaciones/notificaciones_screen.dart';
import '../services/menu_perfil/trabajo_service.dart';
import '../services/notificacion/notificacion_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../utils/calificacion_middleware.dart';

class MainNavScreen extends StatefulWidget {
  final int initialTab;

  const MainNavScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _selectedIndex;
  bool _verificandoCalificaciones = true; // ✅ AGREGADO
  final _trabajoService = TrabajoService();
  final _notificacionService = NotificacionService();
  final _chatService = ChatService();
  int? _currentUserId;

  // ✅ Lista de pantallas (MOVIDO AQUÍ)
  final List<Widget> _screens = const [
    NavegadorTrabajosScreen(),     // 0 - 🔍 Trabajos
    CrearTrabajoScreen(),           // 1 - ➕ Crear
    ConversacionesScreen(),         // 2 - 💬 Chat
    NotificacionesScreen(),         // 3 - 🔔 Notificaciones
    UserMenuScreen(),               // 4 - 👤 Perfil
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _verificarCalificacionesPendientes(); // ✅ PRIMERO verificar calificaciones
    _loadUserId();
    _actualizarEstados();
  }

  Future<void> _loadUserId() async {
    try {
      final userData = await AuthService.getCurrentUserData();
      setState(() {
        _currentUserId = userData?.idUsuario;
      });
    } catch (e) {
      print('Error cargando ID usuario: $e');
    }
  }

  // ✅ Verificar calificaciones pendientes al iniciar
  Future<void> _verificarCalificacionesPendientes() async {
    // Esperar un poco para que la pantalla se construya
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      setState(() => _verificandoCalificaciones = true);
      
      final bloqueado = await CalificacionMiddleware.verificarYBloquear(context);
      
      if (mounted) {
        setState(() => _verificandoCalificaciones = false);
      }
    }
  }

  // ✅ Actualizar estados de trabajos
  Future<void> _actualizarEstados() async {
    try {
      await _trabajoService.actualizarEstadosTrabajos();
      print('✅ Estados actualizados en MainNavScreen');
    } catch (e) {
      print('⚠️ Error actualizando estados: $e');
    }
  }

  // ✅ Cambiar de tab con verificación
  void _onItemTapped(int index) async {
    // ✅ NUEVO: Verificar calificaciones pendientes antes de cambiar de pestaña
    final bloqueado = await CalificacionMiddleware.verificarYBloquear(context);
    
    if (!bloqueado) {
      setState(() => _selectedIndex = index);

      // Actualizar estados cuando vuelven a tab de trabajos
      if (index == 0) {
        _actualizarEstados();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ MOSTRAR LOADING MIENTRAS VERIFICA
    if (_verificandoCalificaciones) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
              ),
              SizedBox(height: 16),
              Text(
                'Verificando cuenta...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ PANTALLA NORMAL
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFC5414B),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Trabajos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Crear',
          ),
          // ========== CHAT CON BADGE ==========
          BottomNavigationBarItem(
            icon: _currentUserId == null
                ? const Icon(Icons.chat_bubble_outline)
                : StreamBuilder<int>(
                    stream: _chatService.streamContadorConversacionesNoLeidas(_currentUserId!),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.chat_bubble_outline),
                          if (count > 0)
                            Positioned(
                              right: -6,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC5414B),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  count > 99 ? '99+' : count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
            label: 'Chat',
          ),
          // ========== NOTIFICACIONES CON BADGE ==========
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: _notificacionService.streamContadorNoLeidas(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (count > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFC5414B),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Notificaciones',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}