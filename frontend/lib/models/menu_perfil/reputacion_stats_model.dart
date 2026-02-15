// lib/models/reputacion_stats_model.dart

class ReputacionStats {
  final double promedioCalificaciones;
  final int totalCalificaciones;
  final int totalTrabajosFinalizados;
  final Map<int, int> distribucionEstrellas;
  final List<ComentarioCalificacion> comentariosRecientes;
  final Map<String, ReputacionPorRubro>? desglosePorRubro; // ✅ NUEVO: Solo para empleados

  ReputacionStats({
    required this.promedioCalificaciones,
    required this.totalCalificaciones,
    required this.totalTrabajosFinalizados,
    required this.distribucionEstrellas,
    required this.comentariosRecientes,
    this.desglosePorRubro,
  });
}

// ✅ NUEVO: Estadísticas por rubro/tipo de trabajo
class ReputacionPorRubro {
  final String nombreRubro;
  final double promedioCalificaciones;
  final int totalCalificaciones;
  final int totalTrabajosRealizados;

  ReputacionPorRubro({
    required this.nombreRubro,
    required this.promedioCalificaciones,
    required this.totalCalificaciones,
    required this.totalTrabajosRealizados,
  });
}

class ComentarioCalificacion {
  final int idCalificacion;
  final String nombreEmisor;
  final String? fotoEmisor;
  final int puntuacion;
  final String? comentario;
  final bool recomendacion;
  final DateTime fecha;
  final String? tituloTrabajo;
  final String? nombreRubro; // ✅ NUEVO: Para saber en qué rubro trabajó

  ComentarioCalificacion({
    required this.idCalificacion,
    required this.nombreEmisor,
    this.fotoEmisor,
    required this.puntuacion,
    this.comentario,
    required this.recomendacion,
    required this.fecha,
    this.tituloTrabajo,
    this.nombreRubro,
  });

  factory ComentarioCalificacion.fromJson(Map<String, dynamic> json) {
    return ComentarioCalificacion(
      idCalificacion: json['id_calificacion'] ?? 0,
      nombreEmisor: json['nombre_emisor'] ?? 'Usuario',
      fotoEmisor: json['foto_emisor'],
      puntuacion: json['puntuacion'] ?? 0,
      comentario: json['comentario'],
      recomendacion: json['recomendacion'] ?? false,
      fecha: DateTime.parse(json['fecha'] ?? DateTime.now().toIso8601String()),
      tituloTrabajo: json['titulo_trabajo'],
      nombreRubro: json['nombre_rubro'],
    );
  }
}