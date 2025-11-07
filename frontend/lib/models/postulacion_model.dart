// lib/models/postulacion_model.dart

class PostulacionModel {
  final int id;
  final int trabajoId;
  final int postulanteId;
  final String estado;
  final String? mensaje;
  final double? ofertaPago;
  final DateTime fechaPostulacion;
  final DateTime? fechaRespuesta;
  final DateTime? fechaCancelacion;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  final TrabajoInfo? trabajo;
  final PostulanteInfo? postulante;

  PostulacionModel({
    required this.id,
    required this.trabajoId,
    required this.postulanteId,
    required this.estado,
    this.mensaje,
    this.ofertaPago,
    required this.fechaPostulacion,
    this.fechaRespuesta,
    this.fechaCancelacion,
    required this.createdAt,
    required this.updatedAt,
    this.trabajo,
    this.postulante,
  });

  factory PostulacionModel.fromJson(Map<String, dynamic> json) {
    return PostulacionModel(
      id: json['id_postulacion'] ?? 0,
      trabajoId: json['trabajo_id'] ?? 0,
      postulanteId: json['postulante_id'] ?? 0,
      estado: json['estado'] ?? 'PENDIENTE',
      mensaje: json['mensaje'],
      ofertaPago: json['oferta_pago']?.toDouble(),
      fechaPostulacion: json['fecha_postulacion'] != null
          ? DateTime.parse(json['fecha_postulacion'])
          : DateTime.now(),
      fechaRespuesta: json['fecha_respuesta'] != null
          ? DateTime.parse(json['fecha_respuesta'])
          : null,
      fechaCancelacion: json['fecha_cancelacion'] != null
          ? DateTime.parse(json['fecha_cancelacion'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      trabajo: json['trabajo'] != null
          ? TrabajoInfo.fromJson(json['trabajo'])
          : null,
      postulante: json['postulante'] != null
          ? PostulanteInfo.fromJson(json['postulante'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_postulacion': id,
      'trabajo_id': trabajoId,
      'postulante_id': postulanteId,
      'estado': estado,
      'mensaje': mensaje,
      'oferta_pago': ofertaPago,
      'fecha_postulacion': fechaPostulacion.toIso8601String(),
      'fecha_respuesta': fechaRespuesta?.toIso8601String(),
      'fecha_cancelacion': fechaCancelacion?.toIso8601String(),
    };
  }

  String getEstadoColor() {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return '#FFA500';
      case 'ACEPTADO':
        return '#4CAF50';
      case 'RECHAZADO':
        return '#F44336';
      case 'CANCELADO':
        return '#9E9E9E';
      default:
        return '#9E9E9E';
    }
  }

  String getEstadoLabel() {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return 'Pendiente';
      case 'ACEPTADO':
        return 'Aceptado';
      case 'RECHAZADO':
        return 'Rechazado';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  bool puedeCancelarse() {
    return estado.toUpperCase() == 'PENDIENTE' || 
           estado.toUpperCase() == 'ACEPTADO';
  }

  PostulacionModel copyWith({
    int? id,
    int? trabajoId,
    int? postulanteId,
    String? estado,
    String? mensaje,
    double? ofertaPago,
    DateTime? fechaPostulacion,
    DateTime? fechaRespuesta,
    DateTime? fechaCancelacion,
    DateTime? createdAt,
    DateTime? updatedAt,
    TrabajoInfo? trabajo,
    PostulanteInfo? postulante,
  }) {
    return PostulacionModel(
      id: id ?? this.id,
      trabajoId: trabajoId ?? this.trabajoId,
      postulanteId: postulanteId ?? this.postulanteId,
      estado: estado ?? this.estado,
      mensaje: mensaje ?? this.mensaje,
      ofertaPago: ofertaPago ?? this.ofertaPago,
      fechaPostulacion: fechaPostulacion ?? this.fechaPostulacion,
      fechaRespuesta: fechaRespuesta ?? this.fechaRespuesta,
      fechaCancelacion: fechaCancelacion ?? this.fechaCancelacion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trabajo: trabajo ?? this.trabajo,
      postulante: postulante ?? this.postulante,
    );
  }
}

// ========================================
// CLASE AUXILIAR: Información del Trabajo
// ========================================
class TrabajoInfo {
  final int id;
  final String titulo;
  final String descripcion;
  final double? salario;
  final String? fechaInicio;
  final String? fechaFin;
  final String? horarioInicio;
  final String? horarioFin;
  final int? cantidadEmpleadosRequeridos;
  final String nombreRubro;
  final String direccion;

  TrabajoInfo({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.salario,
    this.fechaInicio,
    this.fechaFin,
    this.horarioInicio,
    this.horarioFin,
    this.cantidadEmpleadosRequeridos,
    required this.nombreRubro,
    required this.direccion,
  });

  factory TrabajoInfo.fromJson(Map<String, dynamic> json) {
    String direccion = 'Ubicación no disponible';
    if (json['ubicacion'] != null) {
      final ubi = json['ubicacion'];
      direccion = '${ubi['calle']} ${ubi['numero']}, ${ubi['ciudad']}';
    }

    return TrabajoInfo(
      id: json['id_trabajo'] ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      salario: json['salario']?.toDouble(),
      fechaInicio: json['fecha_inicio'],
      fechaFin: json['fecha_fin'],
      horarioInicio: json['horario_inicio'],
      horarioFin: json['horario_fin'],
      cantidadEmpleadosRequeridos: json['cantidad_empleados_requeridos'],
      nombreRubro: json['rubro']?['nombre'] ?? 'Sin rubro',
      direccion: direccion,
    );
  }
}

// ========================================
// CLASE AUXILIAR: Información del Postulante
// ========================================
class PostulanteInfo {
  final int id;
  final String nombre;
  final String? fotoPerfil;
  final double? puntajePromedio;
  final bool esEmpresa;

  PostulanteInfo({
    required this.id,
    required this.nombre,
    this.fotoPerfil,
    this.puntajePromedio,
    required this.esEmpresa,
  });

    factory PostulanteInfo.fromJson(Map<String, dynamic> json) {
    String nombre = 'Usuario';
    String? fotoPerfil;
    double? puntaje;
    bool esEmpresa = false;
    
    try {
      // ✅ PRIMERO: Verificar usuario_persona
      if (json['usuario_persona'] != null) {
        final personaData = json['usuario_persona'];
        
        if (personaData is List && personaData.isNotEmpty) {
          final persona = personaData[0];
          if (persona is Map<String, dynamic>) {
            nombre = '${persona['nombre']} ${persona['apellido']}'.trim();
            fotoPerfil = persona['foto_perfil_url'];
            puntaje = persona['puntaje_promedio']?.toDouble();
            esEmpresa = false;
          }
        }
      }
      // ✅ SEGUNDO: Si NO hay persona, verificar empresa
      else if (json['usuario_empresa'] != null) {
        final empresaData = json['usuario_empresa'];
        
        if (empresaData is List && empresaData.isNotEmpty) {
          final empresa = empresaData[0];
          if (empresa is Map<String, dynamic>) {
            nombre = empresa['nombre_corporativo'] ?? 'Empresa';
            esEmpresa = true;
          }
        }
      }
    } catch (e) {
      print('⚠️ Error: $e');
    }

    return PostulanteInfo(
      id: json['id_usuario'] ?? 0,
      nombre: nombre,
      fotoPerfil: fotoPerfil,
      puntajePromedio: puntaje,
      esEmpresa: esEmpresa,
    );
  }

  String getIniciales() {
    if (nombre.isEmpty || nombre == 'Usuario') return '?';
    
    final palabras = nombre.split(' ');
    if (palabras.length >= 2 && palabras[0].isNotEmpty && palabras[1].isNotEmpty) {
      return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
    }
    return nombre.length > 0 ? nombre[0].toUpperCase() : '?';
  }
}