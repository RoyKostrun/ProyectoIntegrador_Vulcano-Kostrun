// lib/models/nota_model.dart

class NotaModel {
  final int? idNotas;
  final int idUsuario;
  final String titulo;
  final String contenido;
  final DateTime fechaCreacion;
  final DateTime fechaModificacion;

  NotaModel({
    this.idNotas,
    required this.idUsuario,
    required this.titulo,
    required this.contenido,
    required this.fechaCreacion,
    required this.fechaModificacion,
  });

  factory NotaModel.fromJson(Map<String, dynamic> json) {
    return NotaModel(
      idNotas: json['id_notas'],
      idUsuario: json['id_usuario'],
      titulo: json['titulo'] ?? '',
      contenido: json['contenido'] ?? '',
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaModificacion: DateTime.parse(json['fecha_modificacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idNotas != null) 'id_notas': idNotas,
      'id_usuario': idUsuario,
      'titulo': titulo,
      'contenido': contenido,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_modificacion': fechaModificacion.toIso8601String(),
    };
  }

  NotaModel copyWith({
    int? idNotas,
    int? idUsuario,
    String? titulo,
    String? contenido,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return NotaModel(
      idNotas: idNotas ?? this.idNotas,
      idUsuario: idUsuario ?? this.idUsuario,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
    );
  }
}