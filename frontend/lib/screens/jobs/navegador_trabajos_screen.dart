//lib/screens/jobs/navegador_trabajos_screen.dart
import 'package:flutter/material.dart';
import '../../models/trabajo_model.dart';
import '../../services/trabajo_service.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navegar a detalle del trabajo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Detalle del trabajo próximamente'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trabajo.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(trabajo.estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getEstadoLabel(trabajo.estado),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getEstadoColor(trabajo.estado),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
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
              
              const SizedBox(height: 12),
              
              // Rubro y Ubicación
              Row(
                children: [
                  Icon(Icons.category, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    trabajo.nombreRubro,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trabajo.nombreUbicacion,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Footer con urgencia y salario
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getUrgenciaColor(trabajo.urgencia).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trabajo.urgencia.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getUrgenciaColor(trabajo.urgencia),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trabajo.metodoPago,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    trabajo.salario != null 
                        ? '\$${trabajo.salario!.toStringAsFixed(0)}' 
                        : 'A convenir',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}