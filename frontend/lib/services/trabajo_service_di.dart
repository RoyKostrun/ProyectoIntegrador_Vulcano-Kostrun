import '../models/trabajo_model.dart';
import 'auth_service.dart';
import 'api/trabajo_api.dart';

/// Versión inyectable del servicio de trabajos.
/// No reemplaza al existente; conviven para facilitar migración segura.
class TrabajoServiceDI {
  final TrabajoApi _api;
  final Future<int> Function() _getUserId;

  TrabajoServiceDI({TrabajoApi? api, Future<int> Function()? getUserId})
      : _api = api ?? SupabaseTrabajoApi(),
        _getUserId = getUserId ?? AuthService.getCurrentUserId;

  Future<List<TrabajoModel>> getTrabajos({int from = 0, int to = 19}) async {
    final idUsuario = await _getUserId();
    final rows =
        await _api.fetchTrabajos(idUsuario: idUsuario, from: from, to: to);
    return rows.map((e) => TrabajoModel.fromJson(e)).toList();
  }

  Future<List<TrabajoModel>> getMisTrabajos({int from = 0, int to = 19}) async {
    final idUsuario = await _getUserId();
    final rows =
        await _api.fetchMisTrabajos(idUsuario: idUsuario, from: from, to: to);
    return rows.map((e) => TrabajoModel.fromJson(e)).toList();
  }

  Future<void> createTrabajo(Map<String, dynamic> datos) async {
    final pagoData = {
      'monto': datos['salario'] ?? 0,
      'metodo': datos['metodo_pago'],
      'estado': 'PENDIENTE',
      'periodo': datos['periodo_pago'],
    };

    final pagoResponse = await _api.insertPago(pagoData);
    final idPago = pagoResponse['id_pago'];

    final trabajoData = {
      'empleador_id': datos['empleador_id'],
      'id_pago': idPago,
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

    await _api.insertTrabajo(trabajoData);
  }

  Future<void> updateTrabajo(int idTrabajo, Map<String, dynamic> datos) async {
    final idUsuario = await _getUserId();
    final trabajo = await _api.getTrabajoOwner(idTrabajo);
    if (trabajo['empleador_id'] != idUsuario) {
      throw Exception('No tienes permiso para editar este trabajo');
    }
    await _api.updateTrabajo(idTrabajo, datos);
  }

  Future<void> deleteTrabajo(int idTrabajo) async {
    final idUsuario = await _getUserId();
    final trabajo = await _api.getTrabajoOwner(idTrabajo);
    if (trabajo['empleador_id'] != idUsuario) {
      throw Exception('No tienes permiso para eliminar este trabajo');
    }
    final idPago = trabajo['id_pago'];
    await _api.deleteTrabajo(idTrabajo);
    if (idPago != null) {
      await _api.deletePago(idPago);
    }
  }
}
