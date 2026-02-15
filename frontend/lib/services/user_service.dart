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
// 🔹 ACTUALIZAR ES_EMPLEADOR (UNIVERSAL)
// ==============================================================
  /// Actualiza el campo es_empleador del usuario actual (PERSONA o EMPRESA)
  Future<void> actualizarEsEmpleador(bool valor) async {
    try {
      final user = await obtenerUsuarioActual();

      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      dynamic response;

      if (user.isPersona && user.persona != null) {
        // Actualizar persona
        response = await _supabase
            .from('usuario_persona')
            .update({
              'es_empleador': valor,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id_persona', user.persona!.idPersona)
            .select();
      } else if (user.isEmpresa && user.empresa != null) {
        // Actualizar empresa
        response = await _supabase
            .from('usuario_empresa')
            .update({
              'es_empleador': valor,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id_empresa', user.empresa!.idEmpresa)
            .select();
      } else {
        throw Exception('No se encontró información del usuario');
      }

      if (response.isEmpty) {
        throw Exception('No se pudo actualizar el usuario');
      }

      print('✅ Usuario actualizado: es_empleador = $valor');
    } catch (e) {
      print('❌ Error al actualizar es_empleador: $e');
      rethrow;
    }
  }

// ==============================================================
// 🔹 ACTUALIZAR ES_EMPLEADO (UNIVERSAL)
// ==============================================================
  /// Actualiza el campo es_empleado del usuario actual (PERSONA o EMPRESA)
  Future<void> actualizarEsEmpleado(bool valor) async {
    try {
      final user = await obtenerUsuarioActual();

      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      dynamic response;

      if (user.isPersona && user.persona != null) {
        // Actualizar persona
        response = await _supabase
            .from('usuario_persona')
            .update({
              'es_empleado': valor,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id_persona', user.persona!.idPersona)
            .select();
      } else if (user.isEmpresa && user.empresa != null) {
        // Actualizar empresa
        response = await _supabase
            .from('usuario_empresa')
            .update({
              'es_empleado': valor,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id_empresa', user.empresa!.idEmpresa)
            .select();
      } else {
        throw Exception('No se encontró información del usuario');
      }

      if (response.isEmpty) {
        throw Exception('No se pudo actualizar el usuario');
      }

      print('✅ Usuario actualizado: es_empleado = $valor');
    } catch (e) {
      print('❌ Error al actualizar es_empleado: $e');
      rethrow;
    }
  }

// ==============================================================
// 🔹 VERIFICAR SI ES EMPLEADOR (UNIVERSAL)
// ==============================================================
  /// Verifica si el usuario actual es empleador
  Future<bool> esEmpleador() async {
    try {
      final user = await obtenerUsuarioActual();

      if (user == null) {
        return false;
      }

      if (user.isPersona && user.persona != null) {
        return user.persona!.esEmpleador;
      }

      if (user.isEmpresa && user.empresa != null) {
        return user.empresa!.esEmpleador;
      }

      return false;
    } catch (e) {
      print('❌ Error al verificar es_empleador: $e');
      return false;
    }
  }

// ==============================================================
// 🔹 VERIFICAR SI ES EMPLEADO (UNIVERSAL)
// ==============================================================
  /// Verifica si el usuario actual es empleado
  Future<bool> esEmpleado() async {
    try {
      final user = await obtenerUsuarioActual();

      if (user == null) {
        return false;
      }

      if (user.isPersona && user.persona != null) {
        return user.persona!.esEmpleado;
      }

      if (user.isEmpresa && user.empresa != null) {
        return user.empresa!.esEmpleado;
      }

      return false;
    } catch (e) {
      print('❌ Error al verificar es_empleado: $e');
      return false;
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

      final response = await _supabase.from('usuario').select('''
            *,
            usuario_persona (*),
            usuario_empresa (*)
          ''').eq('email', email);

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

  // ==============================================================
  // 🔹 ACTUALIZAR PERSONA (CONFIGURACIÓN)
  // ==============================================================
  Future<void> actualizarPersona(
    int idUsuario,
    Map<String, dynamic> datos,
  ) async {
    try {
      datos['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('usuario_persona')
          .update(datos)
          .eq('id_usuario', idUsuario)
          .select();

      if (response.isEmpty) {
        throw Exception('No se pudo actualizar la persona');
      }

      print('✅ Persona actualizada: $idUsuario');
    } catch (e) {
      print('❌ Error actualizando persona: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 ACTUALIZAR TELÉFONO
  // ==============================================================
  Future<void> actualizarTelefono(String? telefono) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) throw Exception('Usuario no autenticado');

      await _supabase.from('usuario').update({
        'telefono': telefono,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_usuario', userData.idUsuario);

      print('✅ Teléfono actualizado');
    } catch (e) {
      print('❌ Error actualizando teléfono: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 ACTUALIZAR EMAIL
  // ==============================================================
  Future<void> actualizarEmail(String nuevoEmail) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(email: nuevoEmail),
      );

      final userData = await AuthService.getCurrentUserData();
      if (userData != null) {
        await _supabase.from('usuario').update({
          'email': nuevoEmail,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_usuario', userData.idUsuario);
      }

      print('✅ Email actualizado: $nuevoEmail');
    } catch (e) {
      print('❌ Error actualizando email: $e');
      rethrow;
    }
  }

  // Agregar estos métodos a lib/services/user_service.dart

// Actualizar disponibilidad de empresa
  Future<bool> actualizarDisponibilidadEmpresa(
      int idEmpresa, String disponibilidad) async {
    try {
      final response = await _supabase
          .from('usuario_empresa')
          .update({'disponibilidad': disponibilidad})
          .eq('id_empresa', idEmpresa)
          .select();

      return response != null && response.isNotEmpty;
    } catch (e) {
      print('Error al actualizar disponibilidad de empresa: $e');
      return false;
    }
  }

// Actualizar disponibilidad de persona (si no existe)
  Future<bool> actualizarDisponibilidadPersona(
      int idPersona, String disponibilidad) async {
    try {
      final response = await _supabase
          .from('persona')
          .update({'disponibilidad': disponibilidad})
          .eq('id_persona', idPersona)
          .select();

      return response != null && response.isNotEmpty;
    } catch (e) {
      print('Error al actualizar disponibilidad de persona: $e');
      return false;
    }
  }
}
