// lib/services/calendario_service.dart
import '../../models/menu_perfil/trabajo_model.dart';
import '../auth_service.dart';
import '../supabase_client.dart';

class CalendarioService {
  
  // ========================================
  // 📅 OBTENER TRABAJOS PROPIOS DEL MES (TODOS - incluyendo pasados)
  // ========================================
  static Future<List<TrabajoModel>> getTrabajosPropiosMes(
    DateTime mes,
  ) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) throw 'Usuario no autenticado';

      final idUsuario = userData.idUsuario;

      // Calcular primer y último día del mes
      final primerDia = DateTime(mes.year, mes.month, 1);
      final ultimoDia = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);

      print('📅 Buscando TODOS los trabajos propios del mes: ${mes.month}/${mes.year}');
      print('   Rango: $primerDia a $ultimoDia');
      print('   ✅ Incluyendo: TODOS los estados (PUBLICADO, VENCIDO, COMPLETO, etc.)');

      final response = await supabase
          .from('trabajo')
          .select('''
            *,
            rubro:id_rubro(id_rubro, nombre),
            ubicacion:ubicacion_id(id_ubicacion, nombre, calle, numero, ciudad, provincia),
            pago:id_pago(id_pago, monto, metodo, estado, periodo)
          ''')
          .eq('empleador_id', idUsuario)
          .gte('fecha_inicio', primerDia.toIso8601String())
          .lte('fecha_inicio', ultimoDia.toIso8601String())
          .order('fecha_inicio', ascending: true);
          // ✅ NO FILTRAMOS POR ESTADO - traemos todos

      print('✅ ${(response as List).length} trabajos propios encontrados (todos los estados)');

      return (response as List)
          .map((json) => TrabajoModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error al obtener trabajos propios del mes: $e');
      return [];
    }
  }

  // ========================================
  // 🙋 OBTENER POSTULACIONES DEL MES
  // ========================================
  static Future<List<Map<String, dynamic>>> getPostulacionesMes(
    DateTime mes,
  ) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) throw 'Usuario no autenticado';

      final idUsuario = userData.idUsuario;

      final primerDia = DateTime(mes.year, mes.month, 1);
      final ultimoDia = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);

      print('📅 Buscando postulaciones del mes: ${mes.month}/${mes.year}');

      final response = await supabase
          .from('postulacion')
          .select('''
            id_postulacion,
            estado,
            fecha_postulacion,
            trabajo:trabajo_id (
              id_trabajo,
              titulo,
              descripcion,
              fecha_inicio,
              fecha_fin,
              horario_inicio,
              horario_fin,
              estado_publicacion,
              rubro:id_rubro(nombre),
              ubicacion:ubicacion_id(ciudad, provincia)
            )
          ''')
          .eq('postulante_id', idUsuario)
          .not('trabajo', 'is', null); // Solo donde el trabajo existe

      // Filtrar por fecha en memoria (porque es del trabajo, no de la postulación)
      final postulaciones = (response as List).where((item) {
        if (item['trabajo'] == null) return false;
        
        final fechaInicioStr = item['trabajo']['fecha_inicio'];
        if (fechaInicioStr == null) return false;

        final fechaInicio = DateTime.parse(fechaInicioStr);
        return fechaInicio.isAfter(primerDia.subtract(Duration(days: 1))) &&
               fechaInicio.isBefore(ultimoDia.add(Duration(days: 1)));
      }).toList();

      print('✅ ${postulaciones.length} postulaciones encontradas');

      return postulaciones.map((p) => Map<String, dynamic>.from(p)).toList();
    } catch (e) {
      print('❌ Error al obtener postulaciones del mes: $e');
      return [];
    }
  }

  // ========================================
  // 📊 OBTENER EVENTOS DEL MES (UNIFICADO)
  // ========================================
  static Future<Map<String, dynamic>> getEventosMes(DateTime mes) async {
    try {
      print('📊 Obteniendo eventos del mes ${mes.month}/${mes.year}');

      final trabajosPropios = await getTrabajosPropiosMes(mes);
      final postulaciones = await getPostulacionesMes(mes);

      // Convertir a eventos del calendario
      final eventos = <DateTime, List<Map<String, dynamic>>>{};

      // Agregar trabajos propios
      for (var trabajo in trabajosPropios) {
        // ✅ NUEVO: Calcular todos los días entre fecha_inicio y fecha_fin
        final fechaInicio = DateTime(
          trabajo.fechaInicio.year,
          trabajo.fechaInicio.month,
          trabajo.fechaInicio.day,
        );
        
        final fechaFin = trabajo.fechaFin != null
            ? DateTime(
                trabajo.fechaFin!.year,
                trabajo.fechaFin!.month,
                trabajo.fechaFin!.day,
              )
            : fechaInicio; // Si no hay fecha_fin, solo dura 1 día

        print('📅 Trabajo "${trabajo.titulo}": $fechaInicio a $fechaFin');

        // ✅ CORREGIDO: Detectar si está pasado (comparar solo fechas, sin horas)
        final estaVencido = trabajo.estadoPublicacion == EstadoPublicacion.VENCIDO;
        final estaCancelado = trabajo.estadoPublicacion == EstadoPublicacion.CANCELADO;
        final estaFinalizado = trabajo.estadoPublicacion == EstadoPublicacion.FINALIZADO ||
                               trabajo.estadoPublicacion == EstadoPublicacion.COMPLETO;
        
        // ✅ Normalizar fechas a medianoche para comparar solo día/mes/año
        final fechaFinNormalizada = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
        final hoy = DateTime.now();
        final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);
        
        final trabajoTermino = fechaFinNormalizada.isBefore(hoyNormalizado); // Solo SI ya pasó
        
        // Un trabajo está "pasado" si:
        // - Su estado es VENCIDO, CANCELADO, FINALIZADO o COMPLETO
        // - O su fecha_fin ya pasó (comparando solo fechas, sin horas)
        final isPasado = estaVencido || estaCancelado || estaFinalizado || trabajoTermino;

        // ✅ AGREGAR EVENTO EN CADA DÍA DE DURACIÓN
        DateTime currentDate = fechaInicio;
        while (currentDate.isBefore(fechaFin.add(Duration(days: 1)))) {
          if (!eventos.containsKey(currentDate)) {
            eventos[currentDate] = [];
          }

          eventos[currentDate]!.add({
            'tipo': 'PROPIO',
            'id': trabajo.id,
            'titulo': trabajo.titulo,
            'estado': trabajo.estadoPublicacion.toString().split('.').last,
            'isPasado': isPasado,
            'data': trabajo,
          });

          currentDate = currentDate.add(Duration(days: 1));
        }
      }

      // Agregar postulaciones
      for (var postulacion in postulaciones) {
        if (postulacion['trabajo'] == null) continue;

        final trabajo = postulacion['trabajo'];
        final fechaInicioStr = trabajo['fecha_inicio'];
        if (fechaInicioStr == null) continue;

        final fechaInicio = DateTime.parse(fechaInicioStr);
        
        // ✅ NUEVO: Considerar fecha_fin también
        final fechaFinStr = trabajo['fecha_fin'];
        final fechaFin = fechaFinStr != null
            ? DateTime.parse(fechaFinStr)
            : fechaInicio;

        final fechaInicioNormalizada = DateTime(
          fechaInicio.year,
          fechaInicio.month,
          fechaInicio.day,
        );

        final fechaFinNormalizada = DateTime(
          fechaFin.year,
          fechaFin.month,
          fechaFin.day,
        );

        print('📅 Postulación "${trabajo['titulo']}": $fechaInicioNormalizada a $fechaFinNormalizada');

        // ✅ Normalizar hoy para comparar solo fechas
        final hoy = DateTime.now();
        final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);
        final trabajoYaPaso = fechaFinNormalizada.isBefore(hoyNormalizado);

        // ✅ AGREGAR EVENTO EN CADA DÍA DE DURACIÓN
        DateTime currentDate = fechaInicioNormalizada;
        while (currentDate.isBefore(fechaFinNormalizada.add(Duration(days: 1)))) {
          if (!eventos.containsKey(currentDate)) {
            eventos[currentDate] = [];
          }

          eventos[currentDate]!.add({
            'tipo': 'POSTULACION',
            'id': trabajo['id_trabajo'],
            'titulo': trabajo['titulo'],
            'estado': postulacion['estado'],
            'estadoTrabajo': trabajo['estado_publicacion'],
            'isPasado': trabajoYaPaso,
            'data': trabajo,
          });

          currentDate = currentDate.add(Duration(days: 1));
        }
      }

      print('✅ Total de días con eventos: ${eventos.length}');

      return {
        'eventos': eventos,
        'trabajosPropios': trabajosPropios,
        'postulaciones': postulaciones,
      };
    } catch (e) {
      print('❌ Error al obtener eventos del mes: $e');
      return {
        'eventos': <DateTime, List<Map<String, dynamic>>>{},
        'trabajosPropios': [],
        'postulaciones': [],
      };
    }
  }

  // ========================================
  // 🔍 OBTENER EVENTOS DE UN DÍA ESPECÍFICO
  // ========================================
  static Future<List<Map<String, dynamic>>> getEventosDia(
    DateTime dia,
  ) async {
    try {
      final mesData = await getEventosMes(dia);
      final eventos = mesData['eventos'] as Map<DateTime, List<Map<String, dynamic>>>;

      final diaNormalizado = DateTime(dia.year, dia.month, dia.day);
      
      return eventos[diaNormalizado] ?? [];
    } catch (e) {
      print('❌ Error al obtener eventos del día: $e');
      return [];
    }
  }

  // ========================================
  // 📈 OBTENER ESTADÍSTICAS DEL MES
  // ========================================
  static Future<Map<String, int>> getEstadisticasMes(DateTime mes) async {
    try {
      final data = await getEventosMes(mes);
      
      final trabajosPropios = (data['trabajosPropios'] as List).length;
      final postulaciones = (data['postulaciones'] as List).length;
      final eventos = data['eventos'] as Map<DateTime, List<Map<String, dynamic>>>;
      
      int trabajosPasados = 0;
      int trabajosFuturos = 0;
      int postulacionesAceptadas = 0;

      eventos.forEach((fecha, listaEventos) {
        for (var evento in listaEventos) {
          if (evento['isPasado'] == true) {
            trabajosPasados++;
          } else {
            trabajosFuturos++;
          }

          if (evento['tipo'] == 'POSTULACION' && evento['estado'] == 'ACEPTADO') {
            postulacionesAceptadas++;
          }
        }
      });

      return {
        'trabajosPropios': trabajosPropios,
        'postulaciones': postulaciones,
        'trabajosPasados': trabajosPasados,
        'trabajosFuturos': trabajosFuturos,
        'postulacionesAceptadas': postulacionesAceptadas,
        'diasConEventos': eventos.length,
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {};
    }
  }
}