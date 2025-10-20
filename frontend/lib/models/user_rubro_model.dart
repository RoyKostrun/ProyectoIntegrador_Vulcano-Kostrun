// lib/models/usuario_rubro.dart
class UsuarioRubro {
  final int? idUsuarioRubro;
  final int idUsuario;
  final int idRubro;
  final DateTime fechaAsignacion;
  final bool activo;

  UsuarioRubro({
    this.idUsuarioRubro,
    required this.idUsuario,
    required this.idRubro,
    required this.fechaAsignacion,
    this.activo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_usuario_rubro': idUsuarioRubro,
      'id_usuario': idUsuario,
      'id_rubro': idRubro,
      'fecha_asignacion': fechaAsignacion.toIso8601String(),
      'activo': activo,
    };
  }

  factory UsuarioRubro.fromMap(Map<String, dynamic> map) {
    return UsuarioRubro(
      idUsuarioRubro: map['id_usuario_rubro'],
      idUsuario: map['id_usuario'],
      idRubro: map['id_rubro'],
      fechaAsignacion: DateTime.parse(map['fecha_asignacion']),
      activo: map['activo'] ?? true,
    );
  }
}