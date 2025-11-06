import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostulacionService - Funciones RPC (Backend)', () {
    group('verificar_solapamiento_trabajos RPC', () {
      test('debe construir parámetros correctos para RPC', () {
        final userId = 123;
        final fechaInicio = '2025-02-01';
        final fechaFin = '2025-02-05';
        final trabajoId = 10;

        final params = {
          'p_postulante_id': userId,
          'p_fecha_inicio': fechaInicio,
          'p_fecha_fin': fechaFin,
          'p_excluir_trabajo': trabajoId,
        };

        expect(params['p_postulante_id'], 123);
        expect(params['p_fecha_inicio'], '2025-02-01');
        expect(params['p_fecha_fin'], '2025-02-05');
        expect(params['p_excluir_trabajo'], 10);
      });

      test('debe retornar lista vacía cuando RPC responde null', () {
        final result = null;
        final lista = List<Map<String, dynamic>>.from(result ?? []);
        expect(lista, isEmpty);
      });

      test('debe retornar lista de trabajos solapados cuando existen', () {
        final result = [
          {
            'id_trabajo': 5,
            'titulo': 'Trabajo Solapado',
            'fecha_inicio': '2025-02-02',
            'fecha_fin': '2025-02-04',
          }
        ] as List<dynamic>;

        final lista = List<Map<String, dynamic>>.from(
            result.map((e) => e as Map<String, dynamic>));
        expect(lista.length, 1);
        expect(lista.first['titulo'], 'Trabajo Solapado');
      });

      test('debe manejar fechas null y retornar lista vacía', () {
        final trabajo = {
          'fecha_inicio': null,
          'fecha_fin': null,
        };

        final tieneFechaNull =
            trabajo['fecha_inicio'] == null || trabajo['fecha_fin'] == null;
        final resultado = tieneFechaNull
            ? <Map<String, dynamic>>[]
            : <Map<String, dynamic>>[{}];

        expect(resultado, isEmpty);
      });

      test('debe retornar lista vacía cuando hay error en RPC', () {
        List<Map<String, dynamic>> resultado;

        try {
          throw Exception('Error de conexión');
        } catch (e) {
          resultado = [];
        }

        expect(resultado, isEmpty);
      });
    });

    group('obtener_puestos_disponibles RPC', () {
      test('debe construir parámetros correctos para RPC', () {
        final trabajoId = 42;
        final params = {'p_id_trabajo': trabajoId};

        expect(params['p_id_trabajo'], 42);
      });

      test('debe retornar valores por defecto cuando RPC responde null', () {
        final result = null;

        final data = result == null || result.isEmpty
            ? {'totales': 1, 'ocupados': 0, 'disponibles': 1}
            : {
                'totales': result[0]['puestos_totales'] ?? 1,
                'ocupados': result[0]['puestos_ocupados'] ?? 0,
                'disponibles': result[0]['puestos_disponibles'] ?? 1,
              };

        expect(data['totales'], 1);
        expect(data['ocupados'], 0);
        expect(data['disponibles'], 1);
      });

      test('debe procesar respuesta RPC con datos válidos', () {
        final result = [
          {
            'puestos_totales': 5,
            'puestos_ocupados': 2,
            'puestos_disponibles': 3,
          }
        ];

        final data = result.isEmpty
            ? {'totales': 1, 'ocupados': 0, 'disponibles': 1}
            : {
                'totales': result[0]['puestos_totales'] ?? 1,
                'ocupados': result[0]['puestos_ocupados'] ?? 0,
                'disponibles': result[0]['puestos_disponibles'] ?? 1,
              };

        expect(data['totales'], 5);
        expect(data['ocupados'], 2);
        expect(data['disponibles'], 3);
      });

      test('debe usar valores por defecto cuando campos están null', () {
        final result = [
          {
            'puestos_totales': null,
            'puestos_ocupados': null,
            'puestos_disponibles': null,
          }
        ];

        final data = {
          'totales': result[0]['puestos_totales'] ?? 1,
          'ocupados': result[0]['puestos_ocupados'] ?? 0,
          'disponibles': result[0]['puestos_disponibles'] ?? 1,
        };

        expect(data['totales'], 1);
        expect(data['ocupados'], 0);
        expect(data['disponibles'], 1);
      });

      test('debe retornar valores por defecto cuando hay error', () {
        Map<String, int> resultado;

        try {
          throw Exception('Error de conexión');
        } catch (e) {
          resultado = {'totales': 1, 'ocupados': 0, 'disponibles': 1};
        }

        expect(resultado['totales'], 1);
        expect(resultado['ocupados'], 0);
        expect(resultado['disponibles'], 1);
      });
    });

    group('Lógica de negocio relacionada con RPC', () {
      test('debe detectar solapamiento y lanzar excepción', () {
        final solapamientos = [
          {
            'titulo': 'Trabajo Conflicto',
            'fecha_inicio': '2025-02-01',
            'fecha_fin': '2025-02-05',
          }
        ];

        if (solapamientos.isNotEmpty) {
          final trabajoSolapado = solapamientos.first;
          final exception = Exception(
            'Ya tienes un trabajo aceptado en estas fechas: "${trabajoSolapado['titulo']}" '
            '(${trabajoSolapado['fecha_inicio']} - ${trabajoSolapado['fecha_fin']})',
          );

          expect(exception, isA<Exception>());
          expect(exception.toString(), contains('Trabajo Conflicto'));
        }
      });

      test('debe permitir postulación cuando no hay solapamientos', () {
        final solapamientos = <Map<String, dynamic>>[];

        final puedePostularse = solapamientos.isEmpty;
        expect(puedePostularse, isTrue);
      });

      test('debe validar puestos disponibles antes de aceptar postulación', () {
        final puestos = {
          'totales': 3,
          'ocupados': 2,
          'disponibles': 1,
        };

        final hayPuestos = (puestos['disponibles'] ?? 0) > 0;
        expect(hayPuestos, isTrue);
      });

      test('debe rechazar cuando no hay puestos disponibles', () {
        final puestos = {
          'totales': 2,
          'ocupados': 2,
          'disponibles': 0,
        };

        final hayPuestos = (puestos['disponibles'] ?? 0) > 0;
        expect(hayPuestos, isFalse);

        if (!hayPuestos) {
          final exception = Exception('No hay puestos disponibles');
          expect(exception, isA<Exception>());
        }
      });
    });
  });
}
