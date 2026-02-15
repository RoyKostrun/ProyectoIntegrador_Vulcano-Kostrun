//lib/screens/menu_perfil/notificaciones/notificaciones_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/menu_perfil/notificacion_model.dart';
import '../../../services/notificacion/notificacion_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/auth_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen>
    with AutomaticKeepAliveClientMixin {  // ← AGREGADO
  
  final NotificacionService _notificacionService = NotificacionService();
  final ChatService _chatService = ChatService();
  int? _currentUserId;

  @override
  bool get wantKeepAlive => true;  // ← AGREGADO

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // ← AGREGADO: Refrescar cuando vuelves a la pantalla
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadUserId() async {
    try {
      final userData = await AuthService.getCurrentUserData();
      setState(() {
        _currentUserId = userData?.idUsuario;
      });
    } catch (e) {
      print('Error cargando ID usuario: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);  // ← AGREGADO: Necesario para AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFC5414B),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,  // ← AGREGADO: Sin botón atrás
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como leídas',
            onPressed: () async {
              final success = await _notificacionService.marcarTodasComoLeidas();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todas las notificaciones marcadas como leídas'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Notificacion>>(
        stream: _notificacionService.streamNotificaciones(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFC5414B),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar notificaciones',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final notificaciones = snapshot.data ?? [];

          if (notificaciones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cuando recibas notificaciones aparecerán aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notificaciones.length,
            itemBuilder: (context, index) {
              final notificacion = notificaciones[index];
              return _buildNotificacionCard(notificacion);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificacionCard(Notificacion notificacion) {
    return Dismissible(
      key: Key('notif_${notificacion.idNotificacion}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) async {
        await _notificacionService.eliminarNotificacion(notificacion.idNotificacion);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notificación eliminada'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: notificacion.noLeida ? Colors.white : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notificacion.noLeida
                ? notificacion.color.withOpacity(0.3)
                : Colors.grey[300]!,
            width: notificacion.noLeida ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _handleNotificacionTap(notificacion),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: notificacion.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      notificacion.icono,
                      color: notificacion.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notificacion.titulo,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notificacion.noLeida
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (notificacion.noLeida)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC5414B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notificacion.mensaje,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notificacion.fechaRelativa,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificacionTap(Notificacion notificacion) async {
    if (notificacion.noLeida) {
      await _notificacionService.marcarComoLeida(notificacion.idNotificacion);
    }

    if (!mounted) return;

    final datos = notificacion.datosAdicionales;
    if (datos == null) return;

    switch (notificacion.tipo) {
      case TipoNotificacion.mensaje:
        await _navegarAChat(datos);
        break;

      case TipoNotificacion.postulacion:
        await _navegarAPostulacion(datos);
        break;

      case TipoNotificacion.trabajo:
        await _navegarATrabajo(datos);
        break;

      default:
        break;
    }
    
    // ← AGREGADO: Refrescar al volver
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _navegarAChat(Map<String, dynamic> datos) async {
    try {
      final idConversacion = datos['id_conversacion'] as int?;

      if (idConversacion == null || _currentUserId == null) {
        _mostrarError('No se puede abrir la conversación');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFC5414B)),
        ),
      );

      final conversacion = await _chatService.obtenerConversacionPorId(idConversacion);

      if (mounted) Navigator.pop(context);

      if (conversacion == null) {
        _mostrarError('Conversación no encontrada');
        return;
      }

      if (mounted) {
        await Navigator.pushNamed(  // ← AGREGADO: await
          context,
          '/chat',
          arguments: {
            'conversacion': conversacion,
            'usuarioId': _currentUserId!,
          },
        );
        
        // ← AGREGADO: Refrescar al volver
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('❌ Error navegando a chat: $e');
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _mostrarError('Error al abrir conversación');
    }
  }

  Future<void> _navegarAPostulacion(Map<String, dynamic> datos) async {
    try {
      final idTrabajo = datos['id_trabajo'] as int?;
      
      if (idTrabajo == null || _currentUserId == null) {
        _mostrarError('No se puede abrir el trabajo');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFC5414B)),
        ),
      );

      final response = await Supabase.instance.client
          .from('trabajo')
          .select('empleador_id')
          .eq('id_trabajo', idTrabajo)
          .single();

      final empleadorId = response['empleador_id'] as int;
      final esTrabajoPropio = empleadorId == _currentUserId;

      if (mounted) Navigator.pop(context);

      if (mounted) {
        await Navigator.pushNamed(  // ← AGREGADO: await
          context,
          esTrabajoPropio ? '/detalle-trabajo-propio' : '/detalle-trabajo',
          arguments: idTrabajo,
        );
        
        // ← AGREGADO: Refrescar al volver
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _mostrarError('Error al abrir trabajo: $e');
    }
  }

  Future<void> _navegarATrabajo(Map<String, dynamic> datos) async {
    try {
      final idTrabajo = datos['id_trabajo'] as int?;
      
      if (idTrabajo == null || _currentUserId == null) {
        _mostrarError('No se puede abrir el trabajo');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFC5414B)),
        ),
      );

      final response = await Supabase.instance.client
          .from('trabajo')
          .select('empleador_id')
          .eq('id_trabajo', idTrabajo)
          .single();

      final empleadorId = response['empleador_id'] as int;
      final esTrabajoPropio = empleadorId == _currentUserId;

      if (mounted) Navigator.pop(context);

      if (mounted) {
        await Navigator.pushNamed(  // ← AGREGADO: await
          context,
          esTrabajoPropio ? '/detalle-trabajo-propio' : '/detalle-trabajo',
          arguments: idTrabajo,
        );
        
        // ← AGREGADO: Refrescar al volver
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _mostrarError('Error al abrir trabajo: $e');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}