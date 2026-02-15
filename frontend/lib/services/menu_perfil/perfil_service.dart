// lib/services/perfil_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/menu_perfil/perfil_model.dart';

class PerfilService {
  final _supabase = Supabase.instance.client;

  // ========================================
  // 👤 OBTENER DATOS BÁSICOS DEL USUARIO
  // ========================================
  Future<Map<String, dynamic>> getDatosBasicosUsuario(int userId) async {
    try {
      print('📊 Obteniendo datos básicos del usuario ID: $userId');

      // Obtener el usuario con sus relaciones
      final response = await _supabase
          .from('usuario')
          .select('''
            id_usuario,
            usuario_persona(
              nombre,
              apellido,
              fecha_nacimiento,
              genero
            ),
            usuario_empresa(
              nombre_corporativo,
              descripcion
            )
          ''')
          .eq('id_usuario', userId)
          .single();

      print('✅ Datos básicos obtenidos');
      return response;
    } catch (e) {
      print('❌ Error al obtener datos básicos: $e');
      rethrow;
    }
  }

  // ========================================
  // ⭐ OBTENER RESEÑAS DEL USUARIO
  // ========================================
  Future<List<ReseniaModel>> getReseniasUsuario(int userId) async {
    try {
      print('📊 Obteniendo reseñas del usuario ID: $userId');

      final response = await _supabase
          .from('calificacion')
          .select('''
            id_calificacion,
            puntuacion,
            comentario,
            recomendacion,
            fecha,
            emisor:emisor_id!inner(
              usuario_persona(
                nombre,
                apellido,
                foto_perfil_url
              ),
              usuario_empresa(
                nombre_corporativo
              )
            ),
            trabajo:trabajo_id(
              titulo
            )
          ''')
          .eq('receptor_id', userId)
          .order('fecha', ascending: false);

      print('✅ ${response.length} reseñas obtenidas');

      return (response as List)
          .map((json) => ReseniaModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error al obtener reseñas: $e');
      return [];
    }
  }

  // ========================================
  // 📊 CALCULAR PROMEDIO DE CALIFICACIÓN
  // ========================================
  Future<double> getPromedioCalificacion(int userId) async {
    try {
      final resenias = await getReseniasUsuario(userId);
      
      if (resenias.isEmpty) return 0.0;

      final suma = resenias.fold<int>(
        0,
        (total, resenia) => total + resenia.puntuacion, // ✅ Cambiado de 'calificacion' a 'puntuacion'
      );

      return suma / resenias.length;
    } catch (e) {
      print('❌ Error al calcular promedio: $e');
      return 0.0;
    }
  }

  // ========================================
  // 🏷️ OBTENER CATEGORÍAS DEL EMPLEADO
  // ========================================
  Future<List<CategoriaModel>> getCategoriasEmpleado(int empleadoId) async {
    try {
      print('📊 Obteniendo categorías del empleado ID: $empleadoId');

      // Primero verificar que existe la tabla empleado_categoria
      final response = await _supabase
          .from('empleado_categoria')
          .select('''
            categoria:id_categoria(
              id_categoria,
              nombre,
              descripcion,
              icono
            )
          ''')
          .eq('empleado_id', empleadoId);

      print('✅ ${response.length} categorías obtenidas');

      return (response as List)
          .map((item) => CategoriaModel.fromJson(item['categoria']))
          .toList();
    } catch (e) {
      print('❌ Error al obtener categorías: $e');
      return [];
    }
  }

  // ========================================
  // 📈 CONTAR TRABAJOS COMPLETADOS
  // ========================================
  Future<int> contarTrabajosCompletados(int userId) async {
    try {
      print('📊 Contando trabajos completados del usuario ID: $userId');

      final response = await _supabase
          .from('postulacion')
          .select('id_postulacion')
          .eq('empleado_id', userId)
          .eq('estado', 'COMPLETADO');

      print('✅ ${response.length} trabajos completados');
      return response.length;
    } catch (e) {
      print('❌ Error al contar trabajos: $e');
      return 0;
    }
  }

  // ========================================
  // 📍 OBTENER UBICACIÓN DEL USUARIO
  // ========================================
  Future<String?> getUbicacionUsuario(int userId) async {
    try {
      print('📊 Obteniendo ubicación del usuario ID: $userId');

      // Intentar obtener desde empleado primero
      try {
        final empleadoResponse = await _supabase
            .from('empleado')
            .select('''
              ubicacion:ubicacion_id(
                ciudad,
                provincia
              )
            ''')
            .eq('id_usuario', userId)
            .maybeSingle();

        if (empleadoResponse != null && empleadoResponse['ubicacion'] != null) {
          final ubicacion = empleadoResponse['ubicacion'];
          return '${ubicacion['ciudad']}, ${ubicacion['provincia']}';
        }
      } catch (e) {
        print('No se encontró ubicación en empleado');
      }

      // Si no, intentar desde empleador
      try {
        final empleadorResponse = await _supabase
            .from('empleador')
            .select('''
              ubicacion:ubicacion_id(
                ciudad,
                provincia
              )
            ''')
            .eq('id_usuario', userId)
            .maybeSingle();

        if (empleadorResponse != null && empleadorResponse['ubicacion'] != null) {
          final ubicacion = empleadorResponse['ubicacion'];
          return '${ubicacion['ciudad']}, ${ubicacion['provincia']}';
        }
      } catch (e) {
        print('No se encontró ubicación en empleador');
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener ubicación: $e');
      return null;
    }
  }

  // ========================================
  // 📧 VERIFICAR SI ES EMPLEADO
  // ========================================
  Future<bool> esEmpleado(int userId) async {
    try {
      final response = await _supabase
          .from('empleado')
          .select('id_empleado')
          .eq('id_usuario', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error al verificar empleado: $e');
      return false;
    }
  }

  // ========================================
  // 🏢 VERIFICAR SI ES EMPLEADOR
  // ========================================
  Future<bool> esEmpleador(int userId) async {
    try {
      final response = await _supabase
          .from('empleador')
          .select('id_empleador')
          .eq('id_usuario', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error al verificar empleador: $e');
      return false;
    }
  }

  // ========================================
  // 📊 OBTENER PERFIL COMPLETO
  // ========================================
  Future<Map<String, dynamic>> obtenerPerfilCompleto(int userId) async {
    try {
      print('📊 Obteniendo perfil completo del usuario ID: $userId');

      final datosBasicos = await getDatosBasicosUsuario(userId);
      final resenias = await getReseniasUsuario(userId);
      final promedio = await getPromedioCalificacion(userId);
      final ubicacion = await getUbicacionUsuario(userId);
      final esEmpleadoResult = await esEmpleado(userId);
      final esEmpleadorResult = await esEmpleador(userId);

      int trabajosCompletados = 0;
      List<CategoriaModel> categorias = [];

      if (esEmpleadoResult) {
        trabajosCompletados = await contarTrabajosCompletados(userId);
        categorias = await getCategoriasEmpleado(userId);
      }

      return {
        'datosBasicos': datosBasicos,
        'resenias': resenias,
        'promedio': promedio,
        'ubicacion': ubicacion,
        'esEmpleado': esEmpleadoResult,
        'esEmpleador': esEmpleadorResult,
        'trabajosCompletados': trabajosCompletados,
        'categorias': categorias,
      };
    } catch (e) {
      print('❌ Error al obtener perfil completo: $e');
      rethrow;
    }
  }

  // ========================================
  // 📝 OBTENER RESEÑAS (ALIAS)
  // ========================================
  Future<List<ReseniaModel>> obtenerResenias(int userId) async {
    return await getReseniasUsuario(userId);
  }

  // ========================================
  // 🏷️ OBTENER CATEGORÍAS (ALIAS)
  // ========================================
  Future<List<CategoriaModel>> obtenerCategorias(int userId) async {
    return await getCategoriasEmpleado(userId);
  }

  // ========================================
  // 📊 OBTENER ESTADÍSTICAS
  // ========================================
  Future<Map<String, dynamic>> obtenerEstadisticas(int userId) async {
    try {
      print('📊 Obteniendo estadísticas del usuario ID: $userId');

      final trabajosCompletados = await contarTrabajosCompletados(userId);
      final promedio = await getPromedioCalificacion(userId);
      final totalResenias = (await getReseniasUsuario(userId)).length;

      return {
        'trabajosCompletados': trabajosCompletados,
        'promedioCalificacion': promedio,
        'totalResenias': totalResenias,
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {
        'trabajosCompletados': 0,
        'promedioCalificacion': 0.0,
        'totalResenias': 0,
      };
    }
  }
}