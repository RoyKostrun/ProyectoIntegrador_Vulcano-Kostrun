import 'package:flutter_test/flutter_test.dart';
import 'package:changapp_client/models/trabajo_model.dart';

void main() {
  group('TrabajoModel', () {
    test('fromJson mapea campos y relaciones', () {
      final json = {
        'id_trabajo': 42,
        'titulo': 'Pintor',
        'descripcion': 'Pintar pared',
        'salario': 1500,
        'estado_publicacion': 'PUBLICADO',
        'urgencia': 'ALTA',
        'metodo_pago': 'EFECTIVO',
        'periodo_pago': 'HORA',
        'imagen_url': 'http://img',
        'cantidad_empleados_requeridos': 2,
        'fecha_inicio': '2025-01-01',
        'fecha_fin': '2025-01-02',
        'horario_inicio': '08:00',
        'horario_fin': '16:00',
        'empleador_id': 7,
        'rubro': {'id_rubro': 1, 'nombre': 'Construcción'},
        'ubicacion': {
          'id_ubicacion': 9,
          'calle': 'Av. Siempre Viva',
          'numero': '742',
          'ciudad': 'Springfield',
          'provincia': 'BA'
        },
      };

      final m = TrabajoModel.fromJson(json);
      expect(m.id, 42);
      expect(m.titulo, 'Pintor');
      expect(m.descripcion, 'Pintar pared');
      expect(m.salario, 1500);
      expect(m.estado, 'PUBLICADO');
      expect(m.urgencia, 'ALTA');
      expect(m.metodoPago, 'EFECTIVO');
      expect(m.periodoPago, 'HORA');
      expect(m.imagenUrl, 'http://img');
      expect(m.cantidadEmpleadosRequeridos, 2);
      expect(m.fechaInicio, '2025-01-01');
      expect(m.fechaFin, '2025-01-02');
      expect(m.horarioInicio, '08:00');
      expect(m.horarioFin, '16:00');
      expect(m.empleadorId, 7);
      expect(m.nombreRubro, 'Construcción');
      expect(m.direccionCompleta, contains('Siempre Viva'));
    });

    test('toJson conserva campos clave', () {
      final m = TrabajoModel(
        id: 1,
        titulo: 'Tester',
        descripcion: 'Pruebas',
        nombreRubro: 'IT',
        direccionCompleta: 'Calle 1 123',
        estado: 'PUBLICADO',
        urgencia: 'ESTANDAR',
      );

      final json = m.toJson();
      expect(json['id_trabajo'], 1);
      expect(json['titulo'], 'Tester');
      expect(json['descripcion'], 'Pruebas');
      expect(json['estado_publicacion'], 'PUBLICADO');
      expect(json['urgencia'], 'ESTANDAR');
    });
  });
}
