// lib/services/trabajo_service.dart
// ✅ ACTUALIZADO con sistema de estados

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/menu_perfil/trabajo_model.dart';
import '../auth_service.dart';

class TrabajoService {
  final supabase = Supabase.instance.client;

  // ============================================
  // 🔄 ACTUALIZAR ESTADOS (llamar al iniciar app)
  // ============================================

  Future<void> actualizarEstadosTrabajos() async {
    try {
      print('🔄 Actualizando estados de trabajos...');

      await supabase.rpc('actualizar_estados_trabajos');

      print('✅ Estados actualizados correctamente');
    } catch (e) {
      print('❌ Error actualizando estados: $e');
      // No lanzar error, es una operación de background
    }
  }

  // ============================================
// 🔍 OBTENER TRABAJO POR ID
// ============================================

  Future<TrabajoModel?> getTrabajoById(int idTrabajo) async {
    try {
      print('🔍 Obteniendo trabajo con ID: $idTrabajo');

      final response = await supabase.from('trabajo').select('''
        *,
        rubro:id_rubro(id_rubro, nombre),
        ubicacion:ubicacion_id(id_ubicacion, nombre, calle, numero, ciudad, provincia),
        pago:id_pago(id_pago, monto, metodo, estado, periodo),
        usuario!trabajo_empleador_id_fkey(
          id_usuario,
          usuario_persona(
            nombre,
            apellido,
            foto_perfil_url
          ),
          usuario_empresa(
            nombre_corporativo,
            logo_url
          )
        )
      ''').eq('id_trabajo', idTrabajo).single();

      String? nombreEmpleador;
      if (response['usuario'] != null) {
        final usuario = response['usuario'];
        if (usuario['usuario_persona'] != null &&
            (usuario['usuario_persona'] is List &&
                (usuario['usuario_persona'] as List).isNotEmpty)) {
          final persona = (usuario['usuario_persona'] as List)[0];
          nombreEmpleador = '${persona['nombre']} ${persona['apellido']}';
        } else if (usuario['usuario_empresa'] != null &&
            (usuario['usuario_empresa'] is List &&
                (usuario['usuario_empresa'] as List).isNotEmpty)) {
          final empresa = (usuario['usuario_empresa'] as List)[0];
          nombreEmpleador = empresa['nombre_corporativo'];
        }
      }

      response['nombre_empleador_procesado'] = nombreEmpleador;
      print('✅ Trabajo encontrado: ${response['titulo']}');
      return TrabajoModel.fromJson(response);
    } catch (e) {
      print('❌ Error al obtener trabajo por ID: $e');
      return null;
    }
  }

  // ============================================
  // 📋 TRAER TRABAJOS DE OTROS (solo PUBLICADO)
  // ============================================

  // ============================================
// 📋 TRAER TRABAJOS DE OTROS (solo PUBLICADO)
// ============================================

  Future<List<TrabajoModel>> getTrabajos({int from = 0, int to = 19}) async {
    try {
      final idUsuario = await AuthService.getCurrentUserId();
      print('🔍 Cargando trabajos donde empleador_id != $idUsuario');

      final response = await supabase
          .from('trabajo')
          .select('''
      *,
      rubro:id_rubro(id_rubro, nombre),
      ubicacion:ubicacion_id(id_ubicacion, nombre, calle, numero, ciudad, provincia),
      pago:id_pago(id_pago, monto, metodo, estado, periodo),
      usuario!trabajo_empleador_id_fkey(
        id_usuario,
        usuario_persona(
          nombre,
          apellido,
          foto_perfil_url
        ),
        usuario_empresa(
          nombre_corporativo,
          logo_url
        )
      ),
      trabajo_foto(foto_url, es_principal)
    ''')
          .neq('empleador_id', idUsuario)
          .eq('estado_publicacion', 'PUBLICADO')
          .range(from, to)
          .order('created_at', ascending: false);

      print('✅ Trabajos encontrados: ${(response as List).length}');

      final trabajos = (response as List).map((json) {
        String? nombreEmpleador;
        if (json['usuario'] != null) {
          final usuario = json['usuario'];
          if (usuario['usuario_persona'] != null &&
              (usuario['usuario_persona'] is List &&
                  (usuario['usuario_persona'] as List).isNotEmpty)) {
            final persona = (usuario['usuario_persona'] as List)[0];
            nombreEmpleador = '${persona['nombre']} ${persona['apellido']}';
          } else if (usuario['usuario_empresa'] != null &&
              (usuario['usuario_empresa'] is List &&
                  (usuario['usuario_empresa'] as List).isNotEmpty)) {
            final empresa = (usuario['usuario_empresa'] as List)[0];
            nombreEmpleador = empresa['nombre_corporativo'];
          }
        }
        json['nombre_empleador_procesado'] = nombreEmpleador;

        String? fotoPrincipalUrl;
        if (json['trabajo_foto'] != null) {
          final fotos = json['trabajo_foto'];
          if (fotos is List && fotos.isNotEmpty) {
            try {
              final fotoPrincipal = fotos.firstWhere(
                (f) => f['es_principal'] == true,
                orElse: () => fotos[0],
              );
              fotoPrincipalUrl = fotoPrincipal['foto_url'];
            } catch (e) {
              print('⚠️ Error procesando foto: $e');
            }
          }
        }
        json['foto_principal_url'] = fotoPrincipalUrl;

        return TrabajoModel.fromJson(json);
      }).toList();

      final now = DateTime.now();
      final trabajosFiltrados = trabajos.where((trabajo) {
        if (trabajo.fechaFin == null) return true;
        final fechaFin = trabajo.fechaFin!;
        final horarioFin = trabajo.horarioFin;
        if (horarioFin == null || horarioFin.isEmpty) {
          return fechaFin.isAfter(DateTime(now.year, now.month, now.day)) ||
              fechaFin.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
        }
        try {
          final partes = horarioFin.split(':');
          if (partes.length < 2) return true;
          final hora = int.parse(partes[0]);
          final minuto = int.parse(partes[1]);
          final fechaHoraFin = DateTime(
            fechaFin.year,
            fechaFin.month,
            fechaFin.day,
            hora,
            minuto,
          );
          return fechaHoraFin.isAfter(now);
        } catch (e) {
          return true;
        }
      }).toList();

      print('✅ Trabajos después de filtrar: ${trabajosFiltrados.length}');
      return trabajosFiltrados;
    } catch (e) {
      print('❌ Error al cargar trabajos: $e');
      throw Exception('Error al cargar trabajos: $e');
    }
  }

  // ============================================
  // 📋 TRAER MIS TRABAJOS (todos los estados)
  // ============================================

  Future<List<TrabajoModel>> getMisTrabajos({
    int from = 0,
    int to = 19,
    String? filtroEstado,
  }) async {
    try {
      final idUsuario = await AuthService.getCurrentUserId();
      print('🔍 Cargando mis trabajos donde empleador_id = $idUsuario');

      var query = supabase.from('trabajo').select('''
      *,
      rubro:id_rubro(id_rubro, nombre),
      ubicacion:ubicacion_id(id_ubicacion, nombre, calle, numero, ciudad, provincia),
      pago:id_pago(id_pago, monto, metodo, estado, periodo),
      usuario!trabajo_empleador_id_fkey(
        id_usuario,
        usuario_persona(
          nombre,
          apellido,
          foto_perfil_url
        ),
        usuario_empresa(
          nombre_corporativo,
          logo_url
        )
      ),
      trabajo_foto(foto_url, es_principal)
    ''').eq('empleador_id', idUsuario);

      if (filtroEstado != null) {
        query = query.eq('estado_publicacion', filtroEstado);
      }

      final response =
          await query.range(from, to).order('created_at', ascending: false);

      print('✅ Mis trabajos encontrados: ${(response as List).length}');

      final trabajos = (response as List).map((json) {
        String? nombreEmpleador;
        if (json['usuario'] != null) {
          final usuario = json['usuario'];
          if (usuario['usuario_persona'] != null &&
              (usuario['usuario_persona'] is List &&
                  (usuario['usuario_persona'] as List).isNotEmpty)) {
            final persona = (usuario['usuario_persona'] as List)[0];
            nombreEmpleador = '${persona['nombre']} ${persona['apellido']}';
          } else if (usuario['usuario_empresa'] != null &&
              (usuario['usuario_empresa'] is List &&
                  (usuario['usuario_empresa'] as List).isNotEmpty)) {
            final empresa = (usuario['usuario_empresa'] as List)[0];
            nombreEmpleador = empresa['nombre_corporativo'];
          }
        }
        json['nombre_empleador_procesado'] = nombreEmpleador;

        String? fotoPrincipalUrl;
        if (json['trabajo_foto'] != null) {
          final fotos = json['trabajo_foto'];
          if (fotos is List && fotos.isNotEmpty) {
            try {
              final fotoPrincipal = fotos.firstWhere(
                (f) => f['es_principal'] == true,
                orElse: () => fotos[0],
              );
              fotoPrincipalUrl = fotoPrincipal['foto_url'];
            } catch (e) {
              print('⚠️ Error procesando foto: $e');
            }
          }
        }
        json['foto_principal_url'] = fotoPrincipalUrl;

        return TrabajoModel.fromJson(json);
      }).toList();

      trabajos.sort((a, b) {
        final ordenA = _getOrdenEstado(a.estadoPublicacion);
        final ordenB = _getOrdenEstado(b.estadoPublicacion);
        return ordenA.compareTo(ordenB);
      });

      return trabajos;
    } catch (e) {
      print('❌ Error al cargar mis trabajos: $e');
      throw Exception('Error al cargar mis trabajos: $e');
    }
  }

  // ✅ Helper: orden de estados (menor = más prioritario)
  int _getOrdenEstado(EstadoPublicacion estado) {
    switch (estado) {
      case EstadoPublicacion.PUBLICADO:
        return 1;
      case EstadoPublicacion.COMPLETO:
        return 2;
      case EstadoPublicacion.EN_PROGRESO:
        return 3;
      case EstadoPublicacion.FINALIZADO:
        return 4;
      case EstadoPublicacion.VENCIDO:
        return 5;
      case EstadoPublicacion.CANCELADO:
        return 6;
    }
  }

  // ============================================
  // 🔍 VERIFICAR SI PUEDE POSTULARSE
  // ============================================

  Future<Map<String, dynamic>> puedePostularse(int trabajoId) async {
    try {
      final idUsuario = await AuthService.getCurrentUserId();

      final response =
          await supabase.rpc('puede_postularse_a_trabajo', params: {
        'p_trabajo_id': trabajoId,
        'p_usuario_id': idUsuario,
      });

      if (response is List && response.isNotEmpty) {
        return {
          'puede': response[0]['puede_postular'] ?? false,
          'razon': response[0]['razon'] ?? '',
        };
      }

      return {
        'puede': false,
        'razon': 'Error al verificar',
      };
    } catch (e) {
      print('❌ Error verificando postulación: $e');
      return {
        'puede': false,
        'razon': 'Error: $e',
      };
    }
  }

  // ============================================
  // ❌ CANCELAR TRABAJO (cambiar estado a CANCELADO)
  // ============================================

  Future<void> cancelarTrabajo(int idTrabajo) async {
    try {
      final idUsuario = await AuthService.getCurrentUserId();

      // Verificar que sea el empleador
      final trabajo = await supabase
          .from('trabajo')
          .select('empleador_id')
          .eq('id_trabajo', idTrabajo)
          .single();

      if (trabajo['empleador_id'] != idUsuario) {
        throw Exception('No tienes permiso para cancelar este trabajo');
      }

      // Cambiar estado a CANCELADO
      await supabase.from('trabajo').update({
        'estado_publicacion': 'CANCELADO',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_trabajo', idTrabajo);

      print('✅ Trabajo cancelado');
    } catch (e) {
      print('❌ Error al cancelar trabajo: $e');
      throw Exception('Error al cancelar trabajo: $e');
    }
  }

  // ============================================
// ✅ CREAR TRABAJO (CORREGIDO)
// ============================================

  Future<Map<String, dynamic>> createTrabajo(Map<String, dynamic> datos) async {
    try {
      print('📝 Iniciando creación de trabajo...');

      // 1. Crear el pago primero
      final pagoData = {
        'monto': datos['salario'] ?? 0.0, // ✅ Asegurar 0.0
        'metodo': datos['metodo_pago'] ?? 'EFECTIVO', // ✅ Valor por defecto
        'estado': 'PENDIENTE',
        'periodo':
            datos['periodo_pago'] ?? 'POR_TRABAJO', // ✅ Valor por defecto
      };

      print('💰 Creando pago: $pagoData');

      final pagoResponse =
          await supabase.from('pago').insert(pagoData).select().single();

      final idPago = pagoResponse['id_pago'];
      print('✅ Pago creado con ID: $idPago');

      // ✅ 2. FORMATEAR HORARIOS CORRECTAMENTE (agregar :00 para segundos)
      final horarioInicio = datos['horario_inicio'];
      final horarioFin = datos['horario_fin'];

      // Asegurar formato HH:mm:ss para PostgreSQL
      final horarioInicioFormatted =
          horarioInicio.contains(':') && horarioInicio.split(':').length == 2
              ? '$horarioInicio:00'
              : horarioInicio;

      final horarioFinFormatted =
          horarioFin.contains(':') && horarioFin.split(':').length == 2
              ? '$horarioFin:00'
              : horarioFin;

      print(
          '⏰ Horarios formateados: $horarioInicioFormatted - $horarioFinFormatted');

      // 3. Crear el trabajo
      final trabajoData = {
        'empleador_id': datos['empleador_id'],
        'id_pago': idPago,
        'id_rubro': datos['id_rubro'],
        'titulo': datos['titulo'],
        'descripcion': datos['descripcion'],
        'fecha_inicio': datos['fecha_inicio'],
        'fecha_fin': datos['fecha_fin'],
        'horario_inicio': horarioInicioFormatted, // ✅ CORREGIDO
        'horario_fin': horarioFinFormatted, // ✅ CORREGIDO
        'ubicacion_id': datos['ubicacion_id'],
        'metodo_pago': datos['metodo_pago'],
        'cantidad_empleados_requeridos': datos['cantidad_empleados_requeridos'],
        'permite_inicio_incompleto':
            datos['permite_inicio_incompleto'] ?? false,
        'urgencia': datos['urgencia'] ?? 'ESTANDAR',
        'estado_publicacion': 'PUBLICADO',
      };

      print('📝 Creando trabajo: $trabajoData');

      final trabajoResponse =
          await supabase.from('trabajo').insert(trabajoData).select().single();

      print(
          '✅ Trabajo creado exitosamente con ID: ${trabajoResponse['id_trabajo']}');

      return trabajoResponse;
    } catch (e) {
      print('❌ Error al crear trabajo: $e');
      throw Exception('Error al crear trabajo: $e');
    }
  }

  // ============================================
  // ✅ ACTUALIZAR TRABAJO
  // ============================================

  Future<void> updateTrabajo(int idTrabajo, Map<String, dynamic> datos) async {
    try {
      final idUsuario = await AuthService.getCurrentUserId();

      // Verificar que el trabajo pertenece al usuario
      final trabajo = await supabase
          .from('trabajo')
          .select('empleador_id')
          .eq('id_trabajo', idTrabajo)
          .single();

      if (trabajo['empleador_id'] != idUsuario) {
        throw Exception('No tienes permiso para editar este trabajo');
      }

      await supabase.from('trabajo').update(datos).eq('id_trabajo', idTrabajo);

      print('✅ Trabajo actualizado');
    } catch (e) {
      print('❌ Error al actualizar trabajo: $e');
      throw Exception('Error al actualizar trabajo: $e');
    }
  }

  // ============================================
  // ✅ ELIMINAR TRABAJO
  // ============================================

  Future<void> deleteTrabajo(int idTrabajo) async {
    try {
      final idUsuario = await AuthService.getCurrentUserId();

      // Verificar que el trabajo pertenece al usuario
      final trabajo = await supabase
          .from('trabajo')
          .select('empleador_id, id_pago')
          .eq('id_trabajo', idTrabajo)
          .single();

      if (trabajo['empleador_id'] != idUsuario) {
        throw Exception('No tienes permiso para eliminar este trabajo');
      }

      final idPago = trabajo['id_pago'];

      // Eliminar el trabajo
      await supabase.from('trabajo').delete().eq('id_trabajo', idTrabajo);

      // Eliminar el pago asociado
      if (idPago != null) {
        await supabase.from('pago').delete().eq('id_pago', idPago);
      }

      print('✅ Trabajo eliminado');
    } catch (e) {
      print('❌ Error al eliminar trabajo: $e');
      throw Exception('Error al eliminar trabajo: $e');
    }
  }
}
