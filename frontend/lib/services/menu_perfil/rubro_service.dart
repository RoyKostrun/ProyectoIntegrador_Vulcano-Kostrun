// lib/services/rubro_service.dart
import '../../models/menu_perfil/rubro_model.dart';
import '../supabase_client.dart';
import '../auth_service.dart';

class RubroService {
  
  // ========================================
  // 📋 OBTENER TODOS LOS RUBROS
  // ========================================
  static Future<List<Rubro>> getRubros() async {
    try {
      final response = await supabase
          .from('rubro')
          .select('*')
          .eq('activo', true)
          .order('nombre', ascending: true);

      return (response as List)
          .map((map) => Rubro.fromMap(map))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener rubros: $e');
    }
  }

  // ========================================
  // 🔍 OBTENER RUBRO POR ID
  // ========================================
  static Future<Rubro?> getRubroById(int id) async {
    try {
      final response = await supabase
          .from('rubro')
          .select('*')
          .eq('id_rubro', id)
          .single();

      return Rubro.fromMap(response);
    } catch (e) {
      print('Error al obtener rubro por ID: $e');
      return null;
    }
  }

  // ========================================
  // 👤 OBTENER RUBROS DEL USUARIO ACTUAL
  // ========================================
  static Future<List<Rubro>> getUserRubros() async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) throw 'Usuario no autenticado';

      final idUsuario = userData.idUsuario;

      print('🔍 Buscando rubros para usuario ID: $idUsuario');

      // ✅ Query mejorado: Primero obtener IDs de rubros del usuario
      final usuarioRubrosResponse = await supabase
          .from('usuario_rubro')
          .select('id_rubro')
          .eq('id_usuario', idUsuario)
          .eq('activo', true);

      if (usuarioRubrosResponse.isEmpty) {
        print('⚠️ Usuario no tiene rubros asignados');
        return [];
      }

      // Extraer los IDs
      final rubrosIds = (usuarioRubrosResponse as List)
          .map((item) => item['id_rubro'] as int)
          .toList();

      print('📋 IDs de rubros encontrados: $rubrosIds');

      // ✅ Ahora obtener los datos completos de esos rubros
      final rubrosResponse = await supabase
          .from('rubro')
          .select('*')
          .inFilter('id_rubro', rubrosIds)
          .eq('activo', true)
          .order('nombre', ascending: true);

      print('✅ ${(rubrosResponse as List).length} rubros cargados');

      List<Rubro> rubros = [];
      for (var item in (rubrosResponse as List)) {
        rubros.add(Rubro.fromMap(item));
      }

      return rubros;
    } catch (e) {
      print('❌ Error al obtener rubros del usuario: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // ========================================
  // ➕ AGREGAR RUBRO AL USUARIO
  // ========================================
  static Future<void> addUserRubro(int rubroId) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) throw 'Usuario no autenticado';

      final idUsuario = userData.idUsuario;

      // Verificar si ya existe
      final existing = await supabase
          .from('usuario_rubro')
          .select('id_usuario_rubro')
          .eq('id_usuario', idUsuario)
          .eq('id_rubro', rubroId)
          .maybeSingle();

      if (existing != null) {
        // Si existe pero está inactivo, reactivarlo
        await supabase
            .from('usuario_rubro')
            .update({
              'activo': true,
              'fecha_asignacion': DateTime.now().toIso8601String(),
            })
            .eq('id_usuario', idUsuario)
            .eq('id_rubro', rubroId);
        
        print('✅ Rubro reactivado');
        return;
      }

      // Si no existe, crear nuevo
      await supabase.from('usuario_rubro').insert({
        'id_usuario': idUsuario,
        'id_rubro': rubroId,
        'fecha_asignacion': DateTime.now().toIso8601String(),
        'activo': true,
      });

      print('✅ Rubro agregado al usuario');
    } catch (e) {
      print('❌ Error al agregar rubro: $e');
      throw Exception('Error al agregar rubro: $e');
    }
  }

  // ========================================
  // ➖ ELIMINAR RUBRO DEL USUARIO
  // ========================================
  static Future<void> removeUserRubro(int rubroId) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) throw 'Usuario no autenticado';

      final idUsuario = userData.idUsuario;

      // Marcar como inactivo en lugar de eliminar
      await supabase
          .from('usuario_rubro')
          .update({'activo': false})
          .eq('id_usuario', idUsuario)
          .eq('id_rubro', rubroId);

      print('✅ Rubro eliminado del usuario');
    } catch (e) {
      print('❌ Error al eliminar rubro: $e');
      throw Exception('Error al eliminar rubro: $e');
    }
  }

  // ========================================
  // 💾 GUARDAR MÚLTIPLES RUBROS (desde onboarding)
  // ========================================
  static Future<void> saveUserRubros(List<String> nombresRubros) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) throw 'Usuario no autenticado';

      final idUsuario = userData.idUsuario;

      // Obtener IDs de los rubros seleccionados
      final response = await supabase
          .from('rubro')
          .select('id_rubro, nombre')
          .inFilter('nombre', nombresRubros);

      final rubrosSeleccionados = List<Map<String, dynamic>>.from(response);

      // Eliminar relaciones previas (marcar como inactivo)
      await supabase
          .from('usuario_rubro')
          .update({'activo': false})
          .eq('id_usuario', idUsuario);

      // Insertar nuevas relaciones
      final inserts = rubrosSeleccionados
          .map((r) => {
                'id_usuario': idUsuario,
                'id_rubro': r['id_rubro'],
                'fecha_asignacion': DateTime.now().toIso8601String(),
                'activo': true,
              })
          .toList();

      if (inserts.isNotEmpty) {
        await supabase.from('usuario_rubro').insert(inserts);
      }

      print('✅ Rubros actualizados para usuario ID: $idUsuario');
    } catch (e) {
      print('❌ Error al guardar rubros del usuario: $e');
      rethrow;
    }
  }

  // ========================================
  // 🔄 ACTUALIZAR RUBROS DEL USUARIO (reemplazar todos)
  // ========================================
  static Future<void> updateUserRubros(List<int> rubrosIds) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) throw 'Usuario no autenticado';

      final idUsuario = userData.idUsuario;

      // Marcar todos como inactivos
      await supabase
          .from('usuario_rubro')
          .update({'activo': false})
          .eq('id_usuario', idUsuario);

      // Insertar o reactivar los nuevos
      for (var rubroId in rubrosIds) {
        await addUserRubro(rubroId);
      }

      print('✅ Rubros actualizados correctamente');
    } catch (e) {
      print('❌ Error al actualizar rubros: $e');
      throw Exception('Error al actualizar rubros: $e');
    }
  }

  // ========================================
  // ✅ VERIFICAR SI USUARIO TIENE RUBRO
  // ========================================
  static Future<bool> userHasRubro(int rubroId) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) return false;

      final idUsuario = userData.idUsuario;

      final response = await supabase
          .from('usuario_rubro')
          .select('id_usuario_rubro')
          .eq('id_usuario', idUsuario)
          .eq('id_rubro', rubroId)
          .eq('activo', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // 🔢 CONTAR RUBROS DEL USUARIO
  // ========================================
  static Future<int> getUserRubrosCount() async {
    try {
      final rubros = await getUserRubros();
      return rubros.length;
    } catch (e) {
      return 0;
    }
  }

  // ========================================
  // 🔍 BUSCAR RUBROS POR NOMBRE
  // ========================================
  static Future<List<Rubro>> searchRubros(String query) async {
    try {
      final response = await supabase
          .from('rubro')
          .select('*')
          .or('nombre.ilike.%$query%,descripcion.ilike.%$query%')
          .eq('activo', true)
          .order('nombre', ascending: true);

      return (response as List)
          .map((map) => Rubro.fromMap(map))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar rubros: $e');
    }
  }

  // ========================================
  // 📊 OBTENER CONTEO TOTAL DE RUBROS
  // ========================================
  static Future<int> getRubrosCount() async {
    try {
      final response = await supabase
          .from('rubro')
          .select('id_rubro')
          .eq('activo', true);

      return (response as List).length;
    } catch (e) {
      throw Exception('Error al contar rubros: $e');
    }
  }

  // ========================================
  // 📡 STREAM DE RUBROS (tiempo real - opcional)
  // ========================================
  static Stream<List<Rubro>> getRubrosStream() {
    return supabase
        .from('rubro')
        .stream(primaryKey: ['id_rubro'])
        .eq('activo', true)
        .order('nombre', ascending: true)
        .map((data) => data.map((map) => Rubro.fromMap(map)).toList());
  }

  // ========================================
  // ✅ VERIFICAR SI EXISTE RUBRO POR NOMBRE
  // ========================================
  static Future<bool> existsRubroByName(String nombre) async {
    try {
      final response = await supabase
          .from('rubro')
          .select('id_rubro')
          .eq('nombre', nombre)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // 🎨 OBTENER RUBROS CON ICONOS (para UI)
  // ========================================
  static Future<List<Rubro>> getRubrosConIconos() async {
    try {
      final rubros = await getRubros();
      // Los iconos ya se generan automáticamente en el modelo
      return rubros;
    } catch (e) {
      throw Exception('Error al obtener rubros con iconos: $e');
    }
  }
}