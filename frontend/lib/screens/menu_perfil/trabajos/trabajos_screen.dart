// lib/screens/user/menu_perfil/trabajos_screen.dart
// ✅ USA WIDGET COMPARTIDO + FILTROS

import 'package:flutter/material.dart';
import '../../../services/menu_perfil/trabajo_service.dart';
import '../../../services/menu_perfil/ubicacion_service.dart';
import '../../../models/menu_perfil/trabajo_model.dart';
import '../../../widgets/trabajo_propio_card.dart';

class TrabajosScreen extends StatefulWidget {
  const TrabajosScreen({Key? key}) : super(key: key);

  @override
  State<TrabajosScreen> createState() => _TrabajosScreenState();
}

class _TrabajosScreenState extends State<TrabajosScreen> {
  final TrabajoService _trabajoService = TrabajoService();
  final UbicacionService _ubicacionService = UbicacionService();
  
  List<TrabajoModel> _todosLosTrabajos = [];
  List<TrabajoModel> trabajos = [];
  List<Map<String, dynamic>> _ubicaciones = [];
  
  bool isLoading = true;
  String? errorMessage;

  // Filtros
  String _filtroEstado = 'TODOS';
  String _ordenamiento = 'MAS_NUEVO';
  int? _ubicacionSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final resultTrabajos = await _trabajoService.getMisTrabajos();
      final resultUbicaciones = await _ubicacionService.getUbicacionesDelUsuario();
      
      setState(() {
        _todosLosTrabajos = resultTrabajos;
        _ubicaciones = resultUbicaciones;
        isLoading = false;
      });
      
      _aplicarFiltrosYOrdenamiento();
      
    } catch (e) {
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

  void _aplicarFiltrosYOrdenamiento() {
    List<TrabajoModel> resultado = List.from(_todosLosTrabajos);

    // Filtro por estado
    if (_filtroEstado == 'PUBLICADOS') {
      resultado = resultado.where((t) => 
        t.estadoPublicacion == EstadoPublicacion.PUBLICADO ||
        t.estadoPublicacion == EstadoPublicacion.EN_PROGRESO
      ).toList();
    } else if (_filtroEstado == 'VENCIDOS') {
      resultado = resultado.where((t) => _estaVencido(t)).toList();
    }

    // Filtro por ubicación
    if (_ubicacionSeleccionada != null) {
      resultado = resultado.where((t) => 
        t.ubicacionId == _ubicacionSeleccionada
      ).toList();
    }

    // Ordenamiento
    switch (_ordenamiento) {
      case 'MAS_NUEVO':
        resultado.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
        break;
      case 'MAS_VIEJO':
        resultado.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
        break;
      case 'MONTO_MENOR':
        resultado.sort((a, b) {
          final montoA = a.salario ?? 0;
          final montoB = b.salario ?? 0;
          return montoA.compareTo(montoB);
        });
        break;
      case 'MONTO_MAYOR':
        resultado.sort((a, b) {
          final montoA = a.salario ?? 0;
          final montoB = b.salario ?? 0;
          return montoB.compareTo(montoA);
        });
        break;
    }

    setState(() {
      trabajos = resultado;
    });
  }

  bool _estaVencido(TrabajoModel trabajo) {
    if (trabajo.estadoPublicacion == EstadoPublicacion.VENCIDO ||
        trabajo.estadoPublicacion == EstadoPublicacion.CANCELADO ||
        trabajo.estadoPublicacion == EstadoPublicacion.COMPLETO ||
        trabajo.estadoPublicacion == EstadoPublicacion.FINALIZADO) {
      return true;
    }
    
    final fechaFin = trabajo.fechaFin ?? trabajo.fechaInicio;
    final hoy = DateTime.now();
    final fechaFinNormalizada = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);
    
    return fechaFinNormalizada.isBefore(hoyNormalizado);
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(0, 229, 5, 5),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: Color(0xFFC5414B)),
                    const SizedBox(width: 12),
                    const Text(
                      'Filtros y Ordenamiento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filtroEstado = 'TODOS';
                          _ordenamiento = 'MAS_NUEVO';
                          _ubicacionSeleccionada = null;
                        });
                        _aplicarFiltrosYOrdenamiento();
                        Navigator.pop(context);
                      },
                      child: const Text('Limpiar'),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const Text('🏷️ Estado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildEstadoChip('TODOS', 'Todos'),
                    const SizedBox(height: 8),
                    _buildEstadoChip('PUBLICADOS', 'Publicados'),
                    const SizedBox(height: 8),
                    _buildEstadoChip('VENCIDOS', 'Vencidos'),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    const Text('🔢 Ordenar por', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildOrdenamientoChip('MAS_NUEVO', 'Más nuevo primero', Icons.arrow_downward),
                    const SizedBox(height: 8),
                    _buildOrdenamientoChip('MAS_VIEJO', 'Más viejo primero', Icons.arrow_upward),
                    const SizedBox(height: 8),
                    _buildOrdenamientoChip('MONTO_MENOR', 'Monto: menor a mayor', Icons.attach_money),
                    const SizedBox(height: 8),
                    _buildOrdenamientoChip('MONTO_MAYOR', 'Monto: mayor a menor', Icons.money_off),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    const Text('📍 Ubicación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildUbicacionChip(null, 'Todas las ubicaciones'),
                    const SizedBox(height: 8),
                    ..._ubicaciones.map((ubicacion) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildUbicacionChip(
                          ubicacion['id_ubicacion'],
                          ubicacion['nombre'] ?? 'Sin nombre',
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),

              Container(
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
                  child: ElevatedButton(
                    onPressed: () {
                      _aplicarFiltrosYOrdenamiento();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5414B),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Aplicar Filtros',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Widget _buildEstadoChip(String valor, String label) {
    final isSelected = _filtroEstado == valor;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroEstado = valor;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC5414B).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFC5414B) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? const Color(0xFFC5414B) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFC5414B) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdenamientoChip(String valor, String label, IconData icon) {
    final isSelected = _ordenamiento == valor;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _ordenamiento = valor;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC5414B).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFC5414B) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFC5414B) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFC5414B) : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFC5414B),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUbicacionChip(int? ubicacionId, String nombre) {
    final isSelected = _ubicacionSeleccionada == ubicacionId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _ubicacionSeleccionada = ubicacionId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC5414B).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFC5414B) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: isSelected ? const Color(0xFFC5414B) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                nombre,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFFC5414B) : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFC5414B),
              ),
          ],
        ),
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
          'Mis Trabajos',
          style: TextStyle(
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
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltrosButton(),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargarDatos,
              child: _buildBody(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.pushNamed(context, '/crear-trabajo');
          if (resultado == true) {
            _cargarDatos();
          }
        },
        backgroundColor: const Color(0xFFC5414B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Crear Trabajo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFiltrosButton() {
    int filtrosActivos = 0;
    if (_filtroEstado != 'TODOS') filtrosActivos++;
    if (_ordenamiento != 'MAS_NUEVO') filtrosActivos++;
    if (_ubicacionSeleccionada != null) filtrosActivos++;

    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _mostrarFiltros,
        icon: Stack(
          children: [
            const Icon(Icons.filter_list, size: 20),
            if (filtrosActivos > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$filtrosActivos',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC5414B),
                    ),
                  ),
                ),
              ),
          ],
        ),
        label: Text(
          filtrosActivos > 0 
              ? 'Filtros ($filtrosActivos)' 
              : 'Filtros y Ordenamiento',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFC5414B),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar trabajos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarDatos,
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
            Icon(Icons.work_off, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 24),
            const Text(
              'No hay trabajos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filtroEstado != 'TODOS' || _ubicacionSeleccionada != null
                  ? 'Prueba con otros filtros'
                  : 'Crea tu primer trabajo',
              style: TextStyle(fontSize: 15, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    // ✅ USA EL WIDGET COMPARTIDO
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trabajos.length,
      itemBuilder: (context, index) {
        return TrabajoPropioCard(
          trabajo: trabajos[index],
          onDeleted: _cargarDatos,
        );
      },
    );
  }
}