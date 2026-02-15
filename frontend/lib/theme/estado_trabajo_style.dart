// lib/theme/estado_trabajo_style.dart

import 'package:flutter/material.dart';
import '../models/menu_perfil/trabajo_model.dart';

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
          color: const Color(0xFF4CAF50), // ✅ Verde (igual que trabajo_model)
          icono: Icons.public,              // ✅ Mismo ícono
          texto: 'PUBLICADO',              // ✅ Mismo texto
        );

      case EstadoPublicacion.COMPLETO:
        return EstadoTrabajoStyle(
          color: const Color(0xFF2196F3), // ✅ Azul
          icono: Icons.people,             // ✅ Mismo ícono
          texto: 'COMPLETO',
        );

      case EstadoPublicacion.EN_PROGRESO:
        return EstadoTrabajoStyle(
          color: const Color(0xFFFF9800), // ✅ Naranja
          icono: Icons.work,               // ✅ Mismo ícono
          texto: 'EN PROGRESO',
        );

      case EstadoPublicacion.FINALIZADO:
        return EstadoTrabajoStyle(
          color: const Color(0xFF388E3C), // ✅ Verde oscuro/Teal
          icono: Icons.check_circle,       // ✅ Mismo ícono
          texto: 'FINALIZADO',
        );

      case EstadoPublicacion.VENCIDO:
        return EstadoTrabajoStyle(
          color: const Color(0xFFF44336), // ✅ Rojo (igual que trabajo_model)
          icono: Icons.event_busy,         // ✅ Mismo ícono
          texto: 'VENCIDO',
        );

      case EstadoPublicacion.CANCELADO:
        return EstadoTrabajoStyle(
          color: const Color(0xFF9E9E9E), // ✅ Gris
          icono: Icons.cancel,             // ✅ Mismo ícono
          texto: 'CANCELADO',
        );
    }
  }
}