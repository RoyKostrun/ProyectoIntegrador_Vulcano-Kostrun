import 'package:supabase_flutter/supabase_flutter.dart';

class UbicacionService {
  final _supabase = Supabase.instance.client;

  /// Obtener el id_usuario (integer) desde el auth user (UUID)
  Future<int?> _getIdUsuario() async {
    try {
      final authUser = _supabase.auth.currentUser;
      
      if (authUser == null) {
        print('⚠️ No hay usuario autenticado');
        return null;
      }

      print('🔍 Auth User ID (UUID): ${authUser.id}');
      print('🔍 Auth User Email: ${authUser.email}');

      // ✅ CAMBIO: Buscar por email en lugar de auth_user_id
      final response = await _supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', authUser.email!)
          .maybeSingle();

      if (response == null) {
        print('❌ No se encontró usuario en la tabla usuario');
        return null;
      }

      final idUsuario = response['id_usuario'] as int;
      print('✅ ID Usuario encontrado: $idUsuario');
      return idUsuario;
    } catch (e) {
      print('❌ Error en _getIdUsuario: $e');
      return null;
    }
  }

  /// Obtener todas las ubicaciones del usuario actual
  Future<List<Map<String, dynamic>>> getUbicacionesDelUsuario() async {
    try {
      final idUsuario = await _getIdUsuario();
      
      if (idUsuario == null) {
        print('⚠️ No se pudo obtener id_usuario');
        return [];
      }

      print('🔍 Buscando ubicaciones para id_usuario: $idUsuario');

      final response = await _supabase
          .from('ubicacion')
          .select('id_ubicacion, nombre, calle, numero, barrio, ciudad, provincia, codigo_postal, es_principal')
          .eq('id_usuario', idUsuario) // ✅ Ahora usa el integer correcto
          .order('es_principal', ascending: false)
          .order('nombre', ascending: true);

      print('✅ Ubicaciones encontradas: ${response.length}');
      print('📦 Datos: $response');

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      print('❌ Error en getUbicacionesDelUsuario: $e');
      print('📍 StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Crear nueva ubicación
  Future<Map<String, dynamic>> crearUbicacion(Map<String, dynamic> datos) async {
    try {
      final idUsuario = await _getIdUsuario();
      
      if (idUsuario == null) {
        throw Exception('No se pudo obtener el id_usuario');
      }

      datos['id_usuario'] = idUsuario; // ✅ Usa el integer
      datos['created_at'] = DateTime.now().toIso8601String();
      datos['updated_at'] = DateTime.now().toIso8601String();

      print('📤 Creando ubicación: $datos');

      final response = await _supabase
          .from('ubicacion')
          .insert(datos)
          .select()
          .single();

      print('✅ Ubicación creada: $response');
      return response;
    } catch (e) {
      print('❌ Error en crearUbicacion: $e');
      rethrow;
    }
  }

  /// Obtener una ubicación específica por ID
  Future<Map<String, dynamic>?> getUbicacionPorId(int idUbicacion) async {
    try {
      final response = await _supabase
          .from('ubicacion')
          .select()
          .eq('id_ubicacion', idUbicacion)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error en getUbicacionPorId: $e');
      return null;
    }
  }

  /// Obtener la ubicación principal del usuario
  Future<Map<String, dynamic>?> getUbicacionPrincipal() async {
    try {
      final idUsuario = await _getIdUsuario();
      
      if (idUsuario == null) return null;

      final response = await _supabase
          .from('ubicacion')
          .select()
          .eq('id_usuario', idUsuario)
          .eq('es_principal', true)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error en getUbicacionPrincipal: $e');
      return null;
    }
  }

  /// Actualizar ubicación
  Future<void> actualizarUbicacion(int idUbicacion, Map<String, dynamic> datos) async {
    try {
      datos['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('ubicacion')
          .update(datos)
          .eq('id_ubicacion', idUbicacion);

      print('✅ Ubicación actualizada: $idUbicacion');
    } catch (e) {
      print('❌ Error en actualizarUbicacion: $e');
      rethrow;
    }
  }

  /// Marcar una ubicación como principal
  Future<void> marcarComoPrincipal(int idUbicacion) async {
    try {
      final idUsuario = await _getIdUsuario();
      
      if (idUsuario == null) {
        throw Exception('No se pudo obtener el id_usuario');
      }

      // Quitar el flag de todas las ubicaciones del usuario
      await _supabase
          .from('ubicacion')
          .update({'es_principal': false})
          .eq('id_usuario', idUsuario);

      // Marcar la seleccionada como principal
      await _supabase
          .from('ubicacion')
          .update({'es_principal': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id_ubicacion', idUbicacion);

      print('✅ Ubicación $idUbicacion marcada como principal');
    } catch (e) {
      print('❌ Error en marcarComoPrincipal: $e');
      rethrow;
    }
  }

  /// Eliminar ubicación
  Future<void> eliminarUbicacion(int idUbicacion) async {
    try {
      await _supabase
          .from('ubicacion')
          .delete()
          .eq('id_ubicacion', idUbicacion);

      print('✅ Ubicación eliminada: $idUbicacion');
    } catch (e) {
      print('❌ Error en eliminarUbicacion: $e');
      rethrow;
    }
  }

  /// Verificar si el usuario tiene ubicaciones
  Future<bool> tieneUbicaciones() async {
    try {
      final ubicaciones = await getUbicacionesDelUsuario();
      return ubicaciones.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}