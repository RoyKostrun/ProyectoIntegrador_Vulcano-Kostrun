// lib/middleware/calificacion_middleware.dart

import 'package:flutter/material.dart';
import '../services/calificacion_service.dart';
import '../models/menu_perfil/calificacion_model.dart';
import '../screens/jobs/calificar_trabajo_screen.dart';

class CalificacionMiddleware {
  static Future<bool> verificarYMostrarCalificacionesPendientes(
    BuildContext context,
  ) async {
    try {
      print('🔍 Verificando calificaciones pendientes...');
      
      final pendientes = await CalificacionService.obtenerCalificacionesPendientes();
      
      if (pendientes.isEmpty) {
        print('✅ No hay calificaciones pendientes');
        return false; // No hay pendientes
      }

      print('⚠️ ${pendientes.length} calificaciones pendientes encontradas');
      
      // Mostrar diálogo modal que no se puede cerrar
      if (context.mounted) {
        await _mostrarDialogoCalificacionObligatoria(context, pendientes);
      }
      
      return true; // Hay pendientes
    } catch (e) {
      print('❌ Error verificando calificaciones: $e');
      return false;
    }
  }

  static Future<void> _mostrarDialogoCalificacionObligatoria(
    BuildContext context,
    List<CalificacionPendiente> pendientes,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando afuera
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // No se puede cerrar con botón atrás
        child: AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5414B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: Color(0xFFC5414B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Calificaciones Pendientes',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tienes ${pendientes.length} ${pendientes.length == 1 ? 'trabajo finalizado' : 'trabajos finalizados'} pendiente${pendientes.length == 1 ? '' : 's'} de calificar.',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Debes calificar para continuar usando la app',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Cerrar diálogo
                  await _procesarCalificacionesPendientes(context, pendientes);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5414B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Calificar Ahora',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _procesarCalificacionesPendientes(
    BuildContext context,
    List<CalificacionPendiente> pendientes,
  ) async {
    for (int i = 0; i < pendientes.length; i++) {
      final pendiente = pendientes[i];
      
      if (!context.mounted) break;
      
      // Navegar a la pantalla de calificación
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CalificarTrabajoScreen(
            calificacionPendiente: pendiente,
          ),
        ),
      );
      
      // Si canceló o cerró sin calificar, volver a mostrar el diálogo
      if (resultado != true) {
        if (context.mounted) {
          await _mostrarDialogoCalificacionObligatoria(
            context,
            pendientes.sublist(i), // Mostrar solo las que faltan
          );
        }
        break;
      }
    }
    
    // Cuando termine todas las calificaciones, verificar si quedaron más
    if (context.mounted) {
      await verificarYMostrarCalificacionesPendientes(context);
    }
  }
}