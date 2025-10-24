// lib/screens/jobs/postulaciones_trabajo_screen.dart

import 'package:flutter/material.dart';
import '../../models/postulacion_model.dart';
import '../../services/postulacion_service.dart';

class PostulacionesTrabajoScreen extends StatefulWidget {
  final int trabajoId;
  
  const PostulacionesTrabajoScreen({
    Key? key,
    required this.trabajoId,
  }) : super(key: key);

  @override
  State<PostulacionesTrabajoScreen> createState() => _PostulacionesTrabajoScreenState();
}

class _PostulacionesTrabajoScreenState extends State<PostulacionesTrabajoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PostulacionModel> _todasPostulaciones = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarPostulaciones();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarPostulaciones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final postulaciones = await PostulacionService.getPostulacionesDeTrabajo(
        widget.trabajoId,
      );

      setState(() {
        _todasPostulaciones = postulaciones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<PostulacionModel> _filtrarPorEstado(String? estado) {
    if (estado == null) return _todasPostulaciones;
    return _todasPostulaciones
        .where((p) => p.estado.toUpperCase() == estado.toUpperCase())
        .toList();
  }

  int _contarPorEstado(String estado) {
    return _todasPostulaciones
        .where((p) => p.estado.toUpperCase() == estado.toUpperCase())
        .length;
  }

  Future<void> _aceptarPostulacion(PostulacionModel postulacion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceptar postulante'),
        content: Text(
          '¿Confirmas que quieres aceptar a ${postulacion.postulante?.nombre ?? "este postulante"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        await PostulacionService.aceptarPostulacion(postulacion.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Postulante aceptado'),
            backgroundColor: Colors.green,
          ),
        );
        
        _cargarPostulaciones();
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

  Future<void> _rechazarPostulacion(PostulacionModel postulacion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar postulante'),
        content: Text(
          '¿Confirmas que quieres rechazar a ${postulacion.postulante?.nombre ?? "este postulante"}?',
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
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        await PostulacionService.rechazarPostulacion(postulacion.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Postulante rechazado'),
            backgroundColor: Colors.orange,
          ),
        );
        
        _cargarPostulaciones();
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
          'Postulaciones',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarPostulaciones,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'Todas (${_todasPostulaciones.length})',
            ),
            Tab(
              text: 'Pendientes (${_contarPorEstado('PENDIENTE')})',
            ),
            Tab(
              text: 'Aceptadas (${_contarPorEstado('ACEPTADO')})',
            ),
            Tab(
              text: 'Rechazadas (${_contarPorEstado('RECHAZADO')})',
            ),
          ],
        ),
      ),
      body: _buildBody(),
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
              onPressed: _cargarPostulaciones,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_todasPostulaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay postulaciones aún',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildListaPostulaciones(_filtrarPorEstado(null)),
        _buildListaPostulaciones(_filtrarPorEstado('PENDIENTE')),
        _buildListaPostulaciones(_filtrarPorEstado('ACEPTADO')),
        _buildListaPostulaciones(_filtrarPorEstado('RECHAZADO')),
      ],
    );
  }

  Widget _buildListaPostulaciones(List<PostulacionModel> postulaciones) {
    if (postulaciones.isEmpty) {
      return Center(
        child: Text(
          'No hay postulaciones en esta categoría',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: postulaciones.length,
      itemBuilder: (context, index) {
        return _buildPostulacionCard(postulaciones[index]);
      },
    );
  }

  Widget _buildPostulacionCard(PostulacionModel postulacion) {
    final postulante = postulacion.postulante;
    
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con postulante
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFC5414B),
                  backgroundImage: postulante?.fotoPerfil != null
                      ? NetworkImage(postulante!.fotoPerfil!)
                      : null,
                  child: postulante?.fotoPerfil == null
                      ? Text(
                          postulante?.getIniciales() ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                
                // Info del postulante
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        postulante?.nombre ?? 'Usuario',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (postulante?.puntajePromedio != null)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              postulante!.puntajePromedio!.toStringAsFixed(1),
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
                
                // Badge de estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(postulacion.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    postulacion.getEstadoLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getEstadoColor(postulacion.estado),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Mensaje del postulante
          if (postulacion.mensaje != null && postulacion.mensaje!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.message, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Mensaje:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    postulacion.mensaje!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Fecha de postulación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatFecha(postulacion.fechaPostulacion),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Botones de acción
          if (postulacion.estado.toUpperCase() == 'PENDIENTE')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rechazarPostulacion(postulacion),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _aceptarPostulacion(postulacion),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aceptar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'ACEPTADO':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      case 'CANCELADO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diferencia = now.difference(fecha);
    
    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} minutos';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} horas';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}