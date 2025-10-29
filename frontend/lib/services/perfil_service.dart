// lib/services/perfil_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilService {
  final _supabase = Supabase.instance.client;

  // ==============================================================
  // 🔹 OBTENER DATOS COMPLETOS DEL PERFIL
  // ==============================================================
  Future<Map<String, dynamic>> obtenerPerfilCompleto(int userId) async {
    try {
      print('📊 Obteniendo perfil completo para usuario ID: $userId');

      // Obtener datos del usuario
      final response = await _supabase
          .from('usuario')
          .select('''
            id_usuario,
            cantidad_trabajos_realizados,
            usuario_persona!inner(
              nombre,
              apellido,
              username,
              foto_perfil_url,
              puntaje_promedio
            )
          ''')
          .eq('id_usuario', userId)
          .single();

      print('✅ Datos del perfil obtenidos');
      
      return {
        'id_usuario': response['id_usuario'],
        'nombre': response['usuario_persona']['nombre'],
        'apellido': response['usuario_persona']['apellido'],
        'username': response['usuario_persona']['username'],
        'foto_perfil_url': response['usuario_persona']['foto_perfil_url'],
        'puntaje_promedio': response['usuario_persona']['puntaje_promedio'],
        'cantidad_trabajos_realizados': response['cantidad_trabajos_realizados'],
      };
    } catch (e) {
      print('❌ Error al obtener perfil completo: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 OBTENER RESEÑAS DEL USUARIO
  // ==============================================================
  Future<List<Map<String, dynamic>>> obtenerResenias(int userId) async {
    try {
      print('📝 Obteniendo reseñas para usuario ID: $userId');

      final response = await _supabase
          .from('calificacion')
          .select('''
            id_calificacion,
            puntuacion,
            comentario,
            recomendacion,
            fecha,
            id_emisor,
            emisor:usuario!calificacion_id_emisor_fkey(
              id_usuario,
              usuario_persona(
                nombre,
                apellido,
                foto_perfil_url
              ),
              usuario_empresa(
                nombre_corporativo
              )
            ),
            trabajo:publicacion!calificacion_id_publicacion_fkey(
              id_trabajo,
              titulo
            )
          ''')
          .eq('id_receptor', userId)
          .order('fecha', ascending: false);

      print('✅ ${response.length} reseñas obtenidas');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error al obtener reseñas: $e');
      return [];
    }
  }

  // ==============================================================
  // 🔹 OBTENER CATEGORÍAS/RUBROS DEL USUARIO
  // ==============================================================
  Future<List<Map<String, dynamic>>> obtenerCategorias(int userId) async {
    try {
      print('📂 Obteniendo categorías para usuario ID: $userId');

      final response = await _supabase
          .from('usuario_rubro')
          .select('''
            id_usuario_rubro,
            fecha_asignacion,
            activo,
            rubro!inner(
              id_rubro,
              nombre,
              descripcion
            )
          ''')
          .eq('id_usuario', userId)
          .eq('activo', true)
          .order('fecha_asignacion', ascending: false);

      print('✅ ${response.length} categorías obtenidas');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error al obtener categorías: $e');
      return [];
    }
  }

  // ==============================================================
  // 🔹 OBTENER ESTADÍSTICAS DEL USUARIO
  // ==============================================================
  Future<Map<String, dynamic>> obtenerEstadisticas(int userId) async {
    try {
      print('📈 Obteniendo estadísticas para usuario ID: $userId');

      // Contar trabajos completados
      final trabajosCompletados = await _supabase
          .from('postulacion')
          .select('id_postulacion')
          .eq('postulante_id', userId)
          .eq('estado', 'ACEPTADO');

      // Contar total de postulaciones
      final totalPostulaciones = await _supabase
          .from('postulacion')
          .select('id_postulacion')
          .eq('postulante_id', userId);

      // Contar reseñas recibidas
      final totalResenias = await _supabase
          .from('calificacion')
          .select('id_calificacion')
          .eq('id_receptor', userId);

      print('✅ Estadísticas obtenidas');

      return {
        'trabajos_completados': trabajosCompletados.length,
        'total_postulaciones': totalPostulaciones.length,
        'total_reseñas': totalResenias.length,
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {
        'trabajos_completados': 0,
        'total_postulaciones': 0,
        'total_reseñas': 0,
      };
    }
  }
}