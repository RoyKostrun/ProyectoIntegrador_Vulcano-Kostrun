// lib/models/user_model.dart
class User {
  final int idUsuario;
  final int? ubicacionId;
  final String tipoUsuario; // 'PERSONA' | 'EMPRESA'
  final String email;
  final String? telefono;
  final DateTime fechaRegistro;
  final String estadoCuenta; // 'ACTIVO' | 'SUSPENDIDO' | 'ELIMINADO'
  final int cantidadTrabajosRealizados;
  final int puntosReputacion;
  final DateTime? bloqueadoHasta;
  final DateTime? fechaSuspension;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Datos específicos según tipo de usuario
  final UserPersona? persona;
  final UserEmpresa? empresa;

  User({
    required this.idUsuario,
    this.ubicacionId,
    required this.tipoUsuario,
    required this.email,
    this.telefono,
    required this.fechaRegistro,
    required this.estadoCuenta,
    required this.cantidadTrabajosRealizados,
    required this.puntosReputacion,
    this.bloqueadoHasta,
    this.fechaSuspension,
    required this.createdAt,
    required this.updatedAt,
    this.persona,
    this.empresa,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // ✅ MANEJAR usuario_persona (puede ser lista o map)
    UserPersona? persona;
    if (json['usuario_persona'] != null) {
      if (json['usuario_persona'] is List) {
        final personaList = json['usuario_persona'] as List;
        if (personaList.isNotEmpty) {
          persona = UserPersona.fromJson(personaList.first);
        }
      } else if (json['usuario_persona'] is Map<String, dynamic>) {
        persona = UserPersona.fromJson(json['usuario_persona']);
      }
    }

    // ✅ MANEJAR usuario_empresa (puede ser lista o map)
    UserEmpresa? empresa;
    if (json['usuario_empresa'] != null) {
      if (json['usuario_empresa'] is List) {
        final empresaList = json['usuario_empresa'] as List;
        if (empresaList.isNotEmpty) {
          empresa = UserEmpresa.fromJson(empresaList.first);
        }
      } else if (json['usuario_empresa'] is Map<String, dynamic>) {
        empresa = UserEmpresa.fromJson(json['usuario_empresa']);
      }
    }

    return User(
      idUsuario: json['id_usuario'],
      ubicacionId: json['ubicacion_id'],
      tipoUsuario: json['tipo_usuario'],
      email: json['email'],
      telefono: json['telefono'],
      fechaRegistro: json['fecha_registro'] is String 
          ? DateTime.parse(json['fecha_registro'])
          : json['fecha_registro'] as DateTime,
      estadoCuenta: json['estado_cuenta'],
      cantidadTrabajosRealizados: json['cantidad_trabajos_realizados'] ?? 0,
      puntosReputacion: json['puntos_reputacion'] ?? 0,
      bloqueadoHasta: json['bloqueado_hasta'] != null 
          ? (json['bloqueado_hasta'] is String 
              ? DateTime.parse(json['bloqueado_hasta'])
              : json['bloqueado_hasta'] as DateTime)
          : null,
      fechaSuspension: json['fecha_suspension'] != null 
          ? (json['fecha_suspension'] is String 
              ? DateTime.parse(json['fecha_suspension'])
              : json['fecha_suspension'] as DateTime)
          : null,
      createdAt: json['created_at'] is String 
          ? DateTime.parse(json['created_at'])
          : json['created_at'] as DateTime,
      updatedAt: json['updated_at'] is String 
          ? DateTime.parse(json['updated_at'])
          : json['updated_at'] as DateTime,
      persona: persona,  // ✅ Usar la variable procesada
      empresa: empresa,  // ✅ Usar la variable procesada
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'ubicacion_id': ubicacionId,
      'tipo_usuario': tipoUsuario,
      'email': email,
      'telefono': telefono,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'estado_cuenta': estadoCuenta,
      'cantidad_trabajos_realizados': cantidadTrabajosRealizados,
      'puntos_reputacion': puntosReputacion,
      'bloqueado_hasta': bloqueadoHasta?.toIso8601String(),
      'fecha_suspension': fechaSuspension?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Métodos útiles
  bool get isPersona => tipoUsuario == 'PERSONA';
  bool get isEmpresa => tipoUsuario == 'EMPRESA';
  bool get isActive => estadoCuenta == 'ACTIVO';
  
  String get displayName {
    if (isPersona && persona != null) {
      return '${persona!.nombre} ${persona!.apellido}';
    } else if (isEmpresa && empresa != null) {
      return empresa!.nombreCorporativo;
    }
    return email;
  }

  double get rating {
    if (isPersona && persona != null) {
      return persona!.puntajePromedio;
    } else if (isEmpresa && empresa != null) {
      return empresa!.puntajePromedio;
    }
    return 0.0;
  }
}

// ✅ CLASE ACTUALIZADA CON BOOLEANOS
class UserPersona {
  final int idPersona;
  final int idUsuario;
  final int? rubroId;
  final String nombre;
  final String apellido;
  final String dni; // 8 dígitos argentinos
  final String username; // Nombre de usuario único
  final DateTime? fechaNacimiento;
  final String genero; // 'M' | 'F' | 'X'
  final String? fotoPerfilUrl;
  final String disponibilidad; // 'ACTIVO' | 'INACTIVO'
  final double puntajePromedio;
  final bool esEmpleador; // ✅ NUEVO: Reemplaza 'rol'
  final bool esEmpleado;  // ✅ NUEVO: Reemplaza 'rol'
  final DateTime fechaRegistro;
  final String? contactoEmergencia;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPersona({
    required this.idPersona,
    required this.idUsuario,
    this.rubroId,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.username,
    this.fechaNacimiento,
    required this.genero,
    this.fotoPerfilUrl,
    required this.disponibilidad,
    required this.puntajePromedio,
    required this.esEmpleador, // ✅ CAMBIADO
    required this.esEmpleado,  // ✅ CAMBIADO
    required this.fechaRegistro,
    this.contactoEmergencia,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPersona.fromJson(Map<String, dynamic> json) {
    return UserPersona(
      idPersona: json['id_persona'],
      idUsuario: json['id_usuario'],
      rubroId: json['rubro_id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      dni: json['dni'],
      username: json['username'],
      fechaNacimiento: json['fecha_nacimiento'] != null 
          ? (json['fecha_nacimiento'] is String 
              ? DateTime.parse(json['fecha_nacimiento'])
              : json['fecha_nacimiento'] as DateTime)
          : null,
      genero: json['genero'],
      fotoPerfilUrl: json['foto_perfil_url'],
      disponibilidad: json['disponibilidad'],
      puntajePromedio: (json['puntaje_promedio'] ?? 0.0).toDouble(),
      esEmpleador: json['es_empleador'] ?? false, // ✅ CAMBIADO
      esEmpleado: json['es_empleado'] ?? false,   // ✅ CAMBIADO
      fechaRegistro: json['fecha_registro'] is String 
          ? DateTime.parse(json['fecha_registro'])
          : json['fecha_registro'] as DateTime,
      contactoEmergencia: json['contacto_emergencia'],
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
      'id_persona': idPersona,
      'id_usuario': idUsuario,
      'rubro_id': rubroId,
      'nombre': nombre,
      'apellido': apellido,
      'dni': dni,
      'username': username,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String().split('T')[0],
      'genero': genero,
      'foto_perfil_url': fotoPerfilUrl,
      'disponibilidad': disponibilidad,
      'puntaje_promedio': puntajePromedio,
      'es_empleador': esEmpleador, // ✅ CAMBIADO
      'es_empleado': esEmpleado,   // ✅ CAMBIADO
      'fecha_registro': fechaRegistro.toIso8601String(),
      'contacto_emergencia': contactoEmergencia,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ✅ NUEVO: Helper para mostrar rol de forma legible
  String get rolDisplay {
    if (esEmpleador && esEmpleado) return 'Empleador y Empleado';
    if (esEmpleador) return 'Empleador';
    if (esEmpleado) return 'Empleado';
    return 'Sin rol asignado';
  }
  String? get fotoPerfil => fotoPerfilUrl;
}

class UserEmpresa {
  final int idEmpresa;
  final int idUsuario;
  final int? rubroId;
  final String nombreCorporativo;
  final String? razonSocial;
  final String? cuit;
  final String? representanteLegal;
  final double puntajePromedio;
  final DateTime fechaRegistro;
  final String? direccionFiscal;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserEmpresa({
    required this.idEmpresa,
    required this.idUsuario,
    this.rubroId,
    required this.nombreCorporativo,
    this.razonSocial,
    this.cuit,
    this.representanteLegal,
    required this.puntajePromedio,
    required this.fechaRegistro,
    this.direccionFiscal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserEmpresa.fromJson(Map<String, dynamic> json) {
    return UserEmpresa(
      idEmpresa: json['id_empresa'],
      idUsuario: json['id_usuario'],
      rubroId: json['rubro_id'],
      nombreCorporativo: json['nombre_corporativo'],
      razonSocial: json['razon_social'],
      cuit: json['cuit'],
      representanteLegal: json['representante_legal'],
      puntajePromedio: (json['puntaje_promedio'] ?? 0.0).toDouble(),
      fechaRegistro: json['fecha_registro'] is String 
          ? DateTime.parse(json['fecha_registro'])
          : json['fecha_registro'] as DateTime,
      direccionFiscal: json['direccion_fiscal'],
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
      'id_empresa': idEmpresa,
      'id_usuario': idUsuario,
      'rubro_id': rubroId,
      'nombre_corporativo': nombreCorporativo,
      'razon_social': razonSocial,
      'cuit': cuit,
      'representante_legal': representanteLegal,
      'puntaje_promedio': puntajePromedio,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'direccion_fiscal': direccionFiscal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}