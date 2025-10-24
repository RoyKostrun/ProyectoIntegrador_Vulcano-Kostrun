import 'enums.dart';  // ✅ Importar enums

class Postulacion {
  final String id;
  final String trabajoId;
  final String postulanteId;
  final String? mensaje;
  final double? ofertaPago;
  final EstadoPostulacionEnum estado;
  final DateTime fechaPostulacion;
  final String? comentario;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos adicionales para UI (joins)
  final String? nombrePostulante;
  final String? apellidoPostulante;
    final double? ratingPostulante;
    final String? fotoPerfilUrl;

    Postulacion({
      required this.id,
      required this.trabajoId,
      required this.postulanteId,
      this.mensaje,
      this.ofertaPago,
    this.estado = EstadoPostulacionEnum.pendiente,
    required this.fechaPostulacion,
    this.comentario,
    required this.createdAt,
    required this.updatedAt,
    // Campos adicionales
    this.nombrePostulante,
    this.apellidoPostulante,
    this.ratingPostulante,
    this.fotoPerfilUrl,
  });

  factory Postulacion.fromJson(Map<String, dynamic> json) {
    return Postulacion(
      id: json['id_postulacion']?.toString() ?? '',
      trabajoId: json['trabajo_id']?.toString() ?? '',
      postulanteId: json['postulante_id']?.toString() ?? '',
      mensaje: json['mensaje'],
      ofertaPago: json['oferta_pago']?.toDouble(),
      estado: _parseEstadoPostulacion(json['estado']),
      fechaPostulacion: DateTime.parse(json['fecha_postulacion']),
      comentario: json['comentario'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      // Campos adicionales de joins
      nombrePostulante: json['postulante']?['nombre'],
      apellidoPostulante: json['postulante']?['apellido'],
      ratingPostulante: json['postulante']?['puntaje_promedio']?.toDouble(),
      fotoPerfilUrl: json['postulante']?['foto_perfil_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trabajo_id': trabajoId,
      'postulante_id': postulanteId,
      'mensaje': mensaje,
      'oferta_pago': ofertaPago,
      'estado': estado.name.toUpperCase(),
      'comentario': comentario,
    };
  }

  static EstadoPostulacionEnum _parseEstadoPostulacion(String? value) {
    switch (value?.toLowerCase()) {
      case 'aceptado':
        return EstadoPostulacionEnum.aceptado;
      case 'rechazado':
        return EstadoPostulacionEnum.rechazado;
      case 'cancelado':
        return EstadoPostulacionEnum.cancelado;
      default:
        return EstadoPostulacionEnum.pendiente;
    }
  }

  String get nombreCompleto {
    if (nombrePostulante != null && apellidoPostulante != null) {
      return '$nombrePostulante $apellidoPostulante';
    }
    return 'Usuario';
  }
}