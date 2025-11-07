// lib/services/postulacion_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/postulacion_model.dart';
import 'auth_service.dart';

class PostulacionService {
  static final _supabase = Supabase.instance.client;

  // ========================================
  // 1️⃣ POSTULARSE A UN TRABAJO
  // ========================================
  static Future<void> postularse({
    required int trabajoId,
    String? mensaje,
    double? ofertaPago,
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

      // Verificar si ya está postulado
      final postulacionExistente = await _supabase
          .from('postulacion')
          .select('id_postulacion')
          .eq('trabajo_id', trabajoId)
          .eq('postulante_id', userId)
          .maybeSingle();

      if (postulacionExistente != null) {
        throw Exception('Ya te postulaste a este trabajo');
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
            'estado': 'PENDIENTE',
            'fecha_postulacion': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();

      print('🟢 Resultado insert postulación: $response');

      if (response == null) {
        throw Exception('❌ Error: la postulación no se insertó. Revisa permisos RLS o tipos de datos.');
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

  // ========================================
  // 3️⃣ VERIFICAR SI YA ESTÁ POSTULADO
  // ========================================
  static Future<bool> yaEstaPostulado(int trabajoId) async {
    try {
      final userId = await AuthService.getCurrentUserId();

      final result = await _supabase
          .from('postulacion')
          .select('postulante_id')
          .eq('trabajo_id', trabajoId)
          .eq('postulante_id', userId)
          .maybeSingle();

      return result != null;
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

  // ========================================
  // 6️⃣ OBTENER MIS POSTULACIONES
  // ========================================
  static Future<List<PostulacionModel>> getMisPostulaciones({
    String? estado,
  }) async {
    try {
      final userId = await AuthService.getCurrentUserId();

      var query = _supabase
          .from('postulacion')
          .select('''
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
              rubro:id_rubro (nombre),
              ubicacion:id_ubicacion (calle, numero, ciudad)
            )
          ''')
          .eq('postulante_id', userId);

      if (estado != null) {
        query = query.eq('estado', estado);
      }

      final result = await query.order('fecha_postulacion', ascending: false);

      return result
          .map((json) => PostulacionModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo postulaciones: $e');
      rethrow;
    }
  }

  // ========================================
  // 7️⃣ ACEPTAR POSTULACIÓN (empleador)
  // ========================================
  static Future<void> aceptarPostulacion(int postulacionId) async {
    try {
      final postulacion = await _supabase
          .from('postulacion')
          .select('trabajo_id')
          .eq('id_postulacion', postulacionId)
          .single();

      final trabajoId = postulacion['trabajo_id'];
      final puestos = await obtenerPuestosDisponibles(trabajoId);

      if ((puestos['disponibles'] ?? 0) <= 0) {
        throw Exception('No hay puestos disponibles');
      }

      await _supabase
          .from('postulacion')
          .update({
            'estado': 'ACEPTADO',
            'fecha_respuesta': DateTime.now().toIso8601String(),
          })
          .eq('id_postulacion', postulacionId);

      print('✅ Postulación aceptada.');
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
      await _supabase
          .from('postulacion')
          .update({
            'estado': 'RECHAZADO',
            'fecha_respuesta': DateTime.now().toIso8601String(),
          })
          .eq('id_postulacion', postulacionId);

      print('✅ Postulación rechazada.');
    } catch (e) {
      print('❌ Error rechazando postulación: $e');
      rethrow;
    }
  }

  // ========================================
  // 9️⃣ OBTENER POSTULACIONES DE UN TRABAJO (para empleador)
  // ✅ MÉTODO ALTERNATIVO: 2 Queries separadas (más robusto)
  // ========================================
  static Future<List<PostulacionModel>> getPostulacionesDeTrabajo(
    int trabajoId,
  ) async {
    try {
      print('🔍 Obteniendo postulaciones para trabajo: $trabajoId');
      
      // ✅ PASO 1: Obtener postulaciones básicas
      final postulaciones = await _supabase
          .from('postulacion')
          .select('*')
          .eq('trabajo_id', trabajoId)
          .order('fecha_postulacion', ascending: false);

      print('✅ ${(postulaciones as List).length} postulaciones encontradas');

      // ✅ PASO 2: Para cada postulación, obtener datos del usuario
      List<PostulacionModel> postulacionesCompletas = [];
      
      for (var postulacionJson in (postulaciones as List)) {
        final postulanteId = postulacionJson['postulante_id'];
        print('   🔍 Buscando datos de usuario $postulanteId...');
        
        try {
          // Obtener datos del usuario
          final usuario = await _supabase
              .from('usuario')
              .select('''
                id_usuario,
                usuario_persona(
                  nombre,
                  apellido,
                  foto_perfil_url,
                  puntaje_promedio
                ),
                usuario_empresa(
                  nombre_corporativo
                )
              ''')
              .eq('id_usuario', postulanteId)
              .single();
          
          print('   ✅ Usuario encontrado: $usuario');
          
          // Agregar datos del usuario al JSON de la postulación
          postulacionJson['postulante'] = usuario;
          
          // Crear modelo
          postulacionesCompletas.add(PostulacionModel.fromJson(postulacionJson));
          
        } catch (e) {
          print('   ⚠️ Error obteniendo usuario $postulanteId: $e');
          // Agregar postulación sin datos de usuario
          postulacionesCompletas.add(PostulacionModel.fromJson(postulacionJson));
        }
      }

      print('✅ Total procesadas: ${postulacionesCompletas.length}');
      return postulacionesCompletas;
      
    } catch (e) {
      print('❌ Error obteniendo postulaciones del trabajo: $e');
      rethrow;
    }
  }

  // ========================================
  // 🔟 OBTENER PUESTOS DISPONIBLES
  // ========================================
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