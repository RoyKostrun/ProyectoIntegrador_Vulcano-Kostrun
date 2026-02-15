// lib/models/empleado_empresa_model.dart

class EmpleadoEmpresaModel {
  final int idEmpleado;
  final int idEmpresa;
  final String nombre;
  final String apellido;
  final String? fotoPerfilUrl;
  final String? relacion;
  final DateTime? fechaNacimiento;
  final bool activo;
  final DateTime createdAt;

  EmpleadoEmpresaModel({
    required this.idEmpleado,
    required this.idEmpresa,
    required this.nombre,
    required this.apellido,
    this.fotoPerfilUrl,
    this.relacion,
    this.fechaNacimiento,
    required this.activo,
    required this.createdAt,
  });

  factory EmpleadoEmpresaModel.fromJson(Map<String, dynamic> json) {
    return EmpleadoEmpresaModel(
      idEmpleado: json['id_empleado'] ?? 0,
      idEmpresa: json['id_empresa'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      fotoPerfilUrl: json['foto_de_perfil'],
      relacion: json['relacion'],
      fechaNacimiento: json['fecha_de_nacimiento'] != null
          ? (json['fecha_de_nacimiento'] is String
              ? DateTime.parse(json['fecha_de_nacimiento'])
              : json['fecha_de_nacimiento'] as DateTime)
          : null,
      activo: json['activo'] ?? true,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : json['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_empleado': idEmpleado,
      'id_empresa': idEmpresa,
      'nombre': nombre,
      'apellido': apellido,
      'foto_de_perfil': fotoPerfilUrl,
      'relacion': relacion,
      'fecha_de_nacimiento': fechaNacimiento?.toIso8601String().split('T')[0],
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helpers
  String get nombreCompleto => '$nombre $apellido'.trim();

  String get iniciales {
    final n = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final a = apellido.isNotEmpty ? apellido[0].toUpperCase() : '';
    return '$n$a';
  }

  int? get edad {
    if (fechaNacimiento == null) return null;
    final now = DateTime.now();
    int age = now.year - fechaNacimiento!.year;
    if (now.month < fechaNacimiento!.month ||
        (now.month == fechaNacimiento!.month && now.day < fechaNacimiento!.day)) {
      age--;
    }
    return age;
  }

  EmpleadoEmpresaModel copyWith({
    int? idEmpleado,
    int? idEmpresa,
    String? nombre,
    String? apellido,
    String? fotoPerfilUrl,
    String? relacion,
    DateTime? fechaNacimiento,
    bool? activo,
    DateTime? createdAt,
  }) {
    return EmpleadoEmpresaModel(
      idEmpleado: idEmpleado ?? this.idEmpleado,
      idEmpresa: idEmpresa ?? this.idEmpresa,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      relacion: relacion ?? this.relacion,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}