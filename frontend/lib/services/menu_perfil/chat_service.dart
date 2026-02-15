// lib/services/chat/chat_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/chat/conversacion_model.dart';
import '../../models/chat/mensaje_model.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client; 

  // ============================================================
  // CONVERSACIONES
  // ============================================================

  /// Obtener todas las conversaciones del usuario actual
  /// Incluye datos del otro participante mediante JOIN
  Future<List<Conversacion>> obtenerConversaciones(int usuarioId) async {
    try {
      final response = await _supabase
          .from('conversacion')
          .select('''
            *,
            postulacion!inner(
              trabajo!inner(
                titulo,
                empleador_id
              )
            )
          ''')
          .or('empleador_id.eq.$usuarioId,empleado_id.eq.$usuarioId')
          .eq('activo', true)
          .order('timestamp_ultimo_mensaje', ascending: false);

      // Convertir respuesta a lista de Conversacion
      final conversaciones = <Conversacion>[];

      for (final item in response as List<dynamic>) {
        final conversacion = await _enriquecerConversacion(item);
        conversaciones.add(conversacion);
      }

      return conversaciones;
    } catch (e) {
      print('❌ Error al obtener conversaciones: $e');
      throw Exception('Error al cargar conversaciones: $e');
    }
  }

  /// Obtener conversación por ID de postulación
  Future<Conversacion?> obtenerConversacionPorPostulacion(
      int postulacionId) async {
    try {
      final response = await _supabase
          .from('conversacion')
          .select('''
            *,
            postulacion!inner(
              trabajo!inner(
                titulo
              )
            )
          ''')
          .eq('id_postulacion', postulacionId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return await _enriquecerConversacion(response);
    } catch (e) {
      print('❌ Error al obtener conversación por postulación: $e');
      throw Exception('Error al cargar conversación: $e');
    }
  }

  /// Crear o obtener conversación para una postulación
  Future<Conversacion> obtenerOCrearConversacion(int postulacionId) async {
    try {
      // Primero intentar obtener conversación existente
      final conversacionExistente =
          await obtenerConversacionPorPostulacion(postulacionId);

      if (conversacionExistente != null) {
        return conversacionExistente;
      }

      // Si no existe, usar la función SQL para crearla
      final result = await _supabase.rpc(
        'obtener_o_crear_conversacion',
        params: {'p_postulacion_id': postulacionId},
      );

      final conversacionId = result as int;

      // Obtener la conversación recién creada
      final response = await _supabase
          .from('conversacion')
          .select('''
            *,
            postulacion!inner(
              trabajo!inner(
                titulo
              )
            )
          ''')
          .eq('id_conversacion', conversacionId)
          .single();

      return await _enriquecerConversacion(response);
    } catch (e) {
      print('❌ Error al crear/obtener conversación: $e');
      throw Exception('Error al iniciar conversación: $e');
    }
  }

  /// Método helper privado para enriquecer conversación con datos de usuarios
  Future<Conversacion> _enriquecerConversacion(
      Map<String, dynamic> data) async {
    try {
      final empleadorId = data['empleador_id'] as int;
      final empleadoId = data['empleado_id'] as int;

      // Obtener datos del empleador
      final empleadorResponse = await _supabase
          .from('usuario')
          .select('''
            *,
            usuario_persona(nombre, apellido, foto_perfil_url),
            usuario_empresa(nombre_corporativo, foto_perfil_url)
          ''')
          .eq('id_usuario', empleadorId)
          .single();

      // Obtener datos del empleado
      final empleadoResponse = await _supabase
          .from('usuario')
          .select('''
            *,
            usuario_persona(nombre, apellido, foto_perfil_url)
          ''')
          .eq('id_usuario', empleadoId)
          .single();

      // Extraer nombre y foto del empleador
      String? nombreEmpleador;
      String? fotoEmpleador;

      if (empleadorResponse['tipo_usuario'] == 'PERSONA') {
        final persona = empleadorResponse['usuario_persona'];
        if (persona is List && persona.isNotEmpty) {
          nombreEmpleador =
              '${persona[0]['nombre']} ${persona[0]['apellido']}';
          fotoEmpleador = persona[0]['foto_perfil_url'];
        } else if (persona is Map) {
          nombreEmpleador = '${persona['nombre']} ${persona['apellido']}';
          fotoEmpleador = persona['foto_perfil_url'];
        }
      } else if (empleadorResponse['tipo_usuario'] == 'EMPRESA') {
        final empresa = empleadorResponse['usuario_empresa'];
        if (empresa is List && empresa.isNotEmpty) {
          nombreEmpleador = empresa[0]['nombre_corporativo'];
          fotoEmpleador = empresa[0]['foto_perfil_url'];
        } else if (empresa is Map) {
          nombreEmpleador = empresa['nombre_corporativo'];
          fotoEmpleador = empresa['foto_perfil_url'];
        }
      }

      // Extraer nombre y foto del empleado
      String? nombreEmpleado;
      String? fotoEmpleado;

      final empleadoPersona = empleadoResponse['usuario_persona'];
      if (empleadoPersona is List && empleadoPersona.isNotEmpty) {
        nombreEmpleado =
            '${empleadoPersona[0]['nombre']} ${empleadoPersona[0]['apellido']}';
        fotoEmpleado = empleadoPersona[0]['foto_perfil_url'];
      } else if (empleadoPersona is Map) {
        nombreEmpleado =
            '${empleadoPersona['nombre']} ${empleadoPersona['apellido']}';
        fotoEmpleado = empleadoPersona['foto_perfil_url'];
      }

      // Extraer título del trabajo
      String? tituloTrabajo;
      final postulacion = data['postulacion'];
      if (postulacion != null) {
        final trabajo = postulacion is Map
            ? postulacion['trabajo']
            : (postulacion is List && postulacion.isNotEmpty)
                ? postulacion[0]['trabajo']
                : null;

        if (trabajo != null) {
          tituloTrabajo = trabajo is Map
              ? trabajo['titulo']
              : (trabajo is List && trabajo.isNotEmpty)
                  ? trabajo[0]['titulo']
                  : null;
        }
      }

      return Conversacion.fromJson({
        ...data,
        'nombre_empleador': nombreEmpleador,
        'nombre_empleado': nombreEmpleado,
        'foto_empleador': fotoEmpleador,
        'foto_empleado': fotoEmpleado,
        'titulo_trabajo': tituloTrabajo,
      });
    } catch (e) {
      print('❌ Error al enriquecer conversación: $e');
      // Si falla el enriquecimiento, devolver conversación sin datos extra
      return Conversacion.fromJson(data);
    }
  }

  // ============================================================
  // MENSAJES
  // ============================================================

  /// Obtener mensajes de una conversación (paginado)
  Future<List<Mensaje>> obtenerMensajes(
    int conversacionId, {
    int limite = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('mensaje')
          .select('*')
          .eq('id_conversacion', conversacionId)
          .order('created_at', ascending: false)
          .range(offset, offset + limite - 1);

      return (response as List<dynamic>)
          .map((json) => Mensaje.fromJson(json))
          .toList()
          .reversed
          .toList(); // Invertir para tener orden cronológico
    } catch (e) {
      print('❌ Error al obtener mensajes: $e');
      throw Exception('Error al cargar mensajes: $e');
    }
  }

  /// Enviar mensaje
  Future<Mensaje> enviarMensaje({
    required int conversacionId,
    required int remitenteId,
    required String contenido,
  }) async {
    try {
      // Validar contenido
      if (contenido.trim().isEmpty) {
        throw Exception('El mensaje no puede estar vacío');
      }

      final response = await _supabase
          .from('mensaje')
          .insert({
            'id_conversacion': conversacionId,
            'remitente_id': remitenteId,
            'contenido': contenido.trim(),
          })
          .select()
          .single();

      return Mensaje.fromJson(response);
    } catch (e) {
      print('❌ Error al enviar mensaje: $e');
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  /// Marcar mensajes como leídos
  Future<void> marcarComoLeido({
    required int conversacionId,
    required int usuarioId,
  }) async {
    try {
      await _supabase.rpc(
        'marcar_mensajes_leidos',
        params: {
          'p_conversacion_id': conversacionId,
          'p_usuario_id': usuarioId,
        },
      );
    } catch (e) {
      print('❌ Error al marcar como leído: $e');
      // No lanzar excepción aquí, ya que no es crítico
    }
  }

  // ============================================================
  // REALTIME - STREAMS
  // ============================================================

  /// Stream de mensajes en tiempo real para una conversación
  Stream<List<Mensaje>> streamMensajes(int conversacionId) {
    return _supabase
        .from('mensaje')
        .stream(primaryKey: ['id_mensaje'])
        .eq('id_conversacion', conversacionId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => Mensaje.fromJson(json)).toList());
  }

  /// Stream de conversaciones en tiempo real
  Stream<List<Conversacion>> streamConversaciones(int usuarioId) async* {
    // Primero emitir la carga inicial
    final inicial = await obtenerConversaciones(usuarioId);
    yield inicial;

    // Luego escuchar cambios en tiempo real
    await for (final data in _supabase
        .from('conversacion')
        .stream(primaryKey: ['id_conversacion'])
        .order('timestamp_ultimo_mensaje', ascending: false)) {
      final conversaciones = <Conversacion>[];

      for (final item in data) {
        // Filtrar solo conversaciones del usuario
        if (item['empleador_id'] == usuarioId ||
            item['empleado_id'] == usuarioId) {
          final conversacion = await _enriquecerConversacion(item);
          conversaciones.add(conversacion);
        }
      }

      yield conversaciones;
    }
  }

  // ============================================================
  // UTILIDADES
  // ============================================================

  /// Obtener contador total de mensajes no leídos
  Future<int> obtenerTotalNoLeidos(int usuarioId) async {
    try {
      final conversaciones = await obtenerConversaciones(usuarioId);

      return conversaciones.fold<int>(
        0,
        (total, conv) => total + conv.obtenerNoLeidos(usuarioId),
      );
    } catch (e) {
      print('❌ Error al obtener total no leídos: $e');
      return 0;
    }
  }

  /// Verificar si el usuario puede acceder a una conversación
  Future<bool> puedeAcceder(int conversacionId, int usuarioId) async {
    try {
      final response = await _supabase
          .from('conversacion')
          .select('empleador_id, empleado_id')
          .eq('id_conversacion', conversacionId)
          .maybeSingle();

      if (response == null) return false;

      return response['empleador_id'] == usuarioId ||
          response['empleado_id'] == usuarioId;
    } catch (e) {
      print('❌ Error al verificar acceso: $e');
      return false;
    }
  }
}