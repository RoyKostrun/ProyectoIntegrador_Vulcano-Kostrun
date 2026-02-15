// lib/models/mensaje_model.dart

class Mensaje {
  final int idMensaje;
  final int idConversacion;
  final int remitenteId;
  final String contenido;
  final bool leido;
  final DateTime createdAt;

  Mensaje({
    required this.idMensaje,
    required this.idConversacion,
    required this.remitenteId,
    required this.contenido,
    required this.leido,
    required this.createdAt,
  });

  // Factory: Crear desde JSON (respuesta de Supabase)
  factory Mensaje.fromJson(Map<String, dynamic> json) {
    return Mensaje(
      idMensaje: json['id_mensaje'] as int,
      idConversacion: json['id_conversacion'] as int,
      remitenteId: json['remitente_id'] as int,
      contenido: json['contenido'] as String,
      leido: json['leido'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convertir a JSON para insertar en Supabase
  Map<String, dynamic> toJson() {
    return {
      'id_conversacion': idConversacion,
      'remitente_id': remitenteId,
      'contenido': contenido,
      'leido': leido,
      // No incluimos id_mensaje ni created_at porque son autogenerados
    };
  }

  // CopyWith para inmutabilidad
  Mensaje copyWith({
    int? idMensaje,
    int? idConversacion,
    int? remitenteId,
    String? contenido,
    bool? leido,
    DateTime? createdAt,
  }) {
    return Mensaje(
      idMensaje: idMensaje ?? this.idMensaje,
      idConversacion: idConversacion ?? this.idConversacion,
      remitenteId: remitenteId ?? this.remitenteId,
      contenido: contenido ?? this.contenido,
      leido: leido ?? this.leido,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Mensaje(id: $idMensaje, conversacion: $idConversacion, remitente: $remitenteId, leido: $leido)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mensaje && other.idMensaje == idMensaje;
  }

  @override
  int get hashCode => idMensaje.hashCode;
}