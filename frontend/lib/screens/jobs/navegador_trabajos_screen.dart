//lib/screens/jobs/navegador_trabajos_screen.dart
import 'package:flutter/material.dart';
import '../../models/trabajo_model.dart';
import '../../services/trabajo_service.dart';
import 'detalle_trabajo_screen.dart';
import '../../services/postulacion_service.dart';

class NavegadorTrabajosScreen extends StatefulWidget {
  const NavegadorTrabajosScreen({Key? key}) : super(key: key);

  @override
  State<NavegadorTrabajosScreen> createState() => _NavegadorTrabajosScreenState();
}

class _NavegadorTrabajosScreenState extends State<NavegadorTrabajosScreen> {
  final servicio = TrabajoService();
  List<TrabajoModel> trabajos = [];
  bool isLoading = true;
  bool mostrandoMisTrabajos = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarTrabajos();
  }

  Future<void> _cargarTrabajos() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      List<TrabajoModel> result;
      
      if (mostrandoMisTrabajos) {
        // ✅ CORREGIDO: Cargar MIS trabajos
        result = await servicio.getMisTrabajos(from: 0, to: 19);
        print('📋 Cargados ${result.length} de mis trabajos');
      } else {
        // ✅ CORREGIDO: Cargar trabajos de OTROS
        result = await servicio.getTrabajos(from: 0, to: 19);
        print('📋 Cargados ${result.length} trabajos de otros usuarios');
      }
      
      setState(() {
        trabajos = result;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando trabajos: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar trabajos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleVista() {
    setState(() {
      mostrandoMisTrabajos = !mostrandoMisTrabajos;
    });
    _cargarTrabajos();
  }

  Map<int, Map<String, int>> _puestosCache = {}; // Cache para los puestos

  Future<Map<String, int>> _obtenerPuestos(int trabajoId) async {
    // Si ya está en cache, devolverlo
    if (_puestosCache.containsKey(trabajoId)) {
      return _puestosCache[trabajoId]!;
    }

    try {
      final puestos = await PostulacionService.obtenerPuestosDisponibles(trabajoId);
      _puestosCache[trabajoId] = puestos;
      return puestos;
    } catch (e) {
      print('Error obteniendo puestos: $e');
      return {
        'totales': 1,
        'ocupados': 0,
        'disponibles': 1,
      };
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado.toUpperCase()) {
      case 'PUBLICADO':
        return 'Publicado';
      case 'EN_PROGRESO':
        return 'En Progreso';
      case 'COMPLETADO':
        return 'Completado';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'PUBLICADO':
        return Colors.blue;
      case 'EN_PROGRESO':
        return Colors.orange;
      case 'COMPLETADO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getUrgenciaColor(String urgencia) {
    switch (urgencia.toUpperCase()) {
      case 'ALTA':
        return Colors.red;
      case 'MEDIA':
        return Colors.orange;
      case 'BAJA':
      case 'ESTANDAR':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        title: Text(
          mostrandoMisTrabajos ? 'Mis Trabajos' : 'Explorar Trabajos',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarTrabajos,
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Botón Toggle mejorado
          _buildToggleButton(),
          
          // Contenido de la lista
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (mostrandoMisTrabajos) _toggleVista();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !mostrandoMisTrabajos 
                      ? Colors.white 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: !mostrandoMisTrabajos
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'NAVEGAR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: !mostrandoMisTrabajos 
                          ? Colors.black 
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!mostrandoMisTrabajos) _toggleVista();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: mostrandoMisTrabajos 
                      ? Colors.grey.shade700 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    'MIS TRABAJOS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: mostrandoMisTrabajos 
                          ? Colors.white 
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar trabajos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarTrabajos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5414B),
              ),
            ),
          ],
        ),
      );
    }

    if (trabajos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mostrandoMisTrabajos ? Icons.work_off : Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              mostrandoMisTrabajos 
                  ? 'No tienes trabajos publicados' 
                  : 'No hay trabajos disponibles',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            if (mostrandoMisTrabajos) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navegar a crear trabajo
                  Navigator.pushNamed(context, '/crear-trabajo');
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear Trabajo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5414B),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarTrabajos,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: trabajos.length,
        itemBuilder: (context, index) {
          final trabajo = trabajos[index];
          return _buildTrabajoCard(trabajo);
        },
      ),
    );
  }

  Widget _buildTrabajoCard(TrabajoModel trabajo) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalleTrabajoScreen(trabajo: trabajo),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Header con usuario que publicó
            _buildCardHeader(trabajo),
            
            // ✅ Imagen o placeholder
            _buildCardImage(trabajo),
            
            // ✅ Contenido del card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y categoría
                  Text(
                    trabajo.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trabajo.nombreRubro,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Descripción
                  Text(
                    trabajo.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ✅ Fechas y horarios
                  if (trabajo.fechaInicio != null || trabajo.horarioInicio != null)
                    _buildFechasHorarios(trabajo),
                  
                  const SizedBox(height: 12),
                  
                  // ✅ Salario
                  _buildSalario(trabajo),
                  
                  const SizedBox(height: 16),
                  
                  // ✅ Puestos disponibles (emojis)
                  _buildPuestosDisponibles(trabajo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // WIDGETS AUXILIARES DEL CARD
  // ========================================

  Widget _buildCardHeader(TrabajoModel trabajo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFC5414B),
            child: Text(
              trabajo.nombreEmpleador?.substring(0, 1).toUpperCase() ?? 'E',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Publicado por',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  trabajo.nombreEmpleador ?? 'Usuario',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Badge de urgencia si aplica
          if (trabajo.urgencia.toUpperCase() == 'ALTA')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.priority_high, size: 12, color: Colors.red.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Urgente',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardImage(TrabajoModel trabajo) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        image: trabajo.imagenUrl != null
            ? DecorationImage(
                image: NetworkImage(trabajo.imagenUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: trabajo.imagenUrl == null
          ? Center(
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: Colors.grey[500],
              ),
            )
          : null,
    );
  }

  Widget _buildFechasHorarios(TrabajoModel trabajo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          if (trabajo.fechaInicio != null) ...[
            Icon(Icons.calendar_today, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Text(
              _formatDateRange(trabajo.fechaInicio, trabajo.fechaFin),
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (trabajo.horarioInicio != null) ...[
            const SizedBox(width: 16),
            Icon(Icons.access_time, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Text(
              '${trabajo.horarioInicio} - ${trabajo.horarioFin ?? ""}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalario(TrabajoModel trabajo) {
    final cantidadPersonas = trabajo.cantidadEmpleadosRequeridos ?? 1;
    final esPorPersona = cantidadPersonas > 1;
    
    return Row(
      children: [
        Icon(Icons.payments, size: 18, color: Colors.green[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            trabajo.salario != null
                ? '\$${trabajo.salario!.toStringAsFixed(0)} ${_getPeriodoLabel(trabajo.periodoPago)}${esPorPersona ? " c/u" : ""}'
                : 'Salario a convenir',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPuestosDisponibles(TrabajoModel trabajo) {
    return FutureBuilder<Map<String, int>>(
      future: _obtenerPuestos(trabajo.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 24,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final puestos = snapshot.data!;
        final totales = puestos['totales']!;
        final ocupados = puestos['ocupados']!;
        final disponibles = puestos['disponibles']!;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: disponibles > 0 ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: disponibles > 0 ? Colors.green.shade200 : Colors.red.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people,
                size: 16,
                color: disponibles > 0 ? Colors.green.shade700 : Colors.red.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Puestos: ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: disponibles > 0 ? Colors.green.shade900 : Colors.red.shade900,
                ),
              ),
              const SizedBox(width: 4),
              // ✅ EMOJIS DE PUESTOS
              ...List.generate(
                totales,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    index < ocupados ? '👤' : '⚪',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($ocupados/$totales)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: disponibles > 0 ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========================================
  // HELPERS
  // ========================================

  String _formatDateRange(String? inicio, String? fin) {
    if (inicio == null) return 'Fecha no especificada';
    
    try {
      final fechaInicio = DateTime.parse(inicio);
      final fechaFin = fin != null ? DateTime.parse(fin) : null;
      
      final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      
      String inicioStr = '${fechaInicio.day} ${months[fechaInicio.month - 1]}';
      
      if (fechaFin != null && fechaFin != fechaInicio) {
        String finStr = '${fechaFin.day} ${months[fechaFin.month - 1]}';
        return '$inicioStr - $finStr';
      }
      
      return inicioStr;
    } catch (e) {
      return inicio;
    }
  }

  String _getPeriodoLabel(String? periodo) {
    switch (periodo?.toUpperCase()) {
      case 'POR_HORA':
        return 'por hora';
      case 'POR_DIA':
        return 'por día';
      case 'POR_TRABAJO':
        return 'total';
      default:
        return '';
    }
  }
}