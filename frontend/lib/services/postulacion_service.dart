// lib/services/postulacion_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/postulacion_model.dart';
import 'auth_service.dart';
import 'chat_service.dart';

class PostulacionService {
  static final _supabase = Supabase.instance.client;
  static final _chatService = ChatService();

  // ========================================
  // 1️⃣ POSTULARSE A UN TRABAJO
  // ========================================
  static Future<void> postularse({
    required int trabajoId,
    String? mensaje,
    double? ofertaPago,
    int? empleadoEmpresaId,
  }) async {
    try {
      print('📤 Intentando postularse al trabajo $trabajoId...');

      final userId = await AuthService.getCurrentUserId();
      print('🧩 ID usuario actual: $userId (${userId.runtimeType})');

      // Verificar que no sea el empleador del trabajo
      final trabajo = await _supabase
          .from('trabajo')
          .select('empleador_id')
          .eq('id_trabajo', trabajoId)
          .single();

      if (trabajo['empleador_id'] == userId) {
        throw Exception('No puedes postularte a tu propio trabajo');
      }

      if (empleadoEmpresaId != null) {
        // ES EMPRESA: Verificar que este empleado específico no esté postulado
        final postulacionExistente = await _supabase
            .from('postulacion')
            .select('id_postulacion, estado')
            .eq('trabajo_id', trabajoId)
            .eq('postulante_id', userId)
            .eq('empleado_empresa_id', empleadoEmpresaId)
            .neq('estado', 'CANCELADO') // ✅ Ignorar canceladas
            .maybeSingle();

        if (postulacionExistente != null) {
          throw Exception('Este empleado ya está postulado a este trabajo');
        }
      } else {
        // ES PERSONA: Verificar que no se haya postulado
        final postulacionExistente = await _supabase
            .from('postulacion')
            .select('id_postulacion, estado')
            .eq('trabajo_id', trabajoId)
            .eq('postulante_id', userId)
            .neq('estado', 'CANCELADO') // ✅ Ignorar canceladas
            .maybeSingle();

        if (postulacionExistente != null) {
          throw Exception('Ya te postulaste a este trabajo');
        }
      }

      // Verificar solapamiento de fechas
      final solapamientos = await verificarSolapamiento(trabajoId, userId);
      if (solapamientos.isNotEmpty) {
        final trabajoSolapado = solapamientos.first;
        throw Exception(
          'Ya tienes un trabajo aceptado en estas fechas: "${trabajoSolapado['titulo']}" '
          '(${trabajoSolapado['fecha_inicio']} - ${trabajoSolapado['fecha_fin']})',
        );
      }

      // Crear postulación y validar resultado
      final response = await _supabase
          .from('postulacion')
          .insert({
            'trabajo_id': trabajoId,
            'postulante_id': userId,
            'mensaje': mensaje,
            'oferta_pago': ofertaPago,
            'empleado_empresa_id': empleadoEmpresaId,
            'estado': 'PENDIENTE',
            'fecha_postulacion': DateTime.now().toIso8601String(),
          })
          .select()
          .single(); // ✅ CAMBIO: single() en lugar de maybeSingle()

      print('🟢 Resultado insert postulación: $response');

      if (response == false) {
        throw Exception(
            '❌ Error: la postulación no se insertó. Revisa permisos RLS o tipos de datos.');
      }

      print('✅ Postulación creada exitosamente en la base de datos.');
    } catch (e) {
      print('❌ Error al postularse: $e');
      rethrow;
    }
  }

  // ========================================
  // 2️⃣ VERIFICAR SOLAPAMIENTO DE FECHAS
  // ========================================
  static Future<List<Map<String, dynamic>>> verificarSolapamiento(
    int trabajoId,
    int userId,
  ) async {
    try {
      final trabajo = await _supabase
          .from('trabajo')
          .select('fecha_inicio, fecha_fin')
          .eq('id_trabajo', trabajoId)
          .single();

      if (trabajo['fecha_inicio'] == null || trabajo['fecha_fin'] == null) {
        return [];
      }

      final result = await _supabase.rpc(
        'verificar_solapamiento_trabajos',
        params: {
          'p_postulante_id': userId,
          'p_fecha_inicio': trabajo['fecha_inicio'],
          'p_fecha_fin': trabajo['fecha_fin'],
          'p_excluir_trabajo': trabajoId,
        },
      );

      return List<Map<String, dynamic>>.from(result ?? []);
    } catch (e) {
      print('❌ Error verificando solapamiento: $e');
      return [];
    }
  }

  static Future<bool> yaEstaPostulado(int trabajoId) async {
    try {
      final userId = await AuthService.getCurrentUserId();

      final result = await _supabase
          .from('postulacion')
          .select('id_postulacion, estado')
          .eq('trabajo_id', trabajoId)
          .eq('postulante_id', userId)
          .neq('estado', 'CANCELADO') // ✅ Esta línea es crítica
          .limit(1);

      return (result as List).isNotEmpty;
    } catch (e) {
      print('❌ Error verificando postulación: $e');
      return false;
    }
  }

  // ========================================
  // 4️⃣ OBTENER ESTADO DE POSTULACIÓN
  // ========================================
  static Future<String?> obtenerEstadoPostulacion(int trabajoId) async {
    try {
      final userId = await AuthService.getCurrentUserId();

      final result = await _supabase
          .from('postulacion')
          .select('estado')
          .eq('trabajo_id', trabajoId)
          .eq('postulante_id', userId)
          .maybeSingle();

      return result?['estado'];
    } catch (e) {
      print('❌ Error obteniendo estado: $e');
      return null;
    }
  }

  // ========================================
  // 5️⃣ CANCELAR POSTULACIÓN
  // ========================================
  static Future<void> cancelarPostulacion(int trabajoId) async {
    try {
      final userId = await AuthService.getCurrentUserId();

      final postulacion = await _supabase
          .from('postulacion')
          .select('estado, fecha_postulacion')
          .eq('trabajo_id', trabajoId)
          .eq('postulante_id', userId)
          .single();

      if (postulacion['estado'] == 'ACEPTADO') {
        final trabajo = await _supabase
            .from('trabajo')
            .select('fecha_inicio')
            .eq('id_trabajo', trabajoId)
            .single();

        final fechaInicio = DateTime.parse(trabajo['fecha_inicio']);
        final diferencia = fechaInicio.difference(DateTime.now());

        if (diferencia.inHours < 24) {
          throw Exception(
            'No puedes cancelar con menos de 24 horas de antelación. '
            'El trabajo inicia en ${diferencia.inHours} horas.',
          );
        }
      }

      await _supabase
          .from('postulacion')
          .update({
            'estado': 'CANCELADO',
            'fecha_cancelacion': DateTime.now().toIso8601String(),
          })
          .eq('trabajo_id', trabajoId)
          .eq('postulante_id', userId);

      print('✅ Postulación cancelada correctamente.');
    } catch (e) {
      print('❌ Error cancelando postulación: $e');
      rethrow;
    }
  }

  static Future<List<PostulacionModel>> getMisPostulaciones({
    String? estado,
  }) async {
    try {
      final userId = await AuthService.getCurrentUserId();

      print('📥 Obteniendo postulaciones del usuario: $userId');

      var query = _supabase.from('postulacion').select('''
      *,
      trabajo:trabajo_id (
        id_trabajo,
        titulo,
        descripcion,
        salario,
        fecha_inicio,
        fecha_fin,
        horario_inicio,
        horario_fin,
        cantidad_empleados_requeridos,
        empleador_id,
        rubro:id_rubro (nombre)
      ),
      empleado_empresa:empleado_empresa_id (
        id_empleado,
        nombre,
        apellido,
        foto_de_perfil,
        relacion
      )
    ''').eq('postulante_id', userId);

      if (estado != null) {
        query = query.eq('estado', estado);
      }

      final result = await query.order('fecha_postulacion', ascending: false);

      print('📦 Total postulaciones obtenidas: ${(result as List).length}');

      // ✅ OBTENER DATOS DEL USUARIO UNA SOLA VEZ
      final usuario = await _supabase.from('usuario').select('''
      id_usuario,
      usuario_persona(
        nombre,
        apellido,
        foto_perfil_url,
        puntaje_promedio
      ),
      usuario_empresa(
        nombre_corporativo,
        puntaje_promedio
      )
    ''').eq('id_usuario', userId).single();

      print('👤 Datos del usuario obtenidos: $usuario');

      return result.map((json) {
        print('🔄 Procesando postulación: ${json['id_postulacion']}');
        print('   - Estado: ${json['estado']}');
        print('   - Empleado empresa ID: ${json['empleado_empresa_id']}');
        print('   - Datos empleado_empresa: ${json['empleado_empresa']}');

        // ✅ CRÍTICO: Copiar empleado_empresa al nivel raíz del JSON
        // porque PostulanteInfo.fromJson lo busca ahí
        final postulacionConDatos = Map<String, dynamic>.from(json);

        // Agregar datos del usuario postulante
        postulacionConDatos['postulante'] = Map<String, dynamic>.from(usuario);

        // ✅ AGREGAR empleado_empresa al postulante para que PostulanteInfo lo encuentre
        if (json['empleado_empresa'] != null) {
          postulacionConDatos['postulante']['empleado_empresa'] =
              json['empleado_empresa'];
          print('   ✅ empleado_empresa agregado a postulante');
        }

        return PostulacionModel.fromJson(postulacionConDatos);
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo postulaciones: $e');
      rethrow;
    }
  }

// ========================================
// 7️⃣ ACEPTAR POSTULACIÓN (empleador)
// ✅ ACTUALIZADO: Con validaciones de estado del trabajo
// ========================================
  static Future<void> aceptarPostulacion(int postulacionId) async {
    try {
      // 1. Obtener datos de la postulación Y del trabajo
      final postulacion = await _supabase.from('postulacion').select('''
          *,
          trabajo:trabajo_id(
            titulo, 
            empleador_id, 
            estado_publicacion,
            fecha_inicio,
            horario_inicio,
            cantidad_empleados_requeridos
          )
        ''').eq('id_postulacion', postulacionId).single();

      final trabajoId = postulacion['trabajo_id'];
      final trabajo = postulacion['trabajo'];

      // ✅ 2. VALIDAR ESTADO DEL TRABAJO
      final estadoTrabajo = trabajo['estado_publicacion'];

      if (estadoTrabajo == 'VENCIDO') {
        throw Exception(
            'No se puede aceptar la postulación. El trabajo está vencido.');
      }

      if (estadoTrabajo == 'FINALIZADO') {
        throw Exception(
            'No se puede aceptar la postulación. El trabajo ya finalizó.');
      }

      if (estadoTrabajo == 'CANCELADO') {
        throw Exception(
            'No se puede aceptar la postulación. El trabajo fue cancelado.');
      }

      // ✅ 3. VALIDAR SI EL TRABAJO YA COMENZÓ
      final fechaInicio = trabajo['fecha_inicio'];
      final horarioInicio = trabajo['horario_inicio'];

      if (fechaInicio != null) {
        final fechaInicioDate = DateTime.parse(fechaInicio);
        DateTime fechaHoraInicio;

        if (horarioInicio != null) {
          // Parsear horario (formato HH:mm:ss o HH:mm)
          final partes = horarioInicio.toString().split(':');
          final hora = int.parse(partes[0]);
          final minuto = int.parse(partes[1]);

          fechaHoraInicio = DateTime(
            fechaInicioDate.year,
            fechaInicioDate.month,
            fechaInicioDate.day,
            hora,
            minuto,
          );
        } else {
          fechaHoraInicio = fechaInicioDate;
        }

        // Verificar si ya comenzó
        if (DateTime.now().isAfter(fechaHoraInicio)) {
          throw Exception(
              'No se puede aceptar la postulación. El trabajo ya comenzó.');
        }
      }

      // ✅ 4. VERIFICAR PUESTOS DISPONIBLES
      final puestos = await obtenerPuestosDisponibles(trabajoId);

      if ((puestos['disponibles'] ?? 0) <= 0) {
        throw Exception(
            'No se puede aceptar la postulación. No hay puestos disponibles (trabajo completo).');
      }

      // ✅ 5. ACTUALIZAR ESTADO DE LA POSTULACIÓN
      await _supabase.from('postulacion').update({
        'estado': 'ACEPTADO',
        'fecha_respuesta': DateTime.now().toIso8601String(),
      }).eq('id_postulacion', postulacionId);

      print('✅ Postulación aceptada.');

      // ✅ 6. CREAR O OBTENER CONVERSACIÓN
      try {
        final conversacion =
            await _chatService.obtenerOCrearConversacion(postulacionId);
        print('✅ Conversación creada/obtenida: ${conversacion.idConversacion}');

        // ✅ 7. ENVIAR MENSAJE AUTOMÁTICO
        final tituloTrabajo = trabajo['titulo'] ?? 'el trabajo';
        final empleadorId = trabajo['empleador_id'];

        if (empleadorId != null) {
          await _chatService.enviarMensaje(
            conversacionId: conversacion.idConversacion,
            remitenteId: empleadorId,
            contenido:
                '¡Felicitaciones! 🎉 Has sido seleccionado para "$tituloTrabajo". Cualquier duda, escríbeme por aquí.',
          );
          print('✅ Mensaje automático enviado');
        }
      } catch (e) {
        print('⚠️ Error creando chat/mensaje automático: $e');
        // No lanzar excepción, la postulación ya fue aceptada
      }
    } catch (e) {
      print('❌ Error aceptando postulación: $e');
      rethrow;
    }
  }

  // ========================================
  // 8️⃣ RECHAZAR POSTULACIÓN
  // ========================================
  static Future<void> rechazarPostulacion(int postulacionId) async {
    try {
      await _supabase.from('postulacion').update({
        'estado': 'RECHAZADO',
        'fecha_respuesta': DateTime.now().toIso8601String(),
      }).eq('id_postulacion', postulacionId);

      print('✅ Postulación rechazada.');
      // ❌ NO se crea conversación ni se envía mensaje
    } catch (e) {
      print('❌ Error rechazando postulación: $e');
      rethrow;
    }
  }

  static Future<List<PostulacionModel>> getPostulacionesDeTrabajo(
    int trabajoId,
  ) async {
    try {
      print('🔍 Obteniendo postulaciones para trabajo: $trabajoId');

      final postulaciones = await _supabase
          .from('postulacion')
          .select('''
        *,
        empleado_empresa:empleado_empresa_id (
          id_empleado,
          nombre,
          apellido,
          foto_de_perfil,
          relacion
        )
      ''')
          .eq('trabajo_id', trabajoId)
          .order('fecha_postulacion', ascending: false);

      print('✅ ${(postulaciones as List).length} postulaciones encontradas');

      List<PostulacionModel> postulacionesCompletas = [];

      for (var postulacionJson in (postulaciones as List)) {
        final postulanteId = postulacionJson['postulante_id'];
        print('   🔍 Buscando datos de usuario $postulanteId...');

        try {
          final usuario = await _supabase.from('usuario').select('''
            id_usuario,
            usuario_persona(
              nombre,
              apellido,
              foto_perfil_url,
              puntaje_promedio
            ),
            usuario_empresa(
              nombre_corporativo,
              puntaje_promedio
            )
          ''').eq('id_usuario', postulanteId).single();

          print('   ✅ Usuario encontrado: $usuario');

          // ✅ CRÍTICO: Crear copia para no mutar la lista original
          final postulacionConDatos =
              Map<String, dynamic>.from(postulacionJson);
          postulacionConDatos['postulante'] =
              Map<String, dynamic>.from(usuario);

          // ✅ CRÍTICO: Pasar empleado_empresa al postulante para que PostulanteInfo lo encuentre
          if (postulacionJson['empleado_empresa'] != null) {
            postulacionConDatos['postulante']['empleado_empresa'] =
                postulacionJson['empleado_empresa'];
            print('   ✅ empleado_empresa agregado a postulante');
          }

          postulacionesCompletas
              .add(PostulacionModel.fromJson(postulacionConDatos));
        } catch (e) {
          print('   ⚠️ Error obteniendo usuario $postulanteId: $e');
          postulacionesCompletas
              .add(PostulacionModel.fromJson(postulacionJson));
        }
      }

      print('✅ Total procesadas: ${postulacionesCompletas.length}');
      return postulacionesCompletas;
    } catch (e) {
      print('❌ Error obteniendo postulaciones del trabajo: $e');
      rethrow;
    }
  }

  static Future<Map<String, int>> obtenerPuestosDisponibles(
    int trabajoId,
  ) async {
    try {
      final result = await _supabase.rpc(
        'obtener_puestos_disponibles',
        params: {'p_id_trabajo': trabajoId},
      );

      if (result == null || result.isEmpty) {
        return {'totales': 1, 'ocupados': 0, 'disponibles': 1};
      }

      final data = result[0];
      return {
        'totales': data['puestos_totales'] ?? 1,
        'ocupados': data['puestos_ocupados'] ?? 0,
        'disponibles': data['puestos_disponibles'] ?? 1,
      };
    } catch (e) {
      print('❌ Error obteniendo puestos: $e');
      return {'totales': 1, 'ocupados': 0, 'disponibles': 1};
    }
  }
}
