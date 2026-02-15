// lib/screens/jobs/calificar_trabajo_screen.dart

import 'package:flutter/material.dart';
import '../../models/menu_perfil/calificacion_model.dart';
import '../../services/calificacion_service.dart';

class CalificarTrabajoScreen extends StatefulWidget {
  final CalificacionPendiente calificacionPendiente;

  const CalificarTrabajoScreen({
    Key? key,
    required this.calificacionPendiente,
  }) : super(key: key);

  @override
  State<CalificarTrabajoScreen> createState() => _CalificarTrabajoScreenState();
}

class _CalificarTrabajoScreenState extends State<CalificarTrabajoScreen> {
  int _puntuacion = 0;
  bool _recomendacion = false;
  final _comentarioController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarCalificacion() async {
    if (_puntuacion == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una puntuación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await CalificacionService.crearCalificacion(
        trabajoId: widget.calificacionPendiente.idTrabajo,
        idReceptor: widget.calificacionPendiente.idContraparte,
        rolReceptor: widget.calificacionPendiente.rolACalificar,
        puntuacion: _puntuacion,
        comentario: _comentarioController.text.trim().isEmpty
            ? null
            : _comentarioController.text.trim(),
        recomendacion: _recomendacion,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Calificación enviada correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Volver atrás
        Navigator.pop(context, true); // true = calificación completada
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEmpleador = widget.calificacionPendiente.rolACalificar == 'EMPLEADO';

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
          'Calificar Trabajo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con info del trabajo
            _buildTrabajoInfo(),
            const SizedBox(height: 30),

            // Calificación con estrellas
            _buildCalificacionSection(esEmpleador),
            const SizedBox(height: 30),

            // Comentario
            _buildComentarioSection(),
            const SizedBox(height: 20),

            // Recomendación
            _buildRecomendacionSection(),
            const SizedBox(height: 40),

            // Botón enviar
            _buildEnviarButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTrabajoInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5414B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work,
                  color: Color(0xFFC5414B),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.calificacionPendiente.tituloTrabajo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Finalizado el ${_formatFecha(widget.calificacionPendiente.fechaFinalizacion)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFC5414B),
                child: Text(
                  _getIniciales(widget.calificacionPendiente.nombreContraparte),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.calificacionPendiente.rolACalificar == 'EMPLEADOR'
                          ? 'Calificar a tu empleador'
                          : 'Calificar a tu empleado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.calificacionPendiente.nombreContraparte,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalificacionSection(bool esEmpleador) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo fue tu experiencia?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            esEmpleador
                ? 'Califica el desempeño de tu empleado'
                : 'Califica a tu empleador',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final estrella = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _puntuacion = estrella;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      _puntuacion >= estrella ? Icons.star : Icons.star_border,
                      size: 48,
                      color: _puntuacion >= estrella
                          ? Colors.amber
                          : Colors.grey[400],
                    ),
                  ),
                );
              }),
            ),
          ),
          if (_puntuacion > 0) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                _getTextoCalificacion(_puntuacion),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getColorCalificacion(_puntuacion),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComentarioSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Comentario (opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comentarioController,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Comparte tu experiencia...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC5414B), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecomendacionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Lo recomendarías?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.calificacionPendiente.rolACalificar == 'EMPLEADOR'
                      ? 'Recomendarías este empleador a otros'
                      : 'Recomendarías este empleado a otros',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _recomendacion,
            onChanged: (value) {
              setState(() {
                _recomendacion = value;
              });
            },
            activeColor: const Color(0xFFC5414B),
          ),
        ],
      ),
    );
  }

  Widget _buildEnviarButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _enviarCalificacion,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC5414B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Enviar Calificación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _getTextoCalificacion(int puntuacion) {
    switch (puntuacion) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }

  Color _getColorCalificacion(int puntuacion) {
    if (puntuacion <= 2) return Colors.red;
    if (puntuacion == 3) return Colors.orange;
    return Colors.green;
  }

  String _getIniciales(String nombre) {
    if (nombre.isEmpty) return 'U';
    final palabras = nombre.split(' ');
    if (palabras.length >= 2) {
      return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
    }
    return nombre[0].toUpperCase();
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}