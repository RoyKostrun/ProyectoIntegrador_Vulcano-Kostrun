import 'package:flutter/material.dart';
import '../models/trabajo_model.dart';
import '../theme/estado_trabajo_style.dart';

class EstadoTrabajoBadge extends StatelessWidget {
  final TrabajoModel trabajo;
  final bool mostrarSiempre;

  const EstadoTrabajoBadge({
    Key? key,
    required this.trabajo,
    this.mostrarSiempre = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!mostrarSiempre &&
        trabajo.estadoPublicacion == EstadoPublicacion.PUBLICADO) {
      return const SizedBox.shrink();
    }

    final style = EstadoTrabajoStyle.fromEstado(trabajo.estadoPublicacion);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: style.color.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icono, size: 16, color: style.color),
          const SizedBox(width: 6),
          Text(
            style.texto.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: style.color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
