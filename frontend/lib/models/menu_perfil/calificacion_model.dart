// lib/models/calificacion_model.dart

class CalificacionModel {
  final int idCalificacion;
  final int idPublicacion;
  final int idReceptor;
  final int idEmisor;
  final String rolReceptor;
  final int puntuacion;
  final String? comentario;
  final bool recomendacion;
  final DateTime fecha;
  final String? nombreEmisor;
  final String? fotoEmisor;
  final String? nombreReceptor;
  final String? fotoReceptor;

  CalificacionModel({
    required this.idCalificacion,
    required this.idPublicacion,
    required this.idReceptor,
    required this.idEmisor,
    required this.rolReceptor,
    required this.puntuacion,
    this.comentario,
    required this.recomendacion,
    required this.fecha,
    this.nombreEmisor,
    this.fotoEmisor,
    this.nombreReceptor,
    this.fotoReceptor,
  });

  factory CalificacionModel.fromJson(Map<String, dynamic> json) {
    return CalificacionModel(
      idCalificacion: json['id_calificacion'] ?? 0,
      idPublicacion: json['id_publicacion'] ?? 0,
      idReceptor: json['id_receptor'] ?? 0,
      idEmisor: json['id_emisor'] ?? 0,
      rolReceptor: json['rol_receptor'] ?? '',
      puntuacion: json['puntuacion'] ?? 0,
      comentario: json['comentario'],
      recomendacion: json['recomendacion'] ?? false,
      fecha: DateTime.parse(json['fecha'] ?? DateTime.now().toIso8601String()),
      nombreEmisor: _extractNombre(json, 'emisor'),
      fotoEmisor: _extractFoto(json, 'emisor'),
      nombreReceptor: _extractNombre(json, 'receptor'),
      fotoReceptor: _extractFoto(json, 'receptor'),
    );
  }

  static String? _extractNombre(Map<String, dynamic> json, String tipo) {
    final persona = json['usuario_persona_$tipo'];
    if (persona != null && persona is Map) {
      final nombre = persona['nombre'];
      final apellido = persona['apellido'];
      if (nombre != null && apellido != null) {
        return '$nombre $apellido';
      }
    }

    final empresa = json['usuario_empresa_$tipo'];
    if (empresa != null && empresa is Map) {
      return empresa['nombre_corporativo'];
    }

    return null;
  }

  static String? _extractFoto(Map<String, dynamic> json, String tipo) {
    final persona = json['usuario_persona_$tipo'];
    if (persona != null && persona is Map) {
      return persona['foto_perfil_url'];
    }

    final empresa = json['usuario_empresa_$tipo'];
    if (empresa != null && empresa is Map) {
      return empresa['logo_url'];
    }

    return null;
  }
}

// ✅ Modelo para calificaciones pendientes
class CalificacionPendiente {
  final int idTrabajo;
  final int idPostulacion;
  final String tituloTrabajo;
  final String nombreContraparte;
  final int idContraparte;
  final String rolACalificar;
  final DateTime fechaFinalizacion;

  CalificacionPendiente({
    required this.idTrabajo,
    required this.idPostulacion,
    required this.tituloTrabajo,
    required this.nombreContraparte,
    required this.idContraparte,
    required this.rolACalificar,
    required this.fechaFinalizacion,
  });

  factory CalificacionPendiente.fromJson(Map<String, dynamic> json) {
    return CalificacionPendiente(
      idTrabajo: json['id_trabajo'] ?? 0,
      idPostulacion: json['id_postulacion'] ?? 0,
      tituloTrabajo: json['titulo_trabajo'] ?? '',
      nombreContraparte: json['nombre_contraparte'] ?? 'Usuario',
      idContraparte: json['id_contraparte'] ?? 0,
      rolACalificar: json['rol_a_calificar'] ?? '',
      fechaFinalizacion: DateTime.parse(
        json['fecha_finalizacion'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}