// lib/widgets/disponibilidad_badge.dart
import 'package:flutter/material.dart';

/// Widget para mostrar el estado de disponibilidad de forma compacta
/// Útil para mostrar en listas de empleados o en el header del perfil
class DisponibilidadBadge extends StatelessWidget {
  final String disponibilidad;
  final bool mostrarTexto;
  final double size;

  const DisponibilidadBadge({
    Key? key,
    required this.disponibilidad,
    this.mostrarTexto = true,
    this.size = 16,
  }) : super(key: key);

  bool get estaDisponible => disponibilidad == 'ACTIVO';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mostrarTexto ? 12 : 8,
        vertical: mostrarTexto ? 6 : 6,
      ),
      decoration: BoxDecoration(
        color: estaDisponible 
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: estaDisponible 
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: estaDisponible ? Colors.green : Colors.grey,
            ),
          ),
          if (mostrarTexto) ...[
            SizedBox(width: 6),
            Text(
              estaDisponible ? 'Disponible' : 'No Disponible',
              style: TextStyle(
                fontSize: size * 0.8,
                fontWeight: FontWeight.w600,
                color: estaDisponible 
                    ? Colors.green.shade700 
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}