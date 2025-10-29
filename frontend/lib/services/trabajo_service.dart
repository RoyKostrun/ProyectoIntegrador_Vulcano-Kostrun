import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trabajo_model.dart';
import 'auth_service.dart';

class TrabajoService {
  final supabase = Supabase.instance.client;

  // Obtiene el id_usuario (INTEGER) desde tu tabla usuario

  // Traer trabajos de OTROS usuarios (para navegador)
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
            pago:id_pago(id_pago, monto, metodo, estado)
          ''')
          .neq('empleador_id', idUsuario)
          .eq('estado_publicacion', 'PUBLICADO')
          .range(from, to)
          .order('created_at', ascending: false);

      print('✅ Trabajos encontrados: ${(response as List).length}');

      return (response as List)
          .map((json) => TrabajoModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error al cargar trabajos: $e');
      throw Exception('Error al cargar trabajos: $e');
    }
  }

  // Traer MIS trabajos (publicados por mí)
  Future<List<TrabajoModel>> getMisTrabajos({int from = 0, int to = 19}) async {
    try {
      final idUsuario = await AuthService.getCurrentUserId();
      
      print('🔍 Cargando mis trabajos donde empleador_id = $idUsuario');

      final response = await supabase
          .from('trabajo')
          .select('''
            *,
            rubro:id_rubro(id_rubro, nombre),
            ubicacion:ubicacion_id(id_ubicacion, nombre, calle, numero, ciudad, provincia),
            pago:id_pago(id_pago, monto, metodo, estado)
          ''')
          .eq('empleador_id', idUsuario)
          .range(from, to)
          .order('created_at', ascending: false);

      print('✅ Mis trabajos encontrados: ${(response as List).length}');

      return (response as List)
          .map((json) => TrabajoModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error al cargar mis trabajos: $e');
      throw Exception('Error al cargar mis trabajos: $e');
    }
  }

  // ✅ CREAR TRABAJO (con pago incluido)
  Future<void> createTrabajo(Map<String, dynamic> datos) async {
    try {
      print('📝 Iniciando creación de trabajo...');
      print('📝 Datos recibidos: $datos');

      // 1. Crear el pago primero (porque id_pago es NOT NULL en trabajo)
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

      // 2. Preparar datos del trabajo
      final trabajoData = {
        'empleador_id': datos['empleador_id'],
        'id_pago': idPago, // ✅ ID del pago que acabamos de crear
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
        'estado_publicacion': datos['estado_publicacion'] ?? 'PUBLICADO',
      };

      print('📝 Creando trabajo: $trabajoData');

      // 3. Crear el trabajo
      await supabase.from('trabajo').insert(trabajoData);

      print('✅ Trabajo creado exitosamente');
    } catch (e) {
      print('❌ Error al crear trabajo: $e');
      throw Exception('Error al crear trabajo: $e');
    }
  }

  // ✅ ACTUALIZAR TRABAJO
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

  // ✅ ELIMINAR TRABAJO
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

      // Opcional: Eliminar el pago asociado
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

//queda pendiente arreglar detalle trabajo. 