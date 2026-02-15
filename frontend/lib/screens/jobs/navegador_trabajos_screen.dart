// lib/screens/jobs/navegador_trabajos_screen.dart
// ✅ CON FILTROS + BOTÓN CREAR + FONDO ROSADO

import 'package:flutter/material.dart';
import '../../models/menu_perfil/trabajo_model.dart';
import '../../services/menu_perfil/trabajo_service.dart';
import '../../services/postulacion_service.dart';
import '../../services/menu_perfil/ubicacion_service.dart';
import 'detalle_trabajo_screen.dart';
import '../../widgets/trabajo_propio_card.dart';

class NavegadorTrabajosScreen extends StatefulWidget {
  const NavegadorTrabajosScreen({Key? key}) : super(key: key);

  @override
  State<NavegadorTrabajosScreen> createState() =>
      _NavegadorTrabajosScreenState();
}

class _NavegadorTrabajosScreenState extends State<NavegadorTrabajosScreen> {
  final servicio = TrabajoService();
  final UbicacionService _ubicacionService = UbicacionService();

  List<TrabajoModel> trabajos = [];
  List<TrabajoModel> _todosLosTrabajos = [];
  List<Map<String, dynamic>> _ubicaciones = [];

  bool isLoading = true;
  bool mostrandoMisTrabajos = false;
  String? errorMessage;

  // ✅ FILTROS (solo para MIS TRABAJOS)
  String _filtroEstado = 'TODOS';
  String _ordenamiento = 'MAS_NUEVO';
  int? _ubicacionSeleccionada;

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
        result = await servicio.getMisTrabajos();
        final resultUbicaciones =
            await _ubicacionService.getUbicacionesDelUsuario();

        setState(() {
          _todosLosTrabajos = result;
          _ubicaciones = resultUbicaciones;
          isLoading = false;
        });

        _aplicarFiltrosYOrdenamiento();

        print('📋 Cargados ${result.length} de mis trabajos');
      } else {
        result = await servicio.getTrabajos(from: 0, to: 19);

        setState(() {
          trabajos = result;
          isLoading = false;
        });

        print('📋 Cargados ${result.length} trabajos de otros usuarios');
      }
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
      // Resetear filtros al cambiar
      _filtroEstado = 'TODOS';
      _ordenamiento = 'MAS_NUEVO';
      _ubicacionSeleccionada = null;
    });
    _cargarTrabajos();
  }

  void _aplicarFiltrosYOrdenamiento() {
    List<TrabajoModel> resultado = List.from(_todosLosTrabajos);

    // Filtro por estado
    if (_filtroEstado == 'PUBLICADOS') {
      resultado = resultado
          .where((t) =>
              t.estadoPublicacion == EstadoPublicacion.PUBLICADO ||
              t.estadoPublicacion == EstadoPublicacion.EN_PROGRESO)
          .toList();
    } else if (_filtroEstado == 'VENCIDOS') {
      resultado = resultado.where((t) => _estaVencido(t)).toList();
    }

    // Filtro por ubicación
    if (_ubicacionSeleccionada != null) {
      resultado = resultado
          .where((t) => t.ubicacionId == _ubicacionSeleccionada)
          .toList();
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
    final fechaFinNormalizada =
        DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);

    return fechaFinNormalizada.isBefore(hoyNormalizado);
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return DraggableScrollableSheet(
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
                        const Text('🏷️ Estado',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildEstadoChip('TODOS', 'Todos', setModalState),
                        const SizedBox(height: 8),
                        _buildEstadoChip(
                            'PUBLICADOS', 'Publicados', setModalState),
                        const SizedBox(height: 8),
                        _buildEstadoChip('VENCIDOS', 'Vencidos', setModalState),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        const Text('🔢 Ordenar por',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildOrdenamientoChip('MAS_NUEVO', 'Más nuevo primero',
                            Icons.arrow_downward, setModalState),
                        const SizedBox(height: 8),
                        _buildOrdenamientoChip('MAS_VIEJO', 'Más viejo primero',
                            Icons.arrow_upward, setModalState),
                        const SizedBox(height: 8),
                        _buildOrdenamientoChip(
                            'MONTO_MENOR',
                            'Monto: menor a mayor',
                            Icons.attach_money,
                            setModalState),
                        const SizedBox(height: 8),
                        _buildOrdenamientoChip(
                            'MONTO_MAYOR',
                            'Monto: mayor a menor',
                            Icons.money_off,
                            setModalState),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        const Text('📍 Ubicación',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildUbicacionChip(
                            null, 'Todas las ubicaciones', setModalState),
                        const SizedBox(height: 8),
                        ..._ubicaciones.map((ubicacion) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildUbicacionChip(
                              ubicacion['id_ubicacion'],
                              ubicacion['nombre'] ?? 'Sin nombre',
                              setModalState,
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
          );
        },
      ),
    );
  }

  Widget _buildEstadoChip(
      String valor, String label, StateSetter setModalState) {
    final isSelected = _filtroEstado == valor;

    return GestureDetector(
      onTap: () {
        setModalState(() {
          // ✅ Actualiza el modal
          _filtroEstado = valor;
        });
        setState(() {
          // ✅ Actualiza la pantalla principal
          _filtroEstado = valor;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFC5414B).withOpacity(0.1)
              : Colors.grey[100],
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

  Widget _buildOrdenamientoChip(
      String valor, String label, IconData icon, StateSetter setModalState) {
    final isSelected = _ordenamiento == valor;

    return GestureDetector(
      onTap: () {
        setModalState(() {
          // ✅ Actualiza el modal
          _ordenamiento = valor;
        });
        setState(() {
          // ✅ Actualiza la pantalla principal
          _ordenamiento = valor;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFC5414B).withOpacity(0.1)
              : Colors.grey[100],
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

  Widget _buildUbicacionChip(
      int? ubicacionId, String nombre, StateSetter setModalState) {
    final isSelected = _ubicacionSeleccionada == ubicacionId;

    return GestureDetector(
      onTap: () {
        setModalState(() {
          // ✅ Actualiza el modal
          _ubicacionSeleccionada = ubicacionId;
        });
        setState(() {
          // ✅ Actualiza la pantalla principal
          _ubicacionSeleccionada = ubicacionId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFC5414B).withOpacity(0.1)
              : Colors.grey[100],
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
      // ✅ FONDO ROSADO cuando muestra trabajos propios
      backgroundColor: mostrandoMisTrabajos
          ? const Color.fromARGB(255, 235, 176, 181)
          : const Color(0xFFF8F9FA),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarTrabajos,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToggleButton(),

          // ✅ BOTÓN DE FILTROS (solo cuando muestra MIS TRABAJOS)
          if (mostrandoMisTrabajos) _buildFiltrosButton(),

          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      // ✅ BOTÓN FLOTANTE (solo cuando muestra MIS TRABAJOS)
      floatingActionButton: mostrandoMisTrabajos
          ? FloatingActionButton.extended(
              onPressed: () async {
                final resultado =
                    await Navigator.pushNamed(context, '/crear-trabajo');
                if (resultado == true) {
                  _cargarTrabajos();
                }
              },
              backgroundColor: const Color(0xFFC5414B),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Crear Trabajo',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
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
                  color:
                      !mostrandoMisTrabajos ? Colors.white : Colors.transparent,
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

  Widget _buildFiltrosButton() {
    int filtrosActivos = 0;
    if (_filtroEstado != 'TODOS') filtrosActivos++;
    if (_ordenamiento != 'MAS_NUEVO') filtrosActivos++;
    if (_ubicacionSeleccionada != null) filtrosActivos++;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                color: mostrandoMisTrabajos ? Colors.white : Colors.grey[800],
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
                  color: mostrandoMisTrabajos
                      ? Colors.grey[400]
                      : Colors.grey[600],
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
                  ? 'No hay trabajos'
                  : 'No hay trabajos disponibles',
              style: TextStyle(
                fontSize: 16,
                color: mostrandoMisTrabajos ? Colors.white : Colors.grey,
              ),
            ),
            if (mostrandoMisTrabajos) ...[
              const SizedBox(height: 8),
              Text(
                _filtroEstado != 'TODOS' || _ubicacionSeleccionada != null
                    ? 'Prueba con otros filtros'
                    : 'Crea tu primer trabajo',
                style: TextStyle(fontSize: 15, color: Colors.grey[400]),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarTrabajos,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: mostrandoMisTrabajos ? 16 : 12,
          vertical: mostrandoMisTrabajos ? 16 : 8,
        ),
        itemCount: trabajos.length,
        itemBuilder: (context, index) {
          final trabajo = trabajos[index];

          // ✅ SI ES MIS TRABAJOS → USA WIDGET COMPARTIDO
          if (mostrandoMisTrabajos) {
            return TrabajoPropioCard(
              trabajo: trabajo,
              onDeleted: _cargarTrabajos,
            );
          }

          // ✅ SI ES EXPLORAR → USA CARD NORMAL
          return _buildTrabajoAjenoCard(trabajo);
        },
      ),
    );
  }

  // ✅ CARD PARA TRABAJOS AJENOS (explorar)
  Widget _buildTrabajoAjenoCard(TrabajoModel trabajo) {
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
            _buildCardHeader(trabajo),
            _buildCardImage(trabajo),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    trabajo.nombreRubro ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  if (trabajo.fechaInicio != null)
                    _buildFechasHorarios(trabajo),
                  const SizedBox(height: 12),
                  _buildSalario(trabajo),
                  const SizedBox(height: 16),
                  _buildPuestosDisponibles(trabajo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  Icon(Icons.priority_high,
                      size: 12, color: Colors.red.shade700),
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
    // ✅ PRIORIZAR FOTO PRINCIPAL
    final imageUrl = trabajo.fotoPrincipalUrl ?? trabajo.imagenUrl;

    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
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
          if (trabajo.horarioInicio.isNotEmpty) ...[
            const SizedBox(width: 16),
            Icon(Icons.access_time, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Text(
              '${trabajo.horarioInicio} - ${trabajo.horarioFin}',
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
    final cantidadPersonas = trabajo.cantidadEmpleadosRequeridos;
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
              color:
                  disponibles > 0 ? Colors.green.shade200 : Colors.red.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people,
                size: 16,
                color: disponibles > 0
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Puestos: ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: disponibles > 0
                      ? Colors.green.shade900
                      : Colors.red.shade900,
                ),
              ),
              const SizedBox(width: 4),
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
                  color: disponibles > 0
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<int, Map<String, int>> _puestosCache = {};

  Future<Map<String, int>> _obtenerPuestos(int trabajoId) async {
    if (_puestosCache.containsKey(trabajoId)) {
      return _puestosCache[trabajoId]!;
    }

    try {
      final puestos =
          await PostulacionService.obtenerPuestosDisponibles(trabajoId);
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

  String _formatDateRange(DateTime inicio, DateTime? fin) {
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

    String inicioStr = '${inicio.day} ${months[inicio.month - 1]}';

    if (fin != null && fin != inicio) {
      String finStr = '${fin.day} ${months[fin.month - 1]}';
      return '$inicioStr - $finStr';
    }

    return inicioStr;
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
