//lib/screens/jobs/create_trabajo_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/menu_perfil/trabajo_service.dart';
import '../../services/menu_perfil/rubro_service.dart';
import '../../services/menu_perfil/ubicacion_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/menu_perfil/trabajo_foto_service.dart';
import '../../components/primary_button.dart';
import '../../services/calificacion_service.dart';
import '../../widgets/ios_time_picker.dart';

class CrearTrabajoScreen extends StatefulWidget {
  const CrearTrabajoScreen({Key? key}) : super(key: key);

  @override
  State<CrearTrabajoScreen> createState() => _CrearTrabajoScreenState();
}

class _CrearTrabajoScreenState extends State<CrearTrabajoScreen> {
  final _formKey = GlobalKey<FormState>();
  final trabajoService = TrabajoService();
  final ubicacionService = UbicacionService();
  final userService = UserService();

  final tituloController = TextEditingController();
  final descripcionController = TextEditingController();
  final salarioController = TextEditingController();
  final horarioInicioController = TextEditingController();
  final horarioFinController = TextEditingController();

  bool isLoading = false;
  bool isLoadingUbicaciones = true;
  bool isLoadingRubros = true;
  bool isCheckingEmpleador = true;
  bool esEmpleador = false;
  bool sinPrecio = false;
  bool permiteInicioIncompleto = false;
  String? selectedRubro;
  String? selectedMetodoPago;
  String? periodoPagoSeleccionado;
  int? cantidadSeleccionada;
  String? ubicacionSeleccionada;
  String? direccionCompleta;
  List<String> rubros = [];
  List<Map<String, dynamic>> _ubicaciones = [];
  List<DateTime> fechasSeleccionadas = [];

  // ✅ NUEVAS VARIABLES PARA FOTOS
  List<XFile> _fotosSeleccionadas = [];
  bool _isUploadingFotos = false;

  final List<String> metodosPago = ['EFECTIVO', 'TRANSFERENCIA'];

  @override
  void initState() {
    super.initState();
    _verificarSiEsEmpleador();
    _cargarRubros();
    _cargarUbicaciones();
  }

  @override
  void dispose() {
    tituloController.dispose();
    descripcionController.dispose();
    salarioController.dispose();
    horarioInicioController.dispose();
    horarioFinController.dispose();
    super.dispose();
  }

  Future<void> _verificarSiEsEmpleador() async {
    setState(() => isCheckingEmpleador = true);
    try {
      final resultado = await userService.esEmpleador();
      setState(() {
        esEmpleador = resultado;
        isCheckingEmpleador = false;
      });
    } catch (e) {
      setState(() => isCheckingEmpleador = false);
      print('❌ Error al verificar si es empleador: $e');
    }
  }

  Future<void> _irAUnirseEmpleadores() async {
    final resultado = await Navigator.pushNamed(context, '/unirse-empleadores');

    if (resultado == true && mounted) {
      await _verificarSiEsEmpleador();
    }
  }

  Future<void> _cargarRubros() async {
    setState(() => isLoadingRubros = true);
    try {
      final result = await RubroService.getRubros();
      setState(() {
        rubros = [...result.map((r) => r.nombre), 'Otros'];
        isLoadingRubros = false;
      });
    } catch (e) {
      setState(() => isLoadingRubros = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al cargar rubros: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cargarUbicaciones() async {
    setState(() => isLoadingUbicaciones = true);
    try {
      final result = await ubicacionService.getUbicacionesDelUsuario();
      setState(() {
        _ubicaciones = result;
        isLoadingUbicaciones = false;
      });
    } catch (e) {
      setState(() => isLoadingUbicaciones = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al cargar ubicaciones: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============================================
  // ✅ MÉTODOS PARA GESTIÓN DE FOTOS
  // ============================================

  Future<void> _seleccionarFotos() async {
    try {
      final TrabajoFotoService fotoService = TrabajoFotoService();

      if (_fotosSeleccionadas.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Máximo 5 fotos permitidas'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final fotos = await fotoService.seleccionarMultiplesfotos();

      if (fotos.isEmpty) return;

      final espacioDisponible = 5 - _fotosSeleccionadas.length;
      if (fotos.length > espacioDisponible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solo puedes agregar $espacioDisponible foto(s) más'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _fotosSeleccionadas.addAll(fotos);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${fotos.length} foto(s) seleccionada(s)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error al seleccionar fotos: $e');
    }
  }

  void _eliminarFoto(int index) {
    setState(() {
      _fotosSeleccionadas.removeAt(index);
    });
  }

  bool get esRangoDias => fechasSeleccionadas.length > 1;

  void _onFechasChanged() {
    setState(() {
      periodoPagoSeleccionado = null;
    });
  }

  String? _validarTitulo(String? value) {
    if (value == null || value.isEmpty) return 'Este campo es requerido';
    if (value.length < 5) return 'El título debe tener al menos 5 caracteres';
    return null;
  }

  String? _validarDescripcion(String? value) {
    if (value == null || value.isEmpty) return 'Este campo es requerido';
    if (value.length < 20)
      return 'La descripción debe tener al menos 20 caracteres';
    return null;
  }

  String? _validarSalario(String? value) {
    if (sinPrecio) return null;
    if (cantidadSeleccionada == null) return null;
    if (value == null || value.isEmpty) return 'Ingresa el precio';
    final numero = double.tryParse(value);
    if (numero == null) return 'Ingresa un número válido';
    if (numero < 0) return 'El precio no puede ser negativo';
    return null;
  }

  Future<void> _seleccionarHora(
    TextEditingController controller, {
    bool abrirSiguiente = false,
    bool esHoraInicio = true,
  }) async {
    final TimeOfDay? picked = await showIOSTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      title: esHoraInicio ? 'Hora de Inicio' : 'Hora de Fin',
    );

    if (picked != null) {
      setState(() {
        // ✅ FORMATO CORREGIDO: siempre 2 dígitos con padLeft
        controller.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });

      if (abrirSiguiente) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _seleccionarHora(horarioFinController, esHoraInicio: false);
        });
      }
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        fechasSeleccionadas = [picked];
        _onFechasChanged();
      });
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
      while (current.isBefore(picked.end) ||
          current.isAtSameMomentAs(picked.end)) {
        rango.add(current);
        current = current.add(const Duration(days: 1));
      }
      setState(() {
        fechasSeleccionadas = rango;
        _onFechasChanged();
      });
    }
  }

  void _eliminarFecha(DateTime fecha) {
    setState(() {
      fechasSeleccionadas.remove(fecha);
      if (fechasSeleccionadas.isEmpty || fechasSeleccionadas.length == 1) {
        _onFechasChanged();
      }
    });
  }

  void _irAAgregarUbicacion() {
    Navigator.pushNamed(context, '/agregar-ubicacion')
        .then((_) => _cargarUbicaciones());
  }

  Future<void> _crearNuevaUbicacion() async {
    final nuevaUbicacion = await Navigator.pushNamed(
      context,
      '/crear-ubicacion',
    );

    if (nuevaUbicacion != null && mounted) {
      print('✅ Nueva ubicación creada: $nuevaUbicacion');

      await _cargarUbicaciones();

      setState(() {
        if (nuevaUbicacion is Map<String, dynamic>) {
          final idNuevaUbicacion = nuevaUbicacion['id_ubicacion'].toString();

          ubicacionSeleccionada = idNuevaUbicacion;

          direccionCompleta =
              '${nuevaUbicacion['calle']} ${nuevaUbicacion['numero']}, ${nuevaUbicacion['ciudad']}, ${nuevaUbicacion['provincia']}';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Nueva ubicación seleccionada'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<int?> _getIdRubroByName(String nombre) async {
    try {
      final rubros = await RubroService.getRubros();
      final rubro = rubros.firstWhere(
        (r) => r.nombre == nombre,
        orElse: () => throw Exception('Rubro no encontrado'),
      );
      return rubro.idRubro;
    } catch (e) {
      print('❌ Error obteniendo ID del rubro: $e');
      return null;
    }
  }

  Future<void> _publicarTrabajo() async {
    // ✅ NUEVA VALIDACIÓN: Verificar horarios si el trabajo es HOY
    if (fechasSeleccionadas.isNotEmpty) {
      final primerDia = fechasSeleccionadas.first;
      final hoy = DateTime.now();

      // Si el trabajo es HOY, validar que los horarios no sean pasados
      if (primerDia.year == hoy.year &&
          primerDia.month == hoy.month &&
          primerDia.day == hoy.day) {
        // Validar hora de inicio
        if (horarioInicioController.text.isNotEmpty) {
          final partesInicio = horarioInicioController.text.split(':');
          final horaInicio = int.parse(partesInicio[0]);
          final minutoInicio = int.parse(partesInicio[1]);

          final horarioInicio = DateTime(
            hoy.year,
            hoy.month,
            hoy.day,
            horaInicio,
            minutoInicio,
          );

          // Si la hora de inicio ya pasó, mostrar error
          if (horarioInicio.isBefore(hoy)) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Horario Inválido',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'El horario de inicio que seleccionaste ya pasó.',
                      style: TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Hora actual: ${hoy.hour.toString().padLeft(2, '0')}:${hoy.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Por favor, selecciona un horario futuro.',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5414B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            );
            return; // ❌ Bloquear creación
          }
        }
      }
    }

    // ✅ VALIDACIÓN DE CALIFICACIONES PENDIENTES (tu código existente)
    final tienePendientes =
        await CalificacionService.tieneCalificacionesPendientes();

    // ✅ RESTO DEL CÓDIGO ORIGINAL (todas las validaciones que ya tienes)
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Completa todos los campos obligatorios'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (fechasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Debe seleccionar al menos una fecha para el trabajo'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (periodoPagoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Debe seleccionar el período de pago'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (selectedRubro == null ||
        selectedMetodoPago == null ||
        cantidadSeleccionada == null ||
        ubicacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Faltan seleccionar opciones obligatorias'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final inicio = _parseHora(horarioInicioController.text);
    final fin = _parseHora(horarioFinController.text);
    if (inicio != null && fin != null && fin.isBefore(inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La hora de fin no puede ser menor a la de inicio'),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final userData = await AuthService.getCurrentUserData();
      if (userData == null) {
        throw Exception('Usuario no autenticado');
      }

      final idUsuario = userData.idUsuario;
      print('📝 Creando trabajo para usuario ID: $idUsuario');

      final idRubro = await _getIdRubroByName(selectedRubro!);
      if (idRubro == null) {
        throw Exception('No se encontró el rubro seleccionado');
      }

      final datosEnvio = {
        'titulo': tituloController.text.trim(),
        'descripcion': descripcionController.text.trim(),
        'salario': sinPrecio || salarioController.text.isEmpty
            ? 0.0
            : double.parse(salarioController.text),
        'cantidad_empleados_requeridos': cantidadSeleccionada,
        'permite_inicio_incompleto': permiteInicioIncompleto,
        'id_rubro': idRubro,
        'ubicacion_id': int.parse(ubicacionSeleccionada!),
        'metodo_pago': selectedMetodoPago!,
        'periodo_pago': periodoPagoSeleccionado!,
        'estado_publicacion': 'PUBLICADO',
        'urgencia': 'ESTANDAR',
        'fecha_inicio':
            fechasSeleccionadas.first.toIso8601String().split('T')[0],
        'fecha_fin': fechasSeleccionadas.last.toIso8601String().split('T')[0],
        'horario_inicio': horarioInicioController.text,
        'horario_fin': horarioFinController.text,
        'empleador_id': idUsuario,
      };

      print('🕐 DATOS ENVIADOS:');
      print('   Horario inicio controller: ${horarioInicioController.text}');
      print('   Horario fin controller: ${horarioFinController.text}');
      print(
          '   Datos enviados: ${datosEnvio['horario_inicio']} - ${datosEnvio['horario_fin']}');
      // ✅ CREAR TRABAJO
      final trabajoCreado = await trabajoService.createTrabajo(datosEnvio);
      final trabajoId = trabajoCreado['id_trabajo'] as int;

      print('✅ Trabajo creado con ID: $trabajoId');

      // ✅ SUBIR FOTOS SI HAY SELECCIONADAS
      if (_fotosSeleccionadas.isNotEmpty && mounted) {
        setState(() => _isUploadingFotos = true);

        try {
          final TrabajoFotoService fotoService = TrabajoFotoService();
          await fotoService.subirFotosMultiples(
            idTrabajo: trabajoId,
            imageFiles: _fotosSeleccionadas,
            primeraEsPrincipal: true,
          );
          print('✅ Fotos subidas exitosamente');
        } catch (e) {
          print('⚠️ Error al subir fotos: $e');
          // No fallar si las fotos no se suben
        } finally {
          if (mounted) {
            setState(() => _isUploadingFotos = false);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('La publicación laboral se creó exitosamente'),
              backgroundColor: Color(0xFFC5414B)),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main-nav',
          (route) => false,
          arguments: {'initialTab': 0},
        );
      }

      _limpiarFormulario();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al publicar: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
      periodoPagoSeleccionado = null;
      cantidadSeleccionada = null;
      ubicacionSeleccionada = null;
      direccionCompleta = null;
      fechasSeleccionadas.clear();
      sinPrecio = false;
      permiteInicioIncompleto = false;
      _fotosSeleccionadas.clear();
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
    if (isCheckingEmpleador) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 235, 176, 181),
        appBar: AppBar(
          backgroundColor: const Color(0xFFC5414B),
          elevation: 0,
          title: const Text('Crear Trabajo',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!esEmpleador) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 235, 176, 181),
        appBar: AppBar(
          backgroundColor: const Color(0xFFC5414B),
          elevation: 0,
          title: const Text('Crear Trabajo',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5414B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Color(0xFFC5414B),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Únete a empleadores',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Para crear publicaciones de trabajo necesitas unirte a empleadores',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _irAUnirseEmpleadores,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5414B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'UNIRSE A EMPLEADORES',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Volver',
                    style: TextStyle(
                      color: Color(0xFFC5414B),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isLoadingRubros || isLoadingUbicaciones) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 235, 176, 181),
        appBar: AppBar(
          backgroundColor: const Color(0xFFC5414B),
          elevation: 0,
          title: const Text('Crear Trabajo',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 176, 181),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        title: const Text('Crear Trabajo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              _buildInformacionBasica(),
              const SizedBox(height: 20),
              _buildFechasYHorarios(),
              const SizedBox(height: 20),
              _buildDetallesTrabajo(),
              const SizedBox(height: 20),
              _buildSeccionFotos(), // ✅ SECCIÓN DE FOTOS
              const SizedBox(height: 32),
              PrimaryButton(
                  text: _isUploadingFotos
                      ? 'Subiendo fotos...'
                      : 'Publicar Trabajo',
                  onPressed: (_isUploadingFotos || isLoading)
                      ? () {}
                      : () => _publicarTrabajo(),
                  isLoading: isLoading || _isUploadingFotos),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // ✅ WIDGET DE SECCIÓN DE FOTOS
  // ============================================

  Widget _buildSeccionFotos() {
    return _buildCard('📸 Fotos del trabajo (opcional)', Icons.photo_library, [
      const Text(
        'Agrega hasta 5 fotos para hacer tu publicación más atractiva. La primera foto será la principal.',
        style: TextStyle(fontSize: 13, color: Colors.grey),
      ),
      const SizedBox(height: 16),

      // Contador y botón
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Fotos: ${_fotosSeleccionadas.length}/5',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            onPressed:
                _fotosSeleccionadas.length < 5 ? _seleccionarFotos : null,
            icon: const Icon(Icons.add_photo_alternate, size: 18),
            label: const Text('Agregar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5414B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),

      const SizedBox(height: 16),

      // Grid de fotos
      if (_fotosSeleccionadas.isNotEmpty)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _fotosSeleccionadas.length,
          itemBuilder: (context, index) {
            final foto = _fotosSeleccionadas[index];
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: index == 0
                          ? const Color(0xFFC5414B)
                          : Colors.grey.shade300,
                      width: index == 0 ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(
                            foto.path,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Image.file(
                            File(foto.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),
                ),

                // Badge "PRINCIPAL"
                if (index == 0)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5414B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PRINCIPAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Botón eliminar
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _eliminarFoto(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
    ]);
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142)),
          children: required
              ? [
                  const TextSpan(
                      text: ' *', style: TextStyle(color: Color(0xFFC5414B)))
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFC5414B), Color(0xFFE85A4F)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFC5414B).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Publica tu Trabajo',
              style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
              'Completa todos los detalles para atraer a los mejores candidatos',
              style: TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildInformacionBasica() {
    return _buildCard('Información básica', Icons.work_outline, [
      _buildFieldLabel('Título del trabajo', required: true),
      TextFormField(
          controller: tituloController,
          validator: _validarTitulo,
          decoration: _inputDecoration('Ej: Mozo para evento')),
      const SizedBox(height: 16),
      _buildFieldLabel('Descripción del trabajo', required: true),
      TextFormField(
          controller: descripcionController,
          validator: _validarDescripcion,
          maxLines: 4,
          decoration: _inputDecoration(
              'Describe el trabajo, logística y capacidades requeridas')),
      const SizedBox(height: 16),
      _buildFieldLabel('Categoría', required: true),
      DropdownButtonFormField<String>(
        value: selectedRubro,
        items: rubros
            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
            .toList(),
        onChanged: (val) => setState(() => selectedRubro = val),
        decoration: _inputDecoration('Selecciona una categoría'),
        validator: (val) => val == null ? 'Selecciona una categoría' : null,
      ),
    ]);
  }

  Widget _buildFechasYHorarios() {
    return _buildCard('Fechas y horarios', Icons.schedule_outlined, [
      _buildFechasSection(),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('Horario de inicio', required: true),
                GestureDetector(
                  onTap: () => _seleccionarHora(
                    horarioInicioController,
                    abrirSiguiente: true,
                    esHoraInicio: true,
                  ),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: horarioInicioController,
                      decoration: _inputDecoration('08:30').copyWith(
                          suffixIcon: const Icon(Icons.access_time,
                              color: Color(0xFFC5414B))),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('Horario de fin', required: true),
                GestureDetector(
                  onTap: () => _seleccionarHora(
                    horarioFinController,
                    esHoraInicio: false,
                  ),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: horarioFinController,
                      decoration: _inputDecoration('17:00').copyWith(
                          suffixIcon: const Icon(Icons.access_time,
                              color: Color(0xFFC5414B))),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildDetallesTrabajo() {
    return _buildCard('Detalles del trabajo', Icons.info_outline, [
      _buildFieldLabel('Cantidad de empleados', required: true),
      DropdownButtonFormField<int>(
        value: cantidadSeleccionada,
        items: List.generate(10, (i) => i + 1)
            .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
            .toList(),
        onChanged: (val) => setState(() {
          cantidadSeleccionada = val;
          if (!sinPrecio) salarioController.clear();
          // Reset el switch si cambia a 1 persona
          if (val == 1) {
            permiteInicioIncompleto = false;
          }
        }),
        decoration: _inputDecoration('Selecciona'),
        validator: (val) => val == null ? 'Requerido' : null,
      ),

      const SizedBox(height: 20),

      // ✅ NUEVO: Switch para permitir inicio incompleto
      if (cantidadSeleccionada != null && cantidadSeleccionada! > 1) ...[
        const Text(
          '¿Permitir inicio con cupos incompletos?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: permiteInicioIncompleto
                ? const Color(0xFFC5414B).withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: permiteInicioIncompleto
                  ? const Color(0xFFC5414B)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permiteInicioIncompleto
                          ? 'Sí, puede iniciar sin llenar todos los cupos'
                          : 'No, debe esperar a que se llenen todos los cupos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: permiteInicioIncompleto
                            ? const Color(0xFFC5414B)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      permiteInicioIncompleto
                          ? 'El trabajo puede comenzar aunque no se acepten todos los postulantes'
                          : 'Debes aceptar exactamente $cantidadSeleccionada persona(s) antes de que comience',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: permiteInicioIncompleto,
                onChanged: (value) {
                  setState(() {
                    permiteInicioIncompleto = value;
                  });
                },
                activeColor: const Color(0xFFC5414B),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],

      _buildFieldLabel(
          cantidadSeleccionada == null
              ? 'Precio'
              : (cantidadSeleccionada == 1
                  ? 'Precio del trabajo'
                  : 'Precio por trabajador'),
          required: !sinPrecio),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: salarioController,
              enabled: cantidadSeleccionada != null && !sinPrecio,
              keyboardType: TextInputType.number,
              validator: _validarSalario,
              decoration: _inputDecoration(cantidadSeleccionada == null
                  ? 'Selecciona cantidad primero'
                  : (periodoPagoSeleccionado == null
                      ? 'Selecciona período abajo'
                      : _getSalarioHint())),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => setState(() {
              sinPrecio = !sinPrecio;
              if (sinPrecio) {
                salarioController.clear();
                // ✅ AGREGAR VALORES POR DEFECTO
                if (selectedMetodoPago == null) {
                  selectedMetodoPago = 'EFECTIVO';
                }
                if (periodoPagoSeleccionado == null &&
                    fechasSeleccionadas.isNotEmpty) {
                  periodoPagoSeleccionado = fechasSeleccionadas.length > 1
                      ? 'POR_DIA'
                      : 'POR_TRABAJO';
                }
              }
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  sinPrecio ? const Color(0xFFC5414B) : Colors.grey.shade300,
              foregroundColor: sinPrecio ? Colors.white : Colors.black87,
            ),
            child: Text(sinPrecio ? 'Con precio' : 'Sin precio'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (fechasSeleccionadas.isNotEmpty) ...[
        _buildFieldLabel('Período de pago', required: true),
        _buildPeriodoPagoSelector(),
        const SizedBox(height: 16),
      ],
      _buildFieldLabel('Ubicación', required: true),
      _buildUbicacionDropdown(),
      const SizedBox(height: 16),
      _buildFieldLabel('Método de pago', required: true),
      DropdownButtonFormField<String>(
        value: selectedMetodoPago,
        items: metodosPago
            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
            .toList(),
        onChanged: (val) => setState(() => selectedMetodoPago = val),
        decoration: _inputDecoration('Selecciona'),
        validator: (val) => val == null ? 'Requerido' : null,
      ),
    ]);
  }

  Widget _buildPeriodoPagoSelector() {
    if (esRangoDias) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Has seleccionado ${fechasSeleccionadas.length} días de trabajo',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPeriodoButton(
                  'Por Hora',
                  'POR_HORA',
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPeriodoButton(
                  'Por Día',
                  'POR_DIA',
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trabajo de un solo día',
                    style:
                        TextStyle(fontSize: 13, color: Colors.green.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPeriodoButton(
                  'Por Hora',
                  'POR_HORA',
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPeriodoButton(
                  'Trabajo Completo',
                  'POR_TRABAJO',
                  Icons.wb_sunny,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildPeriodoButton(String label, String value, IconData icon) {
    final isSelected = periodoPagoSeleccionado == value;
    return GestureDetector(
      onTap: () => setState(() => periodoPagoSeleccionado = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC5414B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFC5414B) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: const Color(0xFFC5414B).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFFC5414B),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF2D3142),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSalarioHint() {
    if (periodoPagoSeleccionado == null) {
      return 'Selecciona período primero';
    }
    switch (periodoPagoSeleccionado) {
      case 'POR_HORA':
        return 'Precio por hora en \$';
      case 'POR_DIA':
        return 'Precio por día en \$';
      case 'POR_TRABAJO':
        return 'Precio por trabajo completo en \$';
      default:
        return 'Precio en \$';
    }
  }

  Widget _buildCard(String titulo, IconData icono, List<Widget> children) {
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icono, color: const Color(0xFFC5414B), size: 24),
            const SizedBox(width: 10),
            Text(titulo,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoUbicaciones() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFFC5414B), Color(0xFFE85A4F)]),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: Text('Seleccionar Ubicación',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))),
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _ubicaciones.length,
                  itemBuilder: (context, index) {
                    final ubicacion = _ubicaciones[index];
                    final isSelected = ubicacionSeleccionada ==
                        ubicacion['id_ubicacion'].toString();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          ubicacionSeleccionada =
                              ubicacion['id_ubicacion'].toString();
                          direccionCompleta =
                              '${ubicacion['calle']} ${ubicacion['numero']}, ${ubicacion['ciudad']}, ${ubicacion['provincia']}';
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFC5414B).withOpacity(0.1)
                              : Colors.white,
                          border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFC5414B)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFFC5414B)
                                          .withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFC5414B)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.home,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${ubicacion['nombre']} - ${ubicacion['ciudad']}',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? const Color(0xFFC5414B)
                                              : Colors.black)),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${ubicacion['calle']} ${ubicacion['numero']}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700)),
                                  Text(
                                      '${ubicacion['ciudad']}, ${ubicacion['provincia']}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: Color(0xFFC5414B), size: 28),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _crearNuevaUbicacion();
                  },
                  icon: const Icon(Icons.add_location),
                  label: const Text('Agregar nueva ubicación'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC5414B),
                    side: const BorderSide(color: Color(0xFFC5414B)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUbicacionDropdown() {
    if (isLoadingUbicaciones) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)),
        child: const Row(children: [
          SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12),
          Text('Cargando...')
        ]),
      );
    }

    if (_ubicaciones.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              const Expanded(child: Text('No tienes ubicaciones guardadas'))
            ]),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _irAAgregarUbicacion,
              icon: const Icon(Icons.add_location),
              label: const Text('Agregar ubicación'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC5414B),
                  side: const BorderSide(color: Color(0xFFC5414B))),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _mostrarDialogoUbicaciones,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  color: ubicacionSeleccionada != null
                      ? const Color(0xFFC5414B)
                      : Colors.grey.shade300,
                  width: ubicacionSeleccionada != null ? 2 : 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on,
                    color: ubicacionSeleccionada != null
                        ? const Color(0xFFC5414B)
                        : Colors.grey.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ubicacionSeleccionada != null
                            ? _ubicaciones.firstWhere((u) =>
                                u['id_ubicacion'].toString() ==
                                ubicacionSeleccionada)['nombre']
                            : 'Seleccionar ubicación',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ubicacionSeleccionada != null
                                ? Colors.black
                                : Colors.grey.shade600),
                      ),
                      if (direccionCompleta != null) ...[
                        const SizedBox(height: 4),
                        Text(direccionCompleta!,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade700)),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
        if (ubicacionSeleccionada == null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Text('Este campo es requerido',
                style: TextStyle(color: Colors.red[700], fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildFechasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildFieldLabel('Fechas del trabajo', required: true),
            const Spacer(),
            TextButton.icon(
                onPressed: _seleccionarFecha,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC5414B))),
            TextButton.icon(
                onPressed: _seleccionarRangoFechas,
                icon: const Icon(Icons.date_range, size: 16),
                label: const Text('Rango'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC5414B))),
          ],
        ),
        const SizedBox(height: 8),
        if (fechasSeleccionadas.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12)),
            child: Text('Debe seleccionar al menos una fecha',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center),
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
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF012345), width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red)),
      disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
