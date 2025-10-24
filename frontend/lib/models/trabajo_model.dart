// lib/models/trabajo_model.dart

class TrabajoModel {
  final int id;
  final String titulo;
  final String descripcion;
  final double? salario;
  final String nombreRubro;
  final String direccionCompleta;
  final String estado;
  final String urgencia;
  final String? metodoPago;
  final String? periodoPago;
  final String? imagenUrl;
  final int? cantidadEmpleadosRequeridos;
  final String? fechaInicio;
  final String? fechaFin;
  final String? horarioInicio;
  final String? horarioFin;
  final String? nombreEmpleador;
  final int? empleadorId;

  TrabajoModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.salario,
    required this.nombreRubro,
    required this.direccionCompleta,
    required this.estado,
    required this.urgencia,
    this.metodoPago,
    this.periodoPago,
    this.imagenUrl,
    this.cantidadEmpleadosRequeridos,
    this.fechaInicio,
    this.fechaFin,
    this.horarioInicio,
    this.horarioFin,
    this.nombreEmpleador,
    this.empleadorId,
  });

  factory TrabajoModel.fromJson(Map<String, dynamic> json) {
    return TrabajoModel(
      id: json['id_trabajo'] ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      salario: json['salario']?.toDouble(),
      nombreRubro: json['rubro']?['nombre'] ?? 'Sin rubro',
      direccionCompleta: json['ubicacion'] != null
          ? '${json['ubicacion']['calle']} ${json['ubicacion']['numero']}, ${json['ubicacion']['ciudad']}'
          : 'Ubicación no disponible',
      estado: json['estado_publicacion'] ?? 'PUBLICADO',
      urgencia: json['urgencia'] ?? 'ESTANDAR',
      metodoPago: json['metodo_pago'],
      periodoPago: json['periodo_pago'],
      imagenUrl: json['imagen_url'],
      cantidadEmpleadosRequeridos: json['cantidad_empleados_requeridos'],
      fechaInicio: json['fecha_inicio'],
      fechaFin: json['fecha_fin'],
      horarioInicio: json['horario_inicio'],
      horarioFin: json['horario_fin'],
      nombreEmpleador: _getNombreEmpleador(json),
      empleadorId: json['empleador_id'],
    );
  }

  // Helper para obtener el nombre del empleador desde la relación
  static String? _getNombreEmpleador(Map<String, dynamic> json) {
    // Si viene del join con usuario_persona
    if (json['empleador_persona'] != null) {
      final persona = json['empleador_persona'];
      return '${persona['nombre']} ${persona['apellido']}';
    }
    
    // Si viene del join con usuario_empresa
    if (json['empleador_empresa'] != null) {
      final empresa = json['empleador_empresa'];
      return empresa['nombre_corporativo'];
    }
    
    // Fallback
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id_trabajo': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'salario': salario,
      'estado_publicacion': estado,
      'urgencia': urgencia,
      'metodo_pago': metodoPago,
      'periodo_pago': periodoPago,
      'imagen_url': imagenUrl,
      'cantidad_empleados_requeridos': cantidadEmpleadosRequeridos,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'horario_inicio': horarioInicio,
      'horario_fin': horarioFin,
      'empleador_id': empleadorId,
    };
  }

  // Método helper para copiar con modificaciones
  TrabajoModel copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    double? salario,
    String? nombreRubro,
    String? direccionCompleta,
    String? estado,
    String? urgencia,
    String? metodoPago,
    String? periodoPago,
    String? imagenUrl,
    int? cantidadEmpleadosRequeridos,
    String? fechaInicio,
    String? fechaFin,
    String? horarioInicio,
    String? horarioFin,
    String? nombreEmpleador,
    int? empleadorId,
  }) {
    return TrabajoModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      salario: salario ?? this.salario,
      nombreRubro: nombreRubro ?? this.nombreRubro,
      direccionCompleta: direccionCompleta ?? this.direccionCompleta,
      estado: estado ?? this.estado,
      urgencia: urgencia ?? this.urgencia,
      metodoPago: metodoPago ?? this.metodoPago,
      periodoPago: periodoPago ?? this.periodoPago,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      cantidadEmpleadosRequeridos: cantidadEmpleadosRequeridos ?? this.cantidadEmpleadosRequeridos,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      horarioInicio: horarioInicio ?? this.horarioInicio,
      horarioFin: horarioFin ?? this.horarioFin,
      nombreEmpleador: nombreEmpleador ?? this.nombreEmpleador,
      empleadorId: empleadorId ?? this.empleadorId,
    );
  }
}