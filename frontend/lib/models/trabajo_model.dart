// lib/models/trabajo_model.dart
// ✅ VERSIÓN FINAL - Con parse correcto de fechas

import 'package:flutter/material.dart';

enum EstadoPublicacion {
  PUBLICADO,
  COMPLETO,
  EN_PROGRESO,
  FINALIZADO,
  VENCIDO,
  CANCELADO,
}

class TrabajoModel {
  final int id;
  final String titulo;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String horarioInicio;
  final String horarioFin;
  final int cantidadEmpleadosRequeridos;
  final double? salario;
  final String metodoPago;
  final EstadoPublicacion estadoPublicacion;
  final String urgencia;
  final String tipoHorario;
  final String? nombreRubro;
  final String? nombreUbicacion;
  final String? direccionCompleta;
  final int? cantidadPostulaciones;
  final int empleadorId;
  final int? postulacionesAceptadas;
  final int? cuposDisponibles;
  final double? porcentajeLlenado;
  final String? imagenUrl;
  final String? periodoPago;
  final String? nombreEmpleador;

  TrabajoModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fechaInicio,
    this.fechaFin,
    required this.horarioInicio,
    required this.horarioFin,
    required this.cantidadEmpleadosRequeridos,
    this.salario,
    required this.metodoPago,
    required this.estadoPublicacion,
    required this.urgencia,
    required this.tipoHorario,
    this.nombreRubro,
    this.nombreUbicacion,
    this.direccionCompleta,
    this.cantidadPostulaciones,
    required this.empleadorId,
    this.postulacionesAceptadas,
    this.cuposDisponibles,
    this.porcentajeLlenado,
    this.imagenUrl,
    this.periodoPago,
    this.nombreEmpleador,
  });

  factory TrabajoModel.fromJson(Map<String, dynamic> json) {
    return TrabajoModel(
      id: json['id_trabajo'] ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      // ✅ CORREGIDO: Parse de fechas
      fechaInicio: _parseDateTime(json['fecha_inicio'])!,
      fechaFin: _parseDateTime(json['fecha_fin']),
      horarioInicio: json['horario_inicio'] ?? '',
      horarioFin: json['horario_fin'] ?? '',
      cantidadEmpleadosRequeridos: json['cantidad_empleados_requeridos'] ?? 1,
      salario: json['salario']?.toDouble(),
      metodoPago: json['metodo_pago'] ?? '',
      estadoPublicacion: _parseEstadoPublicacion(json['estado_publicacion']),
      urgencia: json['urgencia'] ?? 'ESTANDAR',
      tipoHorario: json['tipo_horario'] ?? 'FIJO',
      nombreRubro: json['rubro']?['nombre'] ??
          (json['rubro'] is List && (json['rubro'] as List).isNotEmpty
              ? json['rubro'][0]['nombre']
              : null),
      nombreUbicacion: json['ubicacion']?['nombre'] ??
          (json['ubicacion'] is List && (json['ubicacion'] as List).isNotEmpty
              ? json['ubicacion'][0]['nombre']
              : null),
      direccionCompleta: _buildDireccion(json['ubicacion']),
      cantidadPostulaciones: json['cantidad_postulaciones'] ?? 0,
      empleadorId: json['empleador_id'] ?? 0,
      postulacionesAceptadas: json['postulaciones_aceptadas'],
      cuposDisponibles: json['cupos_disponibles'],
      porcentajeLlenado: json['porcentaje_llenado']?.toDouble(),
      imagenUrl: json['imagen_url'],
      periodoPago: json['periodo_pago'] ??
          (json['pago'] != null && json['pago'] is Map
              ? json['pago']['periodo']
              : null) ??
          (json['pago'] is List && (json['pago'] as List).isNotEmpty
              ? json['pago'][0]['periodo']
              : null),
      nombreEmpleador:
          json['nombre_empleador_procesado'] ?? json['nombre_empleador'],
    );
  }

  // ✅ NUEVO: Helper para parsear fechas que pueden venir como String o DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parseando fecha: $value - $e');
        return null;
      }
    }
    return null;
  }

  static EstadoPublicacion _parseEstadoPublicacion(String? estado) {
    if (estado == null) return EstadoPublicacion.PUBLICADO;

    switch (estado.toUpperCase()) {
      case 'PUBLICADO':
        return EstadoPublicacion.PUBLICADO;
      case 'COMPLETO':
        return EstadoPublicacion.COMPLETO;
      case 'EN_PROGRESO':
        return EstadoPublicacion.EN_PROGRESO;
      case 'FINALIZADO':
        return EstadoPublicacion.FINALIZADO;
      case 'VENCIDO':
        return EstadoPublicacion.VENCIDO;
      case 'CANCELADO':
        return EstadoPublicacion.CANCELADO;
      default:
        return EstadoPublicacion.PUBLICADO;
    }
  }

  static String? _buildDireccion(dynamic ubicacionData) {
    if (ubicacionData == null) return null;

    final ubicacion =
        ubicacionData is List && (ubicacionData as List).isNotEmpty
            ? ubicacionData[0]
            : ubicacionData;

    if (ubicacion is! Map<String, dynamic>) return null;

    final calle = ubicacion['calle'] ?? '';
    final numero = ubicacion['numero'] ?? '';
    final ciudad = ubicacion['ciudad'] ?? '';
    final provincia = ubicacion['provincia'] ?? '';

    return '$calle $numero, $ciudad, $provincia';
  }

  String get estadoTexto {
    switch (estadoPublicacion) {
      case EstadoPublicacion.PUBLICADO:
        return 'PUBLICADO';
      case EstadoPublicacion.COMPLETO:
        return 'COMPLETO';
      case EstadoPublicacion.EN_PROGRESO:
        return 'EN_PROGRESO';
      case EstadoPublicacion.FINALIZADO:
        return 'FINALIZADO';
      case EstadoPublicacion.VENCIDO:
        return 'VENCIDO';
      case EstadoPublicacion.CANCELADO:
        return 'CANCELADO';
    }
  }

  Color get estadoColor {
    switch (estadoPublicacion) {
      case EstadoPublicacion.PUBLICADO:
        return const Color(0xFF4CAF50);
      case EstadoPublicacion.COMPLETO:
        return const Color(0xFF2196F3);
      case EstadoPublicacion.EN_PROGRESO:
        return const Color(0xFFFF9800);
      case EstadoPublicacion.FINALIZADO:
        return const Color(0xFF388E3C);
      case EstadoPublicacion.VENCIDO:
        return const Color(0xFFF44336);
      case EstadoPublicacion.CANCELADO:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData get estadoIcono {
    switch (estadoPublicacion) {
      case EstadoPublicacion.PUBLICADO:
        return Icons.public;
      case EstadoPublicacion.COMPLETO:
        return Icons.people;
      case EstadoPublicacion.EN_PROGRESO:
        return Icons.work;
      case EstadoPublicacion.FINALIZADO:
        return Icons.check_circle;
      case EstadoPublicacion.VENCIDO:
        return Icons.event_busy;
      case EstadoPublicacion.CANCELADO:
        return Icons.cancel;
    }
  }

  // Getter de compatibilidad
  String get estado => estadoTexto;

  bool get esVisibleParaEmpleados =>
      estadoPublicacion == EstadoPublicacion.PUBLICADO;
  bool get permitePostulaciones =>
      estadoPublicacion == EstadoPublicacion.PUBLICADO;
  bool get estaActivo =>
      estadoPublicacion != EstadoPublicacion.FINALIZADO &&
      estadoPublicacion != EstadoPublicacion.VENCIDO &&
      estadoPublicacion != EstadoPublicacion.CANCELADO;
}
