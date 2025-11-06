import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

abstract class TrabajoApi {
  Future<List<Map<String, dynamic>>> fetchTrabajos({
    required int idUsuario,
    int from = 0,
    int to = 19,
  });

  Future<List<Map<String, dynamic>>> fetchMisTrabajos({
    required int idUsuario,
    int from = 0,
    int to = 19,
  });

  Future<Map<String, dynamic>> insertPago(Map<String, dynamic> pagoData);
  Future<void> insertTrabajo(Map<String, dynamic> trabajoData);

  Future<Map<String, dynamic>> getTrabajoOwner(int idTrabajo);
  Future<void> updateTrabajo(int idTrabajo, Map<String, dynamic> datos);
  Future<void> deleteTrabajo(int idTrabajo);
  Future<void> deletePago(int idPago);
}

class SupabaseTrabajoApi implements TrabajoApi {
  final SupabaseClient _client = supabase;

  @override
  Future<List<Map<String, dynamic>>> fetchTrabajos({
    required int idUsuario,
    int from = 0,
    int to = 19,
  }) async {
    final response = await _client
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

    final list = (response as List).cast<Map<String, dynamic>>();
    return list;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMisTrabajos({
    required int idUsuario,
    int from = 0,
    int to = 19,
  }) async {
    final response = await _client
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

    final list = (response as List).cast<Map<String, dynamic>>();
    return list;
  }

  @override
  Future<Map<String, dynamic>> insertPago(Map<String, dynamic> pagoData) async {
    final pagoResponse =
        await _client.from('pago').insert(pagoData).select().single();
    return (pagoResponse as Map<String, dynamic>);
  }

  @override
  Future<void> insertTrabajo(Map<String, dynamic> trabajoData) async {
    await _client.from('trabajo').insert(trabajoData);
  }

  @override
  Future<Map<String, dynamic>> getTrabajoOwner(int idTrabajo) async {
    final res = await _client
        .from('trabajo')
        .select('empleador_id, id_pago')
        .eq('id_trabajo', idTrabajo)
        .single();
    return (res as Map<String, dynamic>);
  }

  @override
  Future<void> updateTrabajo(int idTrabajo, Map<String, dynamic> datos) async {
    await _client.from('trabajo').update(datos).eq('id_trabajo', idTrabajo);
  }

  @override
  Future<void> deleteTrabajo(int idTrabajo) async {
    await _client.from('trabajo').delete().eq('id_trabajo', idTrabajo);
  }

  @override
  Future<void> deletePago(int idPago) async {
    await _client.from('pago').delete().eq('id_pago', idPago);
  }
}
