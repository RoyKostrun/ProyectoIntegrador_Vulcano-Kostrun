import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trabajo_model.dart';

class TrabajoService {
  final supabase = Supabase.instance.client;

  // Obtener lista de trabajos (con paginación opcional)
  Future<List<TrabajoModel>> getTrabajos({int from = 0, int to = 19}) async {
    final response = await supabase
        .from('trabajo')
        .select()
        .range(from, to)
        .order('created_at', ascending: false);

    return (response as List)
        .map((data) => TrabajoModel.fromJson(data))
        .toList();
  }

  // Crear un trabajo
  Future<void> createTrabajo(Map<String, dynamic> data) async {
    await supabase.from('trabajo').insert(data);
  }

  // Obtener rubros disponibles
  Future<List<String>> getRubros() async {
    final response = await supabase.from('rubro').select('nombre');
    return (response as List).map((r) => r['nombre'] as String).toList();
  }
}
