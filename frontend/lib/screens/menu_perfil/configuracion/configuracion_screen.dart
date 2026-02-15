// lib/screens/user/configuracion_screen.dart
// ✅ Pantalla principal de Configuración

import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({Key? key}) : super(key: key);

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final UserService _userService = UserService();
  User? _usuario;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final usuario = await _userService.obtenerUsuarioActual();
      
      if (mounted) {
        setState(() {
          _usuario = usuario;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando datos: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _mostrarEliminarCuenta() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: const Text(
          'Esta funcionalidad estará disponible próximamente.\n\n'
          'Si deseas eliminar tu cuenta, contacta con soporte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 176, 181),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        title: const Text(
          'Configuración',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección: Cuenta
                  _buildSeccionTitulo('Cuenta'),
                  _buildCard([
                    _buildOpcion(
                      Icons.person_outline,
                      'Nombre de perfil',
                      _usuario?.displayName ?? '',
                      () => Navigator.pushNamed(context, '/editar-nombre')
                          .then((_) => _cargarDatos()),
                    ),
                    _buildDivider(),
                    _buildOpcion(
                      Icons.email_outlined,
                      'Email',
                      _usuario?.email ?? '',
                      () => Navigator.pushNamed(context, '/editar-email')
                          .then((_) => _cargarDatos()),
                    ),
                    _buildDivider(),
                    _buildOpcion(
                      Icons.phone_outlined,
                      'Teléfono',
                      _usuario?.telefono ?? 'No configurado',
                      () => Navigator.pushNamed(context, '/editar-telefono')
                          .then((_) => _cargarDatos()),
                    ),
                    _buildDivider(),
                    _buildOpcion(
                      Icons.camera_alt_outlined,
                      'Foto de perfil',
                      'Cambiar imagen',
                      () => Navigator.pushNamed(context, '/editar-foto')
                          .then((_) => _cargarDatos()),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Sección: Seguridad
                  _buildSeccionTitulo('Seguridad'),
                  _buildCard([
                    _buildOpcion(
                      Icons.lock_outline,
                      'Cambiar contraseña',
                      'Actualizar tu contraseña',
                      () => Navigator.pushNamed(context, '/cambiar-contrasena'),
                    ),
                    _buildDivider(),
                    _buildOpcion(
                      Icons.delete_outline,
                      'Eliminar cuenta',
                      'Eliminar permanentemente',
                      _mostrarEliminarCuenta,
                      color: Colors.red,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Sección: Acerca de
                  _buildSeccionTitulo('Acerca de'),
                  _buildCard([
                    _buildOpcionSinFlecha(
                      Icons.info_outline,
                      'Versión',
                      'v1.0.0',
                    ),
                    _buildDivider(),
                    _buildOpcion(
                      Icons.description_outlined,
                      'Términos y condiciones',
                      '',
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Próximamente'),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildOpcion(
                      Icons.privacy_tip_outlined,
                      'Política de privacidad',
                      '',
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Próximamente'),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildOpcion(
                      Icons.support_agent_outlined,
                      'Contacto y soporte',
                      '',
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Próximamente'),
                          ),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Botón de Cerrar Sesión
                  _buildBotonCerrarSesion(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildOpcion(
    IconData icono,
    String titulo,
    String subtitulo,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icono,
              size: 24,
              color: color ?? Colors.grey.shade700,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color ?? Colors.black87,
                    ),
                  ),
                  if (subtitulo.isNotEmpty)
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionSinFlecha(
    IconData icono,
    String titulo,
    String valor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icono,
            size: 24,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildBotonCerrarSesion() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: _cerrarSesion,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}