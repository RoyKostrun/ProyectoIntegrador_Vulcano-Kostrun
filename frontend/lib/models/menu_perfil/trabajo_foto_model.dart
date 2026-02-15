// lib/models/trabajo_foto_model.dart
// ✅ Modelo para fotos de trabajos

class TrabajoFoto {
  final int idFoto;
  final int idTrabajo;
  final String fotoUrl;
  final int orden; // 0 = principal, 1-4 = secundarias
  final bool esPrincipal;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrabajoFoto({
    required this.idFoto,
    required this.idTrabajo,
    required this.fotoUrl,
    required this.orden,
    required this.esPrincipal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrabajoFoto.fromJson(Map<String, dynamic> json) {
    return TrabajoFoto(
      idFoto: json['id_foto'],
      idTrabajo: json['id_trabajo'],
      fotoUrl: json['foto_url'],
      orden: json['orden'] ?? 0,
      esPrincipal: json['es_principal'] ?? false,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : json['created_at'] as DateTime,
      updatedAt: json['updated_at'] is String
          ? DateTime.parse(json['updated_at'])
          : json['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_foto': idFoto,
      'id_trabajo': idTrabajo,
      'foto_url': fotoUrl,
      'orden': orden,
      'es_principal': esPrincipal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper: Crear foto para insertar (sin id)
  Map<String, dynamic> toInsertJson() {
    return {
      'id_trabajo': idTrabajo,
      'foto_url': fotoUrl,
      'orden': orden,
      'es_principal': esPrincipal,
    };
  }
}