// lib/services/user_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as AppUser;
import 'auth_service.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==============================================================
  // 🔹 ACTUALIZAR DISPONIBILIDAD (usa id_usuario y función RPC segura)
  // ==============================================================
  Future<bool> actualizarDisponibilidad({
    required bool disponible,
  }) async {
    try {
      // Obtener el id_usuario actual desde AuthService
      final idUsuario = await AuthService.getCurrentUserId();

      if (idUsuario == null) {
        print('❌ No se encontró el ID del usuario actual');
        return false;
      }

      final nuevoEstado = disponible ? 'ACTIVO' : 'INACTIVO';

      // Llamar a la función RPC (usa id_usuario y disponibilidad)
      final response = await _supabase.rpc(
        'actualizar_disponibilidad',
        params: {
          'p_id_usuario': idUsuario,
          'p_disponibilidad': nuevoEstado,
        },
      );

      // Si la función no devuelve nada (void), igual consideramos éxito
      if (response == null) return true;

      // Si devuelve un resultado de éxito explícito
      if (response is Map && response['success'] == true) return true;
      if (response is List && response.isNotEmpty) return true;

      return true; // Si no hubo errores
    } catch (e) {
      print('Error al actualizar disponibilidad: $e');
      return false;
    }
  }

  // ==============================================================
  // 🔹 ACTUALIZAR DISPONIBILIDAD POR ID_PERSONA (versión alternativa directa)
  // ==============================================================
  Future<bool> actualizarDisponibilidadPorId({
    required int idPersona,
    required bool disponible,
  }) async {
    try {
      final nuevoEstado = disponible ? 'ACTIVO' : 'INACTIVO';

      final response = await _supabase
          .from('usuario_persona')
          .update({
            'disponibilidad': nuevoEstado,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_persona', idPersona)
          .select();

      if (response.isEmpty) {
        throw Exception('No se pudo actualizar la disponibilidad');
      }

      return true;
    } catch (e) {
      print('Error al actualizar disponibilidad: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 OBTENER USUARIO ACTUAL (por email de sesión)
  // ==============================================================
  Future<AppUser.User?> obtenerUsuarioActual() async {
    try {
      print('=== INICIO obtenerUsuarioActual ===');

      final session = _supabase.auth.currentSession;
      print('Sesión: ${session != null ? "Activa" : "No hay sesión"}');

      if (session == null) {
        print('❌ No hay sesión activa');
        return null;
      }

      final email = session.user.email;
      print('Email de sesión: $email');

      if (email == null) {
        print('❌ No hay email en la sesión');
        return null;
      }

      print('🔍 Buscando usuario con email: $email');

      final response = await _supabase
          .from('usuario')
          .select('''
            *,
            usuario_persona (*),
            usuario_empresa (*)
          ''')
          .eq('email', email);

      print('📦 Tipo de respuesta: ${response.runtimeType}');

      if (response is List) {
        print('Es una lista con ${response.length} elementos');

        if (response.isEmpty) {
          print('❌ Lista vacía - no se encontró usuario');
          return null;
        }

        final userData = response.first;
        print('✅ Usuario encontrado');

        final user = AppUser.User.fromJson(userData);
        print('✅ Usuario creado exitosamente');
        return user;
      }

      print('❌ Formato inesperado de respuesta');
      return null;
    } catch (e, stackTrace) {
      print('❌ ERROR en obtenerUsuarioActual: $e');
      print('Stack: $stackTrace');
      return null;
    }
  }

  // ==============================================================
  // 🔹 CONSULTAR SI ESTÁ DISPONIBLE
  // ==============================================================
  Future<bool> estaDisponible(int idPersona) async {
    try {
      final response = await _supabase
          .from('usuario_persona')
          .select('disponibilidad')
          .eq('id_persona', idPersona)
          .single();

      return response['disponibilidad'] == 'ACTIVO';
    } catch (e) {
      print('Error al verificar disponibilidad: $e');
      return false;
    }
  }

  // ==============================================================
  // 🔹 OBTENER EMPLEADOS DISPONIBLES
  // ==============================================================
  Future<List<AppUser.UserPersona>> obtenerEmpleadosDisponibles({
    int? rubroId,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase.rpc(
        'obtener_empleados_disponibles',
        params: {
          'p_rubro_id': rubroId,
          'p_limit': limit,
        },
      );

      if (response == null || response is! List) {
        return [];
      }

      return (response as List)
          .map((json) => AppUser.UserPersona.fromJson(json))
          .toList();
    } catch (e) {
      print('Error al obtener empleados disponibles: $e');

      // Fallback: usar query directa
      try {
        List<dynamic> response;

        if (rubroId != null) {
          response = await _supabase
              .from('usuario_persona')
              .select()
              .eq('disponibilidad', 'ACTIVO')
              .eq('es_empleado', true)
              .eq('rubro_id', rubroId)
              .limit(limit);
        } else {
          response = await _supabase
              .from('usuario_persona')
              .select()
              .eq('disponibilidad', 'ACTIVO')
              .eq('es_empleado', true)
              .limit(limit);
        }

        return (response as List)
            .map((json) => AppUser.UserPersona.fromJson(json))
            .toList();
      } catch (fallbackError) {
        print('Error en fallback: $fallbackError');
        return [];
      }
    }
  }

  // ==============================================================
  // 🔹 ACTUALIZAR PERFIL PERSONA
  // ==============================================================
  Future<bool> actualizarPerfilPersona({
    required int idPersona,
    required Map<String, dynamic> datos,
  }) async {
    try {
      datos['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('usuario_persona')
          .update(datos)
          .eq('id_persona', idPersona)
          .select();

      return response.isNotEmpty;
    } catch (e) {
      print('Error al actualizar perfil: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 ESCUCHAR DISPONIBILIDAD EN TIEMPO REAL
  // ==============================================================
  Stream<String> escucharDisponibilidad(int idPersona) {
    return _supabase
        .from('usuario_persona')
        .stream(primaryKey: ['id_persona'])
        .eq('id_persona', idPersona)
        .map((data) {
          if (data.isEmpty) return 'INACTIVO';
          return data.first['disponibilidad'] as String;
        });
  }
}
