// lib/screens/empresa/mis_empleados_screen.dart

import 'package:flutter/material.dart';
import '../../models/empleado_empresa_model.dart';
import '../../services/empleado_empresa_service.dart';

class MisEmpleadosScreen extends StatefulWidget {
  const MisEmpleadosScreen({Key? key}) : super(key: key);

  @override
  State<MisEmpleadosScreen> createState() => _MisEmpleadosScreenState();
}

class _MisEmpleadosScreenState extends State<MisEmpleadosScreen> {
  final EmpleadoEmpresaService _empleadoService = EmpleadoEmpresaService();
  List<EmpleadoEmpresaModel> _empleados = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarEmpleados();
  }

  Future<void> _cargarEmpleados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final empleados = await _empleadoService.obtenerEmpleados();
      if (mounted) {
        setState(() {
          _empleados = empleados;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _eliminarEmpleado(EmpleadoEmpresaModel empleado) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar empleado'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${empleado.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        await _empleadoService.eliminarEmpleado(empleado.idEmpleado);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Empleado eliminado'),
            backgroundColor: Colors.green,
          ),
        );
        
        _cargarEmpleados();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mis Empleados',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarEmpleados,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.pushNamed(context, '/agregar-empleado');
          if (resultado == true) {
            _cargarEmpleados();
          }
        },
        backgroundColor: const Color(0xFFC5414B),
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Empleado'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarEmpleados,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_empleados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tienes empleados registrados',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega empleados para poder postularlos a trabajos',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final resultado = await Navigator.pushNamed(context, '/agregar-empleado');
                if (resultado == true) {
                  _cargarEmpleados();
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Agregar Primer Empleado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5414B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarEmpleados,
      color: const Color(0xFFC5414B),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _empleados.length,
        itemBuilder: (context, index) {
          return _buildEmpleadoCard(_empleados[index]);
        },
      ),
    );
  }

  Widget _buildEmpleadoCard(EmpleadoEmpresaModel empleado) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFC5414B),
          backgroundImage: empleado.fotoPerfilUrl != null
              ? NetworkImage(empleado.fotoPerfilUrl!)
              : null,
          child: empleado.fotoPerfilUrl == null
              ? Text(
                  empleado.iniciales,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          empleado.nombreCompleto,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (empleado.relacion != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.work_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    empleado.relacion!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (empleado.edad != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.cake_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${empleado.edad} años',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'editar') {
              Navigator.pushNamed(
                context,
                '/editar-empleado',
                arguments: empleado,
              ).then((result) {
                if (result == true) {
                  _cargarEmpleados();
                }
              });
            } else if (value == 'eliminar') {
              _eliminarEmpleado(empleado);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}