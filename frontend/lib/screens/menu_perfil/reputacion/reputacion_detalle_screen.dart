// lib/screens/menu_perfil/reputacion_detalle_screen.dart

import 'package:flutter/material.dart';
import '../../../services/calificacion_service.dart';
import '../../../models/menu_perfil/reputacion_stats_model.dart';
import '../../../services/auth_service.dart';

class ReputacionDetalleScreen extends StatefulWidget {
  final String rol; // 'EMPLEADOR' o 'EMPLEADO'

  const ReputacionDetalleScreen({
    Key? key,
    required this.rol,
  }) : super(key: key);

  @override
  State<ReputacionDetalleScreen> createState() => _ReputacionDetalleScreenState();
}

class _ReputacionDetalleScreenState extends State<ReputacionDetalleScreen> {
  bool _isLoading = true;
  ReputacionStats? _stats;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _isLoading = true);
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) return;

      final stats = await CalificacionService.obtenerEstadisticasReputacionPorRol(
        usuarioId: userData.idUsuario,
        rol: widget.rol,
      );

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando estadísticas: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEmpleador = widget.rol == 'EMPLEADOR';
    final titulo = esEmpleador ? 'Reputación como Empleador' : 'Reputación como Empleado';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titulo,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
              ),
            )
          : _stats == null
              ? const Center(child: Text('Error cargando datos'))
              : RefreshIndicator(
                  onRefresh: _cargarEstadisticas,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResumenCard(),
                        const SizedBox(height: 20),
                        _buildDistribucionEstrellas(),
                        
                        // ✅ AQUÍ VA EL IF - DENTRO DE children
                        if (widget.rol == 'EMPLEADO' && 
                            _stats!.desglosePorRubro != null && 
                            _stats!.desglosePorRubro!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildDesglosePorRubro(),
                        ],
                        
                        const SizedBox(height: 20),
                        _buildComentarios(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildResumenCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC5414B), Color(0xFFE85A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5414B).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _stats!.promedioCalificaciones.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < _stats!.promedioCalificaciones.floor()
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
                size: 28,
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                '${_stats!.totalCalificaciones}',
                'Calificaciones',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatColumn(
                '${_stats!.totalTrabajosFinalizados}',
                widget.rol == 'EMPLEADOR' ? 'Trabajos Publicados' : 'Trabajos Realizados',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDistribucionEstrellas() {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución de Calificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) {
            final estrellas = 5 - index;
            final cantidad = _stats!.distribucionEstrellas[estrellas] ?? 0;
            final porcentaje = _stats!.totalCalificaciones > 0
                ? (cantidad / _stats!.totalCalificaciones) * 100
                : 0.0;

            return _buildBarraEstrellas(estrellas, cantidad, porcentaje);
          }),
        ],
      ),
    );
  }

  Widget _buildDesglosePorRubro() {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reputación por Tipo de Trabajo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_stats!.desglosePorRubro!.length, (index) {
            final entry = _stats!.desglosePorRubro!.entries.elementAt(index);
            final stats = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.nombreRubro,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stats.totalTrabajosRealizados} trabajo${stats.totalTrabajosRealizados != 1 ? 's' : ''} realizado${stats.totalTrabajosRealizados != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            stats.promedioCalificaciones.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                        ],
                      ),
                      Text(
                        '${stats.totalCalificaciones} valoración${stats.totalCalificaciones != 1 ? 'es' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBarraEstrellas(int estrellas, int cantidad, double porcentaje) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Row(
              children: [
                Text(
                  '$estrellas',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, color: Colors.amber, size: 16),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: porcentaje / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5414B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              '$cantidad',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComentarios() {
    if (_stats!.comentariosRecientes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes comentarios',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comentarios Recientes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_stats!.comentariosRecientes.length, (index) {
          final comentario = _stats!.comentariosRecientes[index];
          return _buildComentarioCard(comentario);
        }),
      ],
    );
  }

  Widget _buildComentarioCard(ComentarioCalificacion comentario) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFC5414B).withOpacity(0.1),
                child: Text(
                  comentario.nombreEmisor[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFC5414B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comentario.nombreEmisor,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < comentario.puntuacion
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comentario.comentario != null) ...[
            const SizedBox(height: 12),
            Text(
              comentario.comentario!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}