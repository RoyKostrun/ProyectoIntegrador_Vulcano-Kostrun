// lib/services/trabajo_service.dart
// ✅ ACTUALIZADO con sistema de estados

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trabajo_model.dart';
import 'auth_service.dart';

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
            pago:id_pago(id_pago, monto, metodo, estado),
            usuario!trabajo_empleador_id_fkey(
              id_usuario,
              usuario_persona(
                nombre,
                apellido
              ),
              usuario_empresa(
                nombre_corporativo
              )
            )
          ''')
          .neq('empleador_id', idUsuario)
          .eq('estado_publicacion', 'PUBLICADO') // ✅ SOLO PUBLICADO
          .range(from, to)
          .order('created_at', ascending: false);

      print('✅ Trabajos encontrados: ${(response as List).length}');
      
      return (response as List)
          .map((json) {
            // Procesar nombre del empleador
            String? nombreEmpleador;
            
            if (json['usuario'] != null) {
              final usuario = json['usuario'];
              
              if (usuario['usuario_persona'] != null && 
                  (usuario['usuario_persona'] is List && 
                   (usuario['usuario_persona'] as List).isNotEmpty)) {
                final persona = (usuario['usuario_persona'] as List)[0];
                nombreEmpleador = '${persona['nombre']} ${persona['apellido']}';
              } 
              else if (usuario['usuario_empresa'] != null && 
                       (usuario['usuario_empresa'] is List && 
                        (usuario['usuario_empresa'] as List).isNotEmpty)) {
                final empresa = (usuario['usuario_empresa'] as List)[0];
                nombreEmpleador = empresa['nombre_corporativo'];
              }
            }
            
            json['nombre_empleador_procesado'] = nombreEmpleador;
            
            return TrabajoModel.fromJson(json);
          })
          .toList();
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
    String? filtroEstado, // Opcional: filtrar por estado
  }) async {
    try {
      final idUsuario = await AuthService.getCurrentUserId();
      
      print('🔍 Cargando mis trabajos donde empleador_id = $idUsuario');

      var query = supabase
          .from('trabajo')
          .select('''
            *,
            rubro:id_rubro(id_rubro, nombre),
            ubicacion:ubicacion_id(id_ubicacion, nombre, calle, numero, ciudad, provincia),
            pago:id_pago(id_pago, monto, metodo, estado),
            usuario!trabajo_empleador_id_fkey(
              id_usuario,
              usuario_persona(
                nombre,
                apellido
              ),
              usuario_empresa(
                nombre_corporativo
              )
            )
          ''')
          .eq('empleador_id', idUsuario);

      // Filtro opcional por estado
      if (filtroEstado != null) {
        query = query.eq('estado_publicacion', filtroEstado);
      }

      final response = await query
          .range(from, to)
          .order('created_at', ascending: false);

      print('✅ Mis trabajos encontrados: ${(response as List).length}');

      final trabajos = (response as List)
          .map((json) {
            // Procesar nombre del empleador
            String? nombreEmpleador;
            
            if (json['usuario'] != null) {
              final usuario = json['usuario'];
              
              if (usuario['usuario_persona'] != null && 
                  (usuario['usuario_persona'] is List && 
                   (usuario['usuario_persona'] as List).isNotEmpty)) {
                final persona = (usuario['usuario_persona'] as List)[0];
                nombreEmpleador = '${persona['nombre']} ${persona['apellido']}';
              } 
              else if (usuario['usuario_empresa'] != null && 
                       (usuario['usuario_empresa'] is List && 
                        (usuario['usuario_empresa'] as List).isNotEmpty)) {
                final empresa = (usuario['usuario_empresa'] as List)[0];
                nombreEmpleador = empresa['nombre_corporativo'];
              }
            }
            
            json['nombre_empleador_procesado'] = nombreEmpleador;
            
            return TrabajoModel.fromJson(json);
          })
          .toList();

      // ✅ Ordenar por prioridad de estado
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
      
      final response = await supabase
          .rpc('puede_postularse_a_trabajo', params: {
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
      await supabase
          .from('trabajo')
          .update({
            'estado_publicacion': 'CANCELADO',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_trabajo', idTrabajo);

      print('✅ Trabajo cancelado');
      
    } catch (e) {
      print('❌ Error al cancelar trabajo: $e');
      throw Exception('Error al cancelar trabajo: $e');
    }
  }

  // ============================================
  // ✅ CREAR TRABAJO
  // ============================================
  
  Future<void> createTrabajo(Map<String, dynamic> datos) async {
    try {
      print('📝 Iniciando creación de trabajo...');

      // 1. Crear el pago primero
      final pagoData = {
        'monto': datos['salario'] ?? 0,
        'metodo': datos['metodo_pago'],
        'estado': 'PENDIENTE',
        'periodo': datos['periodo_pago'],
      };

      print('💰 Creando pago: $pagoData');

      final pagoResponse = await supabase
          .from('pago')
          .insert(pagoData)
          .select()
          .single();

      final idPago = pagoResponse['id_pago'];
      print('✅ Pago creado con ID: $idPago');

      // 2. Crear el trabajo
      final trabajoData = {
        'empleador_id': datos['empleador_id'],
        'id_pago': idPago,
        'id_rubro': datos['id_rubro'],
        'titulo': datos['titulo'],
        'descripcion': datos['descripcion'],
        'fecha_inicio': datos['fecha_inicio'],
        'fecha_fin': datos['fecha_fin'],
        'horario_inicio': datos['horario_inicio'],
        'horario_fin': datos['horario_fin'],
        'ubicacion_id': datos['ubicacion_id'],
        'metodo_pago': datos['metodo_pago'],
        'cantidad_empleados_requeridos': datos['cantidad_empleados_requeridos'],
        'urgencia': datos['urgencia'] ?? 'ESTANDAR',
        'estado_publicacion': 'PUBLICADO', // ✅ Siempre inicia como PUBLICADO
      };

      print('📝 Creando trabajo: $trabajoData');

      await supabase.from('trabajo').insert(trabajoData);

      print('✅ Trabajo creado exitosamente');
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

      await supabase
          .from('trabajo')
          .update(datos)
          .eq('id_trabajo', idTrabajo);

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
      await supabase
          .from('trabajo')
          .delete()
          .eq('id_trabajo', idTrabajo);

      // Eliminar el pago asociado
      if (idPago != null) {
        await supabase
            .from('pago')
            .delete()
            .eq('id_pago', idPago);
      }

      print('✅ Trabajo eliminado');
    } catch (e) {
      print('❌ Error al eliminar trabajo: $e');
      throw Exception('Error al eliminar trabajo: $e');
    }
  }
}