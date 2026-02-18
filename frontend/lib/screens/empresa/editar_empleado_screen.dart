// lib/screens/empresa/editar_empleado_screen.dart

import 'package:flutter/material.dart';
import '../../models/empleado_empresa_model.dart';
import '../../services/empleado_empresa_service.dart';

class EditarEmpleadoScreen extends StatefulWidget {
  final EmpleadoEmpresaModel empleado;

  const EditarEmpleadoScreen({
    Key? key,
    required this.empleado,
  }) : super(key: key);

  @override
  State<EditarEmpleadoScreen> createState() => _EditarEmpleadoScreenState();
}

class _EditarEmpleadoScreenState extends State<EditarEmpleadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final EmpleadoEmpresaService _empleadoService = EmpleadoEmpresaService();

  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _relacionController;

  DateTime? _fechaNacimiento;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.empleado.nombre);
    _apellidoController = TextEditingController(text: widget.empleado.apellido);
    _relacionController = TextEditingController(text: widget.empleado.relacion ?? '');
    _fechaNacimiento = widget.empleado.fechaNacimiento;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _relacionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFC5414B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaNacimiento = fechaSeleccionada;
      });
    }
  }

  Future<void> _actualizarEmpleado() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _empleadoService.actualizarEmpleado(
        idEmpleado: widget.empleado.idEmpleado,
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        relacion: _relacionController.text.trim().isEmpty
            ? null
            : _relacionController.text.trim(),
        fechaNacimiento: _fechaNacimiento,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Empleado actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
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
          'Editar Empleado',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono central con avatar
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFC5414B),
                  backgroundImage: widget.empleado.fotoPerfilUrl != null
                      ? NetworkImage(widget.empleado.fotoPerfilUrl!)
                      : null,
                  child: widget.empleado.fotoPerfilUrl == null
                      ? Text(
                          widget.empleado.iniciales,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 32),

              // Nombre
              const Text(
                'Nombre *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  hintText: 'Ej: Juan',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 20),

              // Apellido
              const Text(
                'Apellido *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apellidoController,
                decoration: InputDecoration(
                  hintText: 'Ej: Pérez',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El apellido es obligatorio';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 20),

              // Relación/Cargo
              const Text(
                'Relación / Cargo (Opcional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _relacionController,
                decoration: InputDecoration(
                  hintText: 'Ej: Encargado, Ayudante, Operario',
                  prefixIcon: const Icon(Icons.work_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 20),

              // Fecha de Nacimiento
              const Text(
                'Fecha de Nacimiento (Opcional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _seleccionarFecha,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        _fechaNacimiento != null
                            ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                            : 'Seleccionar fecha',
                        style: TextStyle(
                          fontSize: 16,
                          color: _fechaNacimiento != null
                              ? Colors.black87
                              : Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      if (_fechaNacimiento != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _fechaNacimiento = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botón Actualizar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _actualizarEmpleado,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC5414B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ACTUALIZAR EMPLEADO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}