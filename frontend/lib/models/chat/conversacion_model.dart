// lib/models/chat/conversacion_model.dart

class Conversacion {
  final int idConversacion;
  final int idPostulacion;
  final int empleadorId;
  final int empleadoId;
  final String? ultimoMensaje;
  final DateTime? timestampUltimoMensaje;
  final int noLeidosEmpleador;
  final int noLeidosEmpleado;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos adicionales opcionales (para joins)
  final String? nombreEmpleador;
  final String? nombreEmpleado;
  final String? fotoEmpleador;
  final String? fotoEmpleado;
  final String? tituloTrabajo;
  final String? fotoTrabajo; // ✅ NUEVO

  Conversacion({
    required this.idConversacion,
    required this.idPostulacion,
    required this.empleadorId,
    required this.empleadoId,
    this.ultimoMensaje,
    this.timestampUltimoMensaje,
    this.noLeidosEmpleador = 0,
    this.noLeidosEmpleado = 0,
    this.activo = true,
    required this.createdAt,
    required this.updatedAt,
    this.nombreEmpleador,
    this.nombreEmpleado,
    this.fotoEmpleador,
    this.fotoEmpleado,
    this.tituloTrabajo,
    this.fotoTrabajo, // ✅ NUEVO
  });

  // Factory: Crear desde JSON (respuesta de Supabase)
  factory Conversacion.fromJson(Map<String, dynamic> json) {
    return Conversacion(
      idConversacion: json['id_conversacion'] as int,
      idPostulacion: json['id_postulacion'] as int,
      empleadorId: json['empleador_id'] as int,
      empleadoId: json['empleado_id'] as int,
      ultimoMensaje: json['ultimo_mensaje'] as String?,
      timestampUltimoMensaje: json['timestamp_ultimo_mensaje'] != null
          ? DateTime.parse(json['timestamp_ultimo_mensaje'] as String)
          : null,
      noLeidosEmpleador: json['no_leidos_empleador'] as int? ?? 0,
      noLeidosEmpleado: json['no_leidos_empleado'] as int? ?? 0,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // Campos de joins (opcionales)
      nombreEmpleador: json['nombre_empleador'] as String?,
      nombreEmpleado: json['nombre_empleado'] as String?,
      fotoEmpleador: json['foto_empleador'] as String?,
      fotoEmpleado: json['foto_empleado'] as String?,
      tituloTrabajo: json['titulo_trabajo'] as String?,
      fotoTrabajo: json['foto_trabajo'] as String?, // ✅ NUEVO
    );
  }

  // Convertir a JSON para insertar en Supabase
  Map<String, dynamic> toJson() {
    return {
      'id_postulacion': idPostulacion,
      'empleador_id': empleadorId,
      'empleado_id': empleadoId,
      'activo': activo,
      // No incluimos campos autogenerados ni calculados
    };
  }

  // Método helper: Obtener contador de no leídos según rol del usuario
  int obtenerNoLeidos(int usuarioId) {
    if (usuarioId == empleadorId) {
      return noLeidosEmpleador;
    } else if (usuarioId == empleadoId) {
      return noLeidosEmpleado;
    }
    return 0;
  }

  // Método helper: Obtener nombre del otro participante
  String? obtenerNombreOtroParticipante(int usuarioId) {
    if (usuarioId == empleadorId) {
      return nombreEmpleado;
    } else if (usuarioId == empleadoId) {
      return nombreEmpleador;
    }
    return null;
  }

  // Método helper: Obtener foto del otro participante
  String? obtenerFotoOtroParticipante(int usuarioId) {
    if (usuarioId == empleadorId) {
      return fotoEmpleado;
    } else if (usuarioId == empleadoId) {
      return fotoEmpleador;
    }
    return null;
  }

  // Método helper: Obtener ID del otro participante
  int? obtenerIdOtroParticipante(int usuarioId) {
    if (usuarioId == empleadorId) {
      return empleadoId;
    } else if (usuarioId == empleadoId) {
      return empleadorId;
    }
    return null;
  }

  // CopyWith para inmutabilidad
  Conversacion copyWith({
    int? idConversacion,
    int? idPostulacion,
    int? empleadorId,
    int? empleadoId,
    String? ultimoMensaje,
    DateTime? timestampUltimoMensaje,
    int? noLeidosEmpleador,
    int? noLeidosEmpleado,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? nombreEmpleador,
    String? nombreEmpleado,
    String? fotoEmpleador,
    String? fotoEmpleado,
    String? tituloTrabajo,
    String? fotoTrabajo, // ✅ NUEVO
  }) {
    return Conversacion(
      idConversacion: idConversacion ?? this.idConversacion,
      idPostulacion: idPostulacion ?? this.idPostulacion,
      empleadorId: empleadorId ?? this.empleadorId,
      empleadoId: empleadoId ?? this.empleadoId,
      ultimoMensaje: ultimoMensaje ?? this.ultimoMensaje,
      timestampUltimoMensaje: timestampUltimoMensaje ?? this.timestampUltimoMensaje,
      noLeidosEmpleador: noLeidosEmpleador ?? this.noLeidosEmpleador,
      noLeidosEmpleado: noLeidosEmpleado ?? this.noLeidosEmpleado,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nombreEmpleador: nombreEmpleador ?? this.nombreEmpleador,
      nombreEmpleado: nombreEmpleado ?? this.nombreEmpleado,
      fotoEmpleador: fotoEmpleador ?? this.fotoEmpleador,
      fotoEmpleado: fotoEmpleado ?? this.fotoEmpleado,
      tituloTrabajo: tituloTrabajo ?? this.tituloTrabajo,
      fotoTrabajo: fotoTrabajo ?? this.fotoTrabajo, // ✅ NUEVO
    );
  }

  @override
  String toString() {
    return 'Conversacion(id: $idConversacion, postulacion: $idPostulacion, empleador: $empleadorId, empleado: $empleadoId, trabajo: $tituloTrabajo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conversacion && other.idConversacion == idConversacion;
  }

  @override
  int get hashCode => idConversacion.hashCode;
}