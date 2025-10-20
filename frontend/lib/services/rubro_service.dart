// lib/services/rubro_service.dart
import '../models/rubro_model.dart';
import 'supabase_client.dart'; // Tu archivo existente
import 'auth_service.dart';

class RubroService {
  
  /// Obtiene todos los rubros desde Supabase
  static Future<List<Rubro>> getRubros() async {
    try {
      final response = await supabase
          .from('rubro')
          .select('*')
          .order('nombre', ascending: true);

      return (response as List)
          .map((map) => Rubro.fromMap(map))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener rubros: $e');
    }
  }

  /// Obtiene un rubro específico por ID
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

  /// Agrega un nuevo rubro a Supabase
  static Future<int> addRubro({
    required String nombre,
    required String descripcion,
  }) async {
    try {
      final response = await supabase
          .from('rubro')
          .insert({
            'nombre': nombre,
            'descripcion': descripcion,
          })
          .select('id_rubro')  
          .single();

      final int id = response['id_rubro'];  
      print('Rubro agregado con ID: $id');
      return id;
    } catch (e) {
      throw Exception('Error al agregar rubro: $e');
    }
  }

  /// Actualiza un rubro existente en Supabase
  static Future<bool> updateRubro({
    required int id,
    String? nombre,
    String? descripcion,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (nombre != null) updates['nombre'] = nombre;
      if (descripcion != null) updates['descripcion'] = descripcion;

      await supabase
          .from('rubro')
          .update(updates)
          .eq('id_rubro', id);  

      return true;
    } catch (e) {
      throw Exception('Error al actualizar rubro: $e');
    }
  }

  /// Elimina un rubro de Supabase
  static Future<bool> deleteRubro(int id) async {
    try {
      await supabase
          .from('rubro')
          .delete()
          .eq('id_rubro', id);  

      return true;
    } catch (e) {
      throw Exception('Error al eliminar rubro: $e');
    }
  }

  /// Busca rubros por nombre en Supabase
  static Future<List<Rubro>> searchRubros(String query) async {
    try {
      final response = await supabase
          .from('rubro')
          .select('*')
          .or('nombre.ilike.%$query%,descripcion.ilike.%$query%')
          .order('nombre', ascending: true);

      return (response as List)
          .map((map) => Rubro.fromMap(map))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar rubros: $e');
    }
  }

  /// Obtiene el conteo total de rubros
  static Future<int> getRubrosCount() async {
    try {
      final response = await supabase
          .from('rubro')
          .select('id_rubro'); 

      return (response as List).length;
    } catch (e) {
      throw Exception('Error al contar rubros: $e');
    }
  }

  /// Escucha cambios en tiempo real (opcional)
  static Stream<List<Rubro>> getRubrosStream() {
    return supabase
        .from('rubro')
        .stream(primaryKey: ['id_rubro']) 
        .order('nombre', ascending: true)
        .map((data) => data.map((map) => Rubro.fromMap(map)).toList());
  }

  /// Método adicional: Obtener rubros por categoría (si tienes campo activo)
  static Future<List<Rubro>> getRubrosActivos() async {
    try {
      final response = await supabase
          .from('rubro')
          .select('*')
          .eq('activo', true)  // Si tienes campo activo en tu tabla
          .order('nombre', ascending: true);

      return (response as List)
          .map((map) => Rubro.fromMap(map))
          .toList();
    } catch (e) {
      // Si no tienes campo activo, devuelve todos
      return getRubros();
    }
  }

  /// Verificar si existe un rubro con ese nombre
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

      // Eliminar relaciones previas
      await supabase.from('usuario_rubro').delete().eq('id_usuario', idUsuario);

      // Insertar nuevas relaciones
      final inserts = rubrosSeleccionados
          .map((r) => {'id_usuario': idUsuario, 'id_rubro': r['id_rubro']})
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
}