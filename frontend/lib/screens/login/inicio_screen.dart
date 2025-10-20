// lib/screens/login/inicio_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart' as AppUser;
import '../../components/app_logo.dart';
import '../../components/primary_button.dart';
import '../user/trabajos_screen.dart';
import '../user/ubicaciones_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({Key? key}) : super(key: key);

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  AppUser.User? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getCurrentUserData();
      setState(() {
        currentUser = userData;
        isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos del usuario: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToScreen(String screenName) {
    switch (screenName) {
      case 'Mi Perfil':
        _showUserProfile();
        break;
      case 'Mis Rubros':
        _showComingSoon('Gestión de Rubros');
        break;
      case 'Mis Ubicaciones':
        Navigator.pushNamed(context, '/ubicaciones');
        break;
      case 'Mis Trabajos':
        Navigator.pushNamed(context, '/trabajos');
        break;
      case 'Chat':
        _showComingSoon('Chat');
        break;
      case 'Agenda':
        _showComingSoon('Agenda');
        break;
      case 'Calendario':
        _showComingSoon('Calendario');
        break;
      case 'Notificaciones':
        _showComingSoon('Notificaciones');
        break;
      case 'Configuración':
        _showComingSoon('Configuración');
        break;
      default:
        _showComingSoon(screenName);
    }
  }

  void _showUserProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      'Información del Perfil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildUserProfileContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Email', currentUser?.email ?? 'No disponible'),
        _buildInfoRow('Tipo', currentUser?.tipoUsuario ?? 'No disponible'),
        
        if (currentUser?.isPersona == true && currentUser?.persona != null) ...[
          const SizedBox(height: 20),
          const Text(
            'Información Personal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC5414B),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Rol', currentUser!.persona!.rolDisplay), 
          _buildInfoRow('DNI', currentUser!.persona!.dni),
          _buildInfoRow('Username', currentUser!.persona!.username),
          _buildInfoRow('Nombre Completo', '${currentUser!.persona!.nombre} ${currentUser!.persona!.apellido}'),
        ],
        
        if (currentUser?.isEmpresa == true && currentUser?.empresa != null) ...[
          const SizedBox(height: 20),
          const Text(
            'Información Empresarial',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC5414B),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Nombre Corporativo', currentUser!.empresa!.nombreCorporativo),
          _buildInfoRow('CUIT', currentUser!.empresa!.cuit ?? 'No disponible'),
          _buildInfoRow('Razón Social', currentUser!.empresa!.razonSocial ?? 'No disponible'),
          _buildInfoRow('Representante Legal', currentUser!.empresa!.representanteLegal ?? 'No disponible'),
        ],
        
        const SizedBox(height: 20),
        const Text(
          'Estadísticas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC5414B),
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Trabajos Realizados', '${currentUser?.cantidadTrabajosRealizados ?? 0}'),
        _buildInfoRow('Puntos de Reputación', '${currentUser?.puntosReputacion ?? 0} pts'),
        _buildInfoRow('Rating', '${currentUser?.rating.toStringAsFixed(1)} ⭐'),
        
        const SizedBox(height: 40),
      ],
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Próximamente: $feature'),
        backgroundColor: const Color(0xFFC5414B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        title: const Text(
          'Inicio',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header de bienvenida
                  _buildWelcomeHeader(),
                  
                  const SizedBox(height: 32),
                  
                  // Menú de opciones expandido
                  _buildExpandedMenu(),
                  
                  const SizedBox(height: 32),
                  
                  // Estadísticas resumidas
                  _buildQuickStats(),
                  
                  const SizedBox(height: 32),
                  
                  // Botón de cerrar sesión
                  PrimaryButton(
                    text: 'Cerrar Sesión',
                    onPressed: _logout,
                    variant: 'secondary',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader() {
    final nombre = currentUser?.displayName ?? 'Usuario';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC5414B), Color(0xFFE85A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5414B).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¡Bienvenido!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accede a todas tus herramientas desde aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedMenu() {
    final menuItems = [
      {'title': 'Mi Perfil', 'icon': Icons.person, 'color': Colors.blue},
      {'title': 'Mis Rubros', 'icon': Icons.category, 'color': Colors.purple},
      {'title': 'Mis Ubicaciones', 'icon': Icons.location_on, 'color': Colors.orange},
      {'title': 'Mis Trabajos', 'icon': Icons.work, 'color': Colors.green},
      {'title': 'Chat', 'icon': Icons.chat, 'color': Colors.teal},
      {'title': 'Agenda', 'icon': Icons.event_note, 'color': Colors.indigo},
      {'title': 'Calendario', 'icon': Icons.calendar_today, 'color': Colors.red},
      {'title': 'Notificaciones', 'icon': Icons.notifications, 'color': Colors.amber},
      {'title': 'Configuración', 'icon': Icons.settings, 'color': Colors.grey},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menú Principal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _buildMenuCard(
              item['title'] as String,
              item['icon'] as IconData,
              item['color'] as Color,
              () => _navigateToScreen(item['title'] as String),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Trabajos',
                  '${currentUser?.cantidadTrabajosRealizados ?? 0}',
                  Icons.work_outline,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Reputación',
                  '${currentUser?.puntosReputacion ?? 0}',
                  Icons.star_outline,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Rating',
                  '${currentUser?.rating.toStringAsFixed(1)}',
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFC5414B), size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC5414B),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
