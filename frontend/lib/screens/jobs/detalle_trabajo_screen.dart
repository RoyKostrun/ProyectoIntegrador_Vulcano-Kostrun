// lib/screens/jobs/detalle_trabajo_screen.dart
import 'package:flutter/material.dart';
import '../../models/trabajo_model.dart';
import '../../services/trabajo_service.dart';
import '../../services/auth_service.dart';
import '../../services/postulacion_service.dart';
import '../../services/user_service.dart';

class DetalleTrabajoScreen extends StatefulWidget {
  final TrabajoModel trabajo;

  const DetalleTrabajoScreen({
    Key? key,
    required this.trabajo,
  }) : super(key: key);

  @override
  State<DetalleTrabajoScreen> createState() => _DetalleTrabajoScreenState();
}

class _DetalleTrabajoScreenState extends State<DetalleTrabajoScreen> {
  final TrabajoService _trabajoService = TrabajoService();
  final UserService _userService = UserService();
  bool _isPostulating = false;
  bool _isAlreadyPostulated = false;
  bool _isEmpleador = false;
  bool _isEmpleado = false;
  bool _isCheckingEmpleado = true;
  int _cantidadPostulaciones = 0;

  @override
  void initState() {
    super.initState();
    _verificarPostulacion();
    _verificarSiEsEmpleador();
    _verificarSiEsEmpleado();
  }

  Future<void> _verificarSiEsEmpleado() async {
    setState(() => _isCheckingEmpleado = true);
    try {
      final resultado = await _userService.esEmpleado();
      setState(() {
        _isEmpleado = resultado;
        _isCheckingEmpleado = false;
      });
    } catch (e) {
      setState(() => _isCheckingEmpleado = false);
      print('❌ Error al verificar si es empleado: $e');
    }
  }

  Future<void> _irAUnirseEmpleados() async {
    final resultado = await Navigator.pushNamed(context, '/unirse-empleados');
    
    if (resultado == true && mounted) {
      // El usuario se unió exitosamente, recargamos el estado
      await _verificarSiEsEmpleado();
    }
  }

  Future<void> _verificarPostulacion() async {
    try {
      final yaPostulado =
          await PostulacionService.yaEstaPostulado(widget.trabajo.id);
      setState(() => _isAlreadyPostulated = yaPostulado);
    } catch (e) {
      print('Error verificando postulación: $e');
    }
  }

  Future<void> _postularse({String? mensaje}) async {
    if (_isAlreadyPostulated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya te postulaste a este trabajo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isPostulating = true);

    try {
      print('🔵 Iniciando postulación...');

      await PostulacionService.postularse(
        trabajoId: widget.trabajo.id,
        mensaje: mensaje?.isNotEmpty == true ? mensaje : null,
      );

      print('🟢 Postulación exitosa');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ¡Te postulaste exitosamente!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        setState(() => _isAlreadyPostulated = true);
      }
    } catch (e) {
      print('🔴 Error al postularse: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPostulating = false);
      }
    }
  }

  String _getPeriodoPagoLabel(String? periodo) {
    switch (periodo?.toUpperCase()) {
      case 'POR_HORA':
        return 'por hora';
      case 'POR_DIA':
        return 'por día';
      case 'POR_TRABAJO':
        return 'por trabajo completo';
      default:
        return '';
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
          'Detalle del Trabajo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Compartir'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Reportar'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Función $value próximamente')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildQuickStats(),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildSection(
                          '📝 Descripción',
                          widget.trabajo.descripcion,
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildFechasHorarios(),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildDetallesPago(),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildUbicacion(),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildPublicadoPor(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        image: widget.trabajo.imagenUrl != null
            ? DecorationImage(
                image: NetworkImage(widget.trabajo.imagenUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: widget.trabajo.imagenUrl == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 64, color: Colors.grey[500]),
                  const SizedBox(height: 8),
                  Text(
                    'Sin imagen',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.trabajo.titulo,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.business, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              widget.trabajo.nombreRubro,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Color(0xFFC5414B)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.trabajo.direccionCompleta,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            icon: Icons.payments,
            label: widget.trabajo.salario != null
                ? '\$${widget.trabajo.salario!.toStringAsFixed(0)}'
                : 'A convenir',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatChip(
            icon: Icons.people,
            label: '${widget.trabajo.cantidadEmpleadosRequeridos ?? 1}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatChip(
            icon: Icons.schedule,
            label: _getDiasRestantes(),
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getDiasRestantes() {
    if (widget.trabajo.fechaInicio == null) return 'N/A';

    final now = DateTime.now();
    final inicio = DateTime.parse(widget.trabajo.fechaInicio!);
    final diferencia = inicio.difference(now).inDays;

    if (diferencia == 0) return 'Hoy';
    if (diferencia == 1) return 'Mañana';
    if (diferencia < 0) return 'Iniciado';
    return 'En $diferencia días';
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFechasHorarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📅 Fechas y Horarios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
            Icons.calendar_today,
            'Fecha inicio',
            widget.trabajo.fechaInicio != null
                ? _formatDate(widget.trabajo.fechaInicio!)
                : 'No especificada'),
        _buildInfoRow(
            Icons.event,
            'Fecha fin',
            widget.trabajo.fechaFin != null
                ? _formatDate(widget.trabajo.fechaFin!)
                : 'No especificada'),
        _buildInfoRow(Icons.access_time, 'Horario',
            '${widget.trabajo.horarioInicio ?? 'N/A'} - ${widget.trabajo.horarioFin ?? 'N/A'}'),
      ],
    );
  }

  Widget _buildDetallesPago() {
    final cantidadPersonas = widget.trabajo.cantidadEmpleadosRequeridos ?? 1;
    final esPorPersona = cantidadPersonas > 1;

    String salarioText;
    if (widget.trabajo.salario != null) {
      final monto = widget.trabajo.salario!.toStringAsFixed(0);
      final periodo = _getPeriodoPagoLabel(widget.trabajo.periodoPago);

      if (esPorPersona) {
        salarioText = '\$$monto $periodo por persona';
      } else {
        salarioText = '\$$monto $periodo';
      }
    } else {
      salarioText = 'A convenir';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💵 Detalles de Pago',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        _buildInfoRow(
          Icons.payments,
          'Salario',
          salarioText,
        ),

        if (esPorPersona && widget.trabajo.salario != null)
          _buildInfoRow(
            Icons.calculate,
            'Total estimado (${cantidadPersonas} personas)',
            '\$${(widget.trabajo.salario! * cantidadPersonas).toStringAsFixed(0)} ${_getPeriodoPagoLabel(widget.trabajo.periodoPago)}',
          ),

        _buildInfoRow(
          Icons.payment,
          'Método de pago',
          widget.trabajo.metodoPago ?? 'No especificado',
        ),

        _buildInfoRow(
          Icons.people,
          'Personas necesarias',
          '$cantidadPersonas',
        ),
      ],
    );
  }

  Widget _buildUbicacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📍 Ubicación',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.trabajo.direccionCompleta,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Mapa próximamente',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPublicadoPor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '👤 Publicado por',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFC5414B),
                child: Text(
                  widget.trabajo.nombreEmpleador
                          ?.substring(0, 1)
                          .toUpperCase() ??
                      'E',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.trabajo.nombreEmpleador ?? 'Empleador',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '4.5 • 12 trabajos',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ver perfil próximamente')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFC5414B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // ✅ SI ES EMPLEADOR DEL TRABAJO, MOSTRAR BOTÓN DE POSTULACIONES
    if (_isEmpleador) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/postulaciones-trabajo',
                arguments: widget.trabajo.id,
              );
            },
            icon: const Icon(Icons.people),
            label: Text(
              _cantidadPostulaciones > 0
                  ? 'Ver postulaciones ($_cantidadPostulaciones)'
                  : 'Sin postulaciones aún',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5414B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      );
    }

    // ✅ LOADING: Verificando si es empleado
    if (_isCheckingEmpleado) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // ✅ SI NO ES EMPLEADO Y NO ES SU TRABAJO, MOSTRAR BOTÓN DE UNIRSE
    // IMPORTANTE: Solo mostrar si NO es el empleador del trabajo
    if (!_isEmpleado && !_isEmpleador) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Únete como empleado para postularte',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _irAUnirseEmpleados,
                icon: const Icon(Icons.person_add),
                label: const Text('UNIRSE COMO EMPLEADO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5414B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ SI ES EMPLEADO Y NO ES SU TRABAJO, MOSTRAR BOTONES NORMALES
    if (_isEmpleado && !_isEmpleador) {
      return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat próximamente')),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Preguntar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC5414B),
                side: const BorderSide(color: Color(0xFFC5414B)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isPostulating || _isAlreadyPostulated 
                    ? null 
                    : _mostrarModalPostulacion,
                icon: Icon(
                  _isAlreadyPostulated ? Icons.check_circle : Icons.work,
                ),
                label: Text(
                  _isAlreadyPostulated 
                      ? 'Ya postulado' 
                      : _isPostulating 
                          ? 'Postulando...' 
                          : '¡Me apunto!',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAlreadyPostulated 
                      ? Colors.green 
                      : const Color(0xFFC5414B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    }

    // ✅ SI ES EMPLEADOR (y potencialmente empleado), no mostrar botones de postulación
    return const SizedBox.shrink();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _mostrarModalPostulacion() async {
    final TextEditingController mensajeController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC5414B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.work_outline,
                color: Color(0xFFC5414B),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¿Postularte a este trabajo?',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.trabajo.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.trabajo.nombreRubro,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Mensaje para el empleador (opcional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: mensajeController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Ej: Tengo 5 años de experiencia en el rubro...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Este mensaje será visible para el empleador',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check),
            label: const Text('Postularme'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5414B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await _postularse(mensaje: mensajeController.text.trim());
    }
  }

  Future<void> _verificarSiEsEmpleador() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      final esEmpleador = widget.trabajo.empleadorId == userId;
      
      if (esEmpleador) {
        final postulaciones = await PostulacionService.getPostulacionesDeTrabajo(
          widget.trabajo.id,
        );
        
        setState(() {
          _isEmpleador = true;
          _cantidadPostulaciones = postulaciones.length;
        });
      }
    } catch (e) {
      print('Error verificando empleador: $e');
    }
  }

}