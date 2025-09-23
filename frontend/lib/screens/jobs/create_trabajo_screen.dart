import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/trabajo_service.dart';
import '../../components/custom_text_field.dart';
import '../../components/primary_button.dart';

class CrearTrabajoScreen extends StatefulWidget {
  const CrearTrabajoScreen({Key? key}) : super(key: key);

  @override
  State<CrearTrabajoScreen> createState() => _CrearTrabajoScreenState();
}

class _CrearTrabajoScreenState extends State<CrearTrabajoScreen> {
  final _formKey = GlobalKey<FormState>();
  final servicio = TrabajoService();

  // Controladores
  final tituloController = TextEditingController();
  final descripcionController = TextEditingController();
  final salarioController = TextEditingController();
  final horarioInicioController = TextEditingController();
  final horarioFinController = TextEditingController();

  // Variables de estado
  bool isLoading = false;
  String? selectedRubro;
  String? selectedMetodoPago;
  String? selectedUrgencia;
  int? cantidadSeleccionada;
  String? ubicacionSeleccionada; // id_ubicacion como string
  List<String> rubros = [];
  List<Map<String, dynamic>> _ubicaciones = [];
  List<DateTime> fechasSeleccionadas = [];

  // Opciones predefinidas
  final List<String> metodosPago = ['EFECTIVO', 'TRANSFERENCIA'];
  final List<String> nivelesUrgencia = ['BAJA', 'ESTANDAR', 'ALTA', 'URGENTE'];

  @override
  void initState() {
    super.initState();
    _cargarRubros();
    _cargarUbicaciones();
  }

  Future<void> _cargarRubros() async {
    final result = await servicio.getRubros();
    setState(() => rubros = [...result, 'Otros']);
  }

  Future<void> _cargarUbicaciones() async {
    final result = await servicio.getUbicacionesDelUsuario();
    setState(() => _ubicaciones = result);
  }

  String? _validarTitulo(String? value) {
    if (value == null || value.isEmpty) return 'Este campo es requerido';
    if (value.length < 5) return 'El título debe tener al menos 5 caracteres';
    return null;
  }

  String? _validarDescripcion(String? value) {
    if (value == null || value.isEmpty) return 'Este campo es requerido';
    if (value.length < 20) return 'Mínimo 20 caracteres';
    return null;
  }

  String? _validarHorario(String? value, String campo) {
    if (value == null || value.isEmpty) return 'Este campo es requerido';
    final regex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!regex.hasMatch(value)) return '$campo debe estar en formato HH:MM (24hs)';
    return null;
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && !fechasSeleccionadas.contains(picked)) {
      setState(() => fechasSeleccionadas..add(picked)..sort());
    }
  }

  Future<void> _seleccionarRangoFechas() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      final rango = <DateTime>[];
      var current = picked.start;
      while (current.isBefore(picked.end) || current.isAtSameMomentAs(picked.end)) {
        rango.add(current);
        current = current.add(const Duration(days: 1));
      }
      setState(() => fechasSeleccionadas = rango);
    }
  }

  void _eliminarFecha(DateTime fecha) {
    setState(() => fechasSeleccionadas.remove(fecha));
  }

  Future<void> _publicarTrabajo() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos obligatorios'), backgroundColor: Colors.red),
      );
      return;
    }

    if (fechasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar al menos una fecha'), backgroundColor: Colors.red),
      );
      return;
    }

    if (selectedRubro == null || selectedMetodoPago == null || cantidadSeleccionada == null || ubicacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faltan seleccionar opciones obligatorias'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validar que horario fin > inicio
    final inicio = _parseHora(horarioInicioController.text);
    final fin = _parseHora(horarioFinController.text);
    if (inicio != null && fin != null && fin.isBefore(inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora de fin no puede ser menor a la de inicio'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      final datosEnvio = {
        'titulo': tituloController.text.trim(),
        'descripcion': descripcionController.text.trim(),
        'salario': salarioController.text.isEmpty ? null : double.parse(salarioController.text),
        'cantidad_empleados_requeridos': cantidadSeleccionada,
        'id_rubro': selectedRubro,
        'ubicacion_id': int.tryParse(ubicacionSeleccionada!), // ✅ ahora manda id_ubicacion
        'metodo_pago': selectedMetodoPago!,
        'urgencia': selectedUrgencia ?? 'ESTANDAR',
        'estado_publicacion': 'PUBLICADO',
        'fecha_inicio': fechasSeleccionadas.first.toIso8601String().split('T')[0],
        'fecha_fin': fechasSeleccionadas.last.toIso8601String().split('T')[0],
        'horario_inicio': horarioInicioController.text,
        'horario_fin': horarioFinController.text,
        'empleador_id': user?.id,
      };

      await servicio.createTrabajo(datosEnvio);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trabajo publicado con éxito'), backgroundColor: Color(0xFFC5414B)),
      );

      _limpiarFormulario();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _limpiarFormulario() {
    _formKey.currentState!.reset();
    tituloController.clear();
    descripcionController.clear();
    salarioController.clear();
    horarioInicioController.clear();
    horarioFinController.clear();
    setState(() {
      selectedRubro = null;
      selectedMetodoPago = null;
      selectedUrgencia = null;
      cantidadSeleccionada = null;
      ubicacionSeleccionada = null;
      fechasSeleccionadas.clear();
    });
  }

  DateTime? _parseHora(String value) {
    try {
      final parts = value.split(':');
      return DateTime(0, 0, 0, int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        title: const Text('Crear Trabajo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSeccion(
                'Información básica',
                Icons.work_outline,
                [
                  TextFormField(
                    controller: tituloController,
                    validator: _validarTitulo,
                    decoration: _inputDecoration('Título del trabajo'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descripcionController,
                    validator: _validarDescripcion,
                    maxLines: 4,
                    decoration: _inputDecoration('Descripción detallada'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRubro,
                    items: rubros.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setState(() => selectedRubro = val),
                    decoration: _inputDecoration('Categoría *'),
                    validator: (val) => val == null ? 'Selecciona un rubro' : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSeccion(
                'Fechas y horarios',
                Icons.schedule_outlined,
                [
                  _buildFechasSection(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: horarioInicioController,
                          validator: (val) => _validarHorario(val, 'Horario inicio'),
                          decoration: _inputDecoration('Inicio (08:30)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: horarioFinController,
                          validator: (val) => _validarHorario(val, 'Horario fin'),
                          decoration: _inputDecoration('Fin (17:00)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSeccion(
                'Detalles del trabajo',
                Icons.info_outline,
                [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: salarioController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Precio (\$)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(onPressed: () => setState(() => salarioController.clear()), child: const Text('Sin precio')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: ubicacionSeleccionada == null ? null : int.tryParse(ubicacionSeleccionada!),
                    items: _ubicaciones
                        .map((u) => DropdownMenuItem<int>(
                              value: u['id_ubicacion'],
                              child: Text("${u['nombre']} - ${u['ciudad']}"),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => ubicacionSeleccionada = val?.toString()),
                    decoration: _inputDecoration('Ubicación *'),
                    validator: (val) => val == null ? 'Selecciona ubicación' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: cantidadSeleccionada,
                    items: List.generate(5, (i) => i + 1)
                        .map((n) => DropdownMenuItem(value: n, child: Text('$n trabajadores')))
                        .toList(),
                    onChanged: (val) => setState(() => cantidadSeleccionada = val),
                    decoration: _inputDecoration('Cantidad de empleados *'),
                    validator: (val) => val == null ? 'Selecciona cantidad' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedMetodoPago,
                          items: metodosPago.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (val) => setState(() => selectedMetodoPago = val),
                          decoration: _inputDecoration('Método de pago *'),
                          validator: (val) => val == null ? 'Selecciona método' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedUrgencia,
                          items: nivelesUrgencia.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (val) => setState(() => selectedUrgencia = val),
                          decoration: _inputDecoration('Urgencia'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(text: 'Publicar Trabajo', onPressed: _publicarTrabajo, isLoading: isLoading),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF012345), width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFC5414B), Color(0xFFE85A4F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFC5414B).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Publica tu Trabajo', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Completa todos los detalles para atraer a los mejores candidatos', style: TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSeccion(String titulo, IconData icono, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icono, color: const Color(0xFFC5414B)), const SizedBox(width: 8), Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _buildFechasSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          const Text('Fechas del trabajo *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(onPressed: _seleccionarFecha, icon: const Icon(Icons.add, size: 16), label: const Text('Agregar fecha')),
          TextButton.icon(onPressed: _seleccionarRangoFechas, icon: const Icon(Icons.date_range, size: 16), label: const Text('Rango de días')),
        ],
      ),
      const SizedBox(height: 8),
      if (fechasSeleccionadas.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
          child: Text('Selecciona al menos una fecha', style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fechasSeleccionadas
              .map((f) => Chip(
                    label: Text('${f.day}/${f.month}/${f.year}'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _eliminarFecha(f),
                    backgroundColor: const Color(0xFFC5414B).withOpacity(0.1),
                    deleteIconColor: const Color(0xFFC5414B),
                  ))
              .toList(),
        ),
    ]);
  }
}
