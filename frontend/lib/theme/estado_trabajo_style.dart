// lib/theme/estado_trabajo_style.dart
import 'package:flutter/material.dart';
import '../models/trabajo_model.dart';

class EstadoTrabajoStyle {
  final Color color;
  final IconData icono;
  final String texto;

  EstadoTrabajoStyle({
    required this.color,
    required this.icono,
    required this.texto,
  });

  static EstadoTrabajoStyle fromEstado(EstadoPublicacion estado) {
    switch (estado) {
      case EstadoPublicacion.PUBLICADO:
        return EstadoTrabajoStyle(
          color: Colors.green,
          icono: Icons.check_circle,
          texto: 'Publicado',
        );

      case EstadoPublicacion.COMPLETO:
        return EstadoTrabajoStyle(
          color: Colors.blue,
          icono: Icons.people_alt_rounded,
          texto: 'Completo',
        );

      case EstadoPublicacion.EN_PROGRESO:
        return EstadoTrabajoStyle(
          color: Colors.orange,
          icono: Icons.work_history,
          texto: 'En progreso',
        );

      case EstadoPublicacion.FINALIZADO:
        return EstadoTrabajoStyle(
          color: Colors.teal,
          icono: Icons.done_all_rounded,
          texto: 'Finalizado',
        );

      case EstadoPublicacion.VENCIDO:
        return EstadoTrabajoStyle(
          color: Colors.red,
          icono: Icons.event_busy,
          texto: 'Vencido',
        );

      case EstadoPublicacion.CANCELADO:
        return EstadoTrabajoStyle(
          color: Colors.grey,
          icono: Icons.cancel,
          texto: 'Cancelado',
        );
    }
  }
}
