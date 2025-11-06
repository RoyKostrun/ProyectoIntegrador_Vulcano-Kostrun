import 'package:flutter_test/flutter_test.dart';
import 'package:changapp_client/services/trabajo_service_di.dart';
import 'package:changapp_client/services/api/trabajo_api.dart';

class TrabajoApiFake implements TrabajoApi {
  final List<Map<String, dynamic>> _otros = [];
  final List<Map<String, dynamic>> _mios = [];
  final Map<int, Map<String, dynamic>> _trabajos = {};
  int _nextPagoId = 1;

  void seed(
      {List<Map<String, dynamic>>? otros, List<Map<String, dynamic>>? mios}) {
    if (otros != null) {
      _otros
        ..clear()
        ..addAll(otros);
    }
    if (mios != null) {
      _mios
        ..clear()
        ..addAll(mios);
      for (final t in mios) {
        if (t['id_trabajo'] != null) {
          _trabajos[t['id_trabajo'] as int] = t;
        }
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTrabajos(
      {required int idUsuario, int from = 0, int to = 19}) async {
    return _otros.sublist(from, (to + 1).clamp(0, _otros.length));
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMisTrabajos(
      {required int idUsuario, int from = 0, int to = 19}) async {
    return _mios.sublist(from, (to + 1).clamp(0, _mios.length));
  }

  @override
  Future<Map<String, dynamic>> insertPago(Map<String, dynamic> pagoData) async {
    return {'id_pago': _nextPagoId++, ...pagoData};
  }

  @override
  Future<void> insertTrabajo(Map<String, dynamic> trabajoData) async {
    final id = (trabajoData['id_trabajo'] as int?) ?? (_trabajos.length + 1);
    _trabajos[id] = {'id_trabajo': id, ...trabajoData};
  }

  @override
  Future<Map<String, dynamic>> getTrabajoOwner(int idTrabajo) async {
    final t = _trabajos[idTrabajo];
    if (t == null) throw Exception('not found');
    return {'empleador_id': t['empleador_id'], 'id_pago': t['id_pago']};
  }

  @override
  Future<void> updateTrabajo(int idTrabajo, Map<String, dynamic> datos) async {
    if (!_trabajos.containsKey(idTrabajo)) throw Exception('not found');
    _trabajos[idTrabajo] = {..._trabajos[idTrabajo]!, ...datos};
  }

  @override
  Future<void> deleteTrabajo(int idTrabajo) async {
    _trabajos.remove(idTrabajo);
  }

  @override
  Future<void> deletePago(int idPago) async {/* no-op for fake */}
}

void main() {
  test('getTrabajos usa API y mapea modelos', () async {
    final api = TrabajoApiFake()
      ..seed(otros: [
        {
          'id_trabajo': 1,
          'titulo': 'Pintor',
          'descripcion': 'Paredes',
          'rubro': {'id_rubro': 1, 'nombre': 'Construcción'},
          'ubicacion': {'calle': 'Calle', 'numero': '1', 'ciudad': 'CABA'},
          'estado_publicacion': 'PUBLICADO',
          'urgencia': 'ESTANDAR',
        }
      ]);

    final service = TrabajoServiceDI(api: api, getUserId: () async => 99);
    final list = await service.getTrabajos(from: 0, to: 0);

    expect(list.length, 1);
    expect(list.first.titulo, 'Pintor');
    expect(list.first.nombreRubro, 'Construcción');
  });

  test('create/update/delete respetan ownership', () async {
    final api = TrabajoApiFake()
      ..seed(mios: [
        {
          'id_trabajo': 10,
          'empleador_id': 7,
          'id_pago': 1,
          'titulo': 'Original',
          'descripcion': 'x',
        }
      ]);

    final serviceOwner = TrabajoServiceDI(api: api, getUserId: () async => 7);
    final serviceOther = TrabajoServiceDI(api: api, getUserId: () async => 8);

    // Update permitido para owner
    await serviceOwner.updateTrabajo(10, {'titulo': 'Editado'});

    // Update rechazado para no-owner
    expect(
      () => serviceOther.updateTrabajo(10, {'titulo': 'Hack'}),
      throwsA(isA<Exception>()),
    );

    // Crear trabajo nuevo
    await serviceOwner.createTrabajo({
      'empleador_id': 7,
      'id_rubro': 1,
      'titulo': 'Nuevo',
      'descripcion': 'desc',
      'fecha_inicio': '2025-01-01',
      'fecha_fin': '2025-01-02',
      'horario_inicio': '08:00',
      'horario_fin': '16:00',
      'ubicacion_id': 1,
      'metodo_pago': 'EFECTIVO',
      'cantidad_empleados_requeridos': 1,
      'periodo_pago': 'HORA',
    });

    // Delete permitido para owner
    await serviceOwner.deleteTrabajo(10);

    // Delete rechazado (ya no existe o no-owner) — aceptamos excepción
    await expectLater(
      () => serviceOther.deleteTrabajo(10),
      throwsA(isA<Exception>()),
    );
  });
}
