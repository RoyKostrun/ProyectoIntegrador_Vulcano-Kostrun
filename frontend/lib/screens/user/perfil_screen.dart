// lib/screens/user/perfil_screen.dart
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../widgets/disponibilidad_switch.dart';
import '../../widgets/disponibilidad_badge.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({Key? key}) : super(key: key);

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final UserService _userService = UserService();
  User? _usuario;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usuario = await _userService.obtenerUsuarioActual();
      if (mounted) {
        setState(() {
          _usuario = usuario;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar usuario: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar el perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Volver',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFC5414B),
          ),
        ),
      );
    }

    if (_usuario == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Volver',
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No se pudo cargar tu perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _cargarUsuario,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5414B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final persona = _usuario!.persona;
    final empresa = _usuario!.empresa;
    final isPersona = _usuario!.isPersona;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: 'Volver',
        ),
        actions: [
          // Badge de disponibilidad en el header (solo para empleados)
          if (isPersona && persona != null && persona.esEmpleado)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: DisponibilidadBadge(
                  disponibilidad: persona.disponibilidad,
                  mostrarTexto: false,
                  size: 20,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Editar perfil - próximamente'),
                ),
              );
            },
            tooltip: 'Editar Perfil',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarUsuario,
        color: const Color(0xFFC5414B),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con foto y nombre
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: isPersona && persona?.fotoPerfilUrl != null
                              ? NetworkImage(persona!.fotoPerfilUrl!)
                              : null,
                          child: (isPersona && persona?.fotoPerfilUrl == null) ||
                                  (!isPersona && empresa?.nombreCorporativo == null)
                              ? Icon(
                                  isPersona ? Icons.person : Icons.business,
                                  size: 60,
                                  color: Colors.grey.shade600,
                                )
                              : null,
                        ),
                        // Indicador de disponibilidad en la foto (solo empleados)
                        if (isPersona && persona != null && persona.esEmpleado)
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: persona.disponibilidad == 'ACTIVO'
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _usuario!.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isPersona && persona != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@${persona.username}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (persona.esEmpleado)
                        DisponibilidadBadge(
                          disponibilidad: persona.disponibilidad,
                        ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _usuario!.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ 5.0',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ✅ SWITCH DE DISPONIBILIDAD (solo para empleados)
              if (isPersona && persona != null && persona.esEmpleado)
                DisponibilidadSwitch(
                  persona: persona,
                  onDisponibilidadCambiada: (nuevoValor) {
                    // Recargar usuario para actualizar el estado en toda la pantalla
                    _cargarUsuario();
                  },
                ),

              const SizedBox(height: 16),

              // Información del perfil
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información Personal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.email,
                        'Email',
                        _usuario!.email,
                      ),
                      if (_usuario!.telefono != null)
                        _buildInfoRow(
                          Icons.phone,
                          'Teléfono',
                          _usuario!.telefono!,
                        ),
                      if (isPersona && persona != null) ...[
                        _buildInfoRow(
                          Icons.badge,
                          'DNI',
                          persona.dni,
                        ),
                        if (persona.fechaNacimiento != null)
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Fecha de Nacimiento',
                            '${persona.fechaNacimiento!.day}/${persona.fechaNacimiento!.month}/${persona.fechaNacimiento!.year}',
                          ),
                        _buildInfoRow(
                          Icons.person,
                          'Género',
                          _formatearGenero(persona.genero),
                        ),
                      ],
                      if (!isPersona && empresa != null) ...[
                        if (empresa.cuit != null)
                          _buildInfoRow(
                            Icons.business,
                            'CUIT',
                            empresa.cuit!,
                          ),
                        if (empresa.razonSocial != null)
                          _buildInfoRow(
                            Icons.description,
                            'Razón Social',
                            empresa.razonSocial!,
                          ),
                      ],
                      _buildInfoRow(
                        Icons.work,
                        'Trabajos Realizados',
                        '${_usuario!.cantidadTrabajosRealizados}',
                      ),
                      _buildInfoRow(
                        Icons.emoji_events,
                        'Puntos de Reputación',
                        '${_usuario!.puntosReputacion}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Roles (solo para personas)
              if (isPersona && persona != null)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Roles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (persona.esEmpleado)
                              Chip(
                                avatar: const Icon(
                                  Icons.work,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                label: const Text('Empleado'),
                                backgroundColor: Colors.blue.shade100,
                              ),
                            if (persona.esEmpleador)
                              Chip(
                                avatar: const Icon(
                                  Icons.business_center,
                                  size: 18,
                                  color: Colors.green,
                                ),
                                label: const Text('Empleador'),
                                backgroundColor: Colors.green.shade100,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Estado de la cuenta
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado de la Cuenta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _usuario!.isActive
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _usuario!.estadoCuenta,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _usuario!.isActive
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatearGenero(String genero) {
    switch (genero) {
      case 'M':
        return 'Masculino';
      case 'F':
        return 'Femenino';
      case 'X':
        return 'Otro';
      default:
        return 'No especificado';
    }
  }
}