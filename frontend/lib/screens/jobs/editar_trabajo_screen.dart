// lib/screens/jobs/editar_trabajo_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/menu_perfil/trabajo_model.dart';
import '../../services/menu_perfil/trabajo_service.dart';
import '../../services/menu_perfil/rubro_service.dart';
import '../../services/postulacion_service.dart';
import '../../services/notificacion/notificacion_service.dart';
import '../../models/menu_perfil/rubro_model.dart';

class EditarTrabajoScreen extends StatefulWidget {
  final TrabajoModel trabajo;

  const EditarTrabajoScreen({Key? key, required this.trabajo}) : super(key: key);

  @override
  State<EditarTrabajoScreen> createState() => _EditarTrabajoScreenState();
}

class _EditarTrabajoScreenState extends State<EditarTrabajoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TrabajoService _trabajoService = TrabajoService();
  
  // Controllers
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _salarioController;
  late TextEditingController _cantidadEmpleadosController;
  late TextEditingController _calleController;
  late TextEditingController _numeroController;
  late TextEditingController _ciudadController;
  late TextEditingController _provinciaController;
  
  // Variables
  List<Rubro> _rubros = [];
  int? _rubroSeleccionado;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  TimeOfDay? _horarioInicio;
  TimeOfDay? _horarioFin;
  String? _metodoPago;
  String? _periodoPago;
  bool _permiteInicioIncompleto = false;
  
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _cargarRubros();
  }

  void _initializeControllers() {
    final trabajo = widget.trabajo;
    
    _tituloController = TextEditingController(text: trabajo.titulo);
    _descripcionController = TextEditingController(text: trabajo.descripcion);
    _salarioController = TextEditingController(
      text: trabajo.salario?.toStringAsFixed(0) ?? '',
    );
    _cantidadEmpleadosController = TextEditingController(
      text: trabajo.cantidadEmpleadosRequeridos?.toString() ?? '1',
    );
    
    // Dirección - parsear de direccionCompleta
    final direccion = trabajo.direccionCompleta?.split(', ') ?? [];
    if (direccion.isNotEmpty) {
      final calleParts = direccion[0].split(' ');
      _numeroController = TextEditingController(text: calleParts.last);
      _calleController = TextEditingController(
        text: calleParts.sublist(0, calleParts.length - 1).join(' '),
      );
    } else {
      _calleController = TextEditingController();
      _numeroController = TextEditingController();
    }
    
    _ciudadController = TextEditingController(
      text: direccion.length > 1 ? direccion[1] : '',
    );
    _provinciaController = TextEditingController(text: 'Córdoba');
    
    // Fechas y horarios
    _fechaInicio = trabajo.fechaInicio;
    _fechaFin = trabajo.fechaFin;
    
    if (trabajo.horarioInicio != null) {
      final parts = trabajo.horarioInicio!.split(':');
      _horarioInicio = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    
    if (trabajo.horarioFin != null) {
      final parts = trabajo.horarioFin!.split(':');
      _horarioFin = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    
    _metodoPago = trabajo.metodoPago;
    _periodoPago = trabajo.periodoPago;
    _permiteInicioIncompleto = trabajo.permiteInicioIncompleto;
  }

  Future<void> _cargarRubros() async {
    setState(() => _isLoading = true);
    try {
      final rubros = await RubroService.getRubros();
      setState(() {
        _rubros = rubros;
        _rubroSeleccionado = widget.trabajo.idRubro;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando rubros: $e')),
        );
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Construir datos actualizados
      final datosActualizados = {
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'id_rubro': _rubroSeleccionado,
        'salario': _salarioController.text.isNotEmpty 
            ? double.parse(_salarioController.text) 
            : null,
        'periodo_pago': _periodoPago,
        'metodo_pago': _metodoPago,
        'cantidad_empleados_requeridos': int.parse(_cantidadEmpleadosController.text),
        'fecha_inicio': _fechaInicio?.toIso8601String().split('T')[0],
        'fecha_fin': _fechaFin?.toIso8601String().split('T')[0],
        'horario_inicio': _horarioInicio != null
            ? '${_horarioInicio!.hour.toString().padLeft(2, '0')}:${_horarioInicio!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'horario_fin': _horarioFin != null
            ? '${_horarioFin!.hour.toString().padLeft(2, '0')}:${_horarioFin!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'permite_inicio_incompleto': _permiteInicioIncompleto,
      };

      // Actualizar trabajo
      await _trabajoService.updateTrabajo(widget.trabajo.id, datosActualizados);

      // ✅ NOTIFICAR A POSTULADOS
      await _notificarPostulados();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trabajo actualizado exitosamente'),
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
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _notificarPostulados() async {
    try {
      // Obtener postulaciones pendientes y aceptadas
      final postulaciones = await PostulacionService.getPostulacionesDeTrabajo(
        widget.trabajo.id,
      );

      final postuladosRelevantes = postulaciones
          .where((p) => p.estado == 'PENDIENTE' || p.estado == 'ACEPTADO')
          .toList();

      // Crear notificación para cada uno
      for (var postulacion in postuladosRelevantes) {
        await NotificacionService.crearNotificacion(
          usuarioId: postulacion.postulanteId,
          tipo: 'TRABAJO_MODIFICADO',
          mensaje: 'El trabajo "${_tituloController.text}" ha sido modificado por el empleador',
          trabajoId: widget.trabajo.id,
          postulacionId: postulacion.id,
        );
      }

      print('✅ ${postuladosRelevantes.length} notificaciones enviadas');
    } catch (e) {
      print('⚠️ Error notificando postulados: $e');
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _salarioController.dispose();
    _cantidadEmpleadosController.dispose();
    _calleController.dispose();
    _numeroController.dispose();
    _ciudadController.dispose();
    _provinciaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        title: const Text(
          'Editar Trabajo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _guardarCambios,
              child: const Text(
                'GUARDAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSeccion('Información Básica', [
                      _buildTextField(
                        controller: _tituloController,
                        label: 'Título del trabajo *',
                        icon: Icons.work,
                        validator: (value) => value!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descripcionController,
                        label: 'Descripción *',
                        icon: Icons.description,
                        maxLines: 4,
                        validator: (value) => value!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Rubro *',
                        icon: Icons.category,
                        value: _rubroSeleccionado,
                        items: _rubros
                            .map((r) => DropdownMenuItem(
                                  value: r.idRubro, // ✅ USAR idRubro
                                  child: Text(r.nombre),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _rubroSeleccionado = value),
                      ),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    _buildSeccion('Compensación', [
                      _buildTextField(
                        controller: _salarioController,
                        label: 'Salario (opcional)',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Período de pago',
                        icon: Icons.calendar_today,
                        value: _periodoPago,
                        items: const [
                          DropdownMenuItem(value: 'POR_HORA', child: Text('Por hora')),
                          DropdownMenuItem(value: 'POR_DIA', child: Text('Por día')),
                          DropdownMenuItem(value: 'POR_TRABAJO', child: Text('Por trabajo')),
                        ],
                        onChanged: (value) => setState(() => _periodoPago = value),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Método de pago',
                        icon: Icons.payment,
                        value: _metodoPago,
                        items: const [
                          DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
                          DropdownMenuItem(value: 'TRANSFERENCIA', child: Text('Transferencia')),
                          DropdownMenuItem(value: 'MERCADOPAGO', child: Text('MercadoPago')),
                        ],
                        onChanged: (value) => setState(() => _metodoPago = value),
                      ),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    _buildSeccion('Fechas y Horarios', [
                      _buildDatePicker(
                        label: 'Fecha de inicio *',
                        icon: Icons.event,
                        fecha: _fechaInicio,
                        onTap: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: _fechaInicio ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (fecha != null) {
                            setState(() => _fechaInicio = fecha);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDatePicker(
                        label: 'Fecha de fin (opcional)',
                        icon: Icons.event,
                        fecha: _fechaFin,
                        onTap: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: _fechaFin ?? _fechaInicio ?? DateTime.now(),
                            firstDate: _fechaInicio ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (fecha != null) {
                            setState(() => _fechaFin = fecha);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTimePicker(
                        label: 'Horario de inicio',
                        icon: Icons.access_time,
                        time: _horarioInicio,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _horarioInicio ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() => _horarioInicio = time);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTimePicker(
                        label: 'Horario de fin',
                        icon: Icons.access_time,
                        time: _horarioFin,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _horarioFin ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() => _horarioFin = time);
                          }
                        },
                      ),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    _buildSeccion('Personal', [
                      _buildTextField(
                        controller: _cantidadEmpleadosController,
                        label: 'Cantidad de empleados *',
                        icon: Icons.people,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value!.isEmpty) return 'Requerido';
                          if (int.parse(value) < 1) return 'Mínimo 1';
                          return null;
                        },
                        onChanged: (value) {
                          if (int.tryParse(value) == 1) {
                            setState(() => _permiteInicioIncompleto = false);
                          }
                        },
                      ),
                      if (int.tryParse(_cantidadEmpleadosController.text) != null &&
                          int.parse(_cantidadEmpleadosController.text) > 1) ...[
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Permite inicio incompleto'),
                          subtitle: const Text('El trabajo puede iniciar sin llenar todos los cupos'),
                          value: _permiteInicioIncompleto,
                          activeColor: const Color(0xFFC5414B),
                          onChanged: (value) => setState(() => _permiteInicioIncompleto = value),
                        ),
                      ],
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    _buildSeccion('Ubicación', [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              controller: _calleController,
                              label: 'Calle *',
                              icon: Icons.location_on,
                              validator: (value) => value!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: _buildTextField(
                              controller: _numeroController,
                              label: 'Número *',
                              keyboardType: TextInputType.number,
                              validator: (value) => value!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _ciudadController,
                        label: 'Ciudad *',
                        icon: Icons.location_city,
                        validator: (value) => value!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _provinciaController,
                        label: 'Provincia *',
                        icon: Icons.map,
                        validator: (value) => value!.isEmpty ? 'Requerido' : null,
                      ),
                    ]),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC5414B),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFFC5414B)) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFC5414B)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime? fecha,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFC5414B)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Text(
          fecha != null
              ? '${fecha.day}/${fecha.month}/${fecha.year}'
              : 'Seleccionar fecha',
          style: TextStyle(
            color: fecha != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required IconData icon,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFC5414B)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Text(
          time != null ? time.format(context) : 'Seleccionar hora',
          style: TextStyle(
            color: time != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }
}