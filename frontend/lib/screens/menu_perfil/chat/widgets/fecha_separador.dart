// lib/screens/chat/widgets/fecha_separador.dart

import 'package:flutter/material.dart';

class FechaSeparador extends StatelessWidget {
  final DateTime fecha;

  const FechaSeparador({
    Key? key,
    required this.fecha,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatearFecha(fecha),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatearFecha(DateTime timestamp) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(timestamp);

    if (diferencia.inDays == 0) {
      return 'Hoy';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      const dias = [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo'
      ];
      return dias[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}