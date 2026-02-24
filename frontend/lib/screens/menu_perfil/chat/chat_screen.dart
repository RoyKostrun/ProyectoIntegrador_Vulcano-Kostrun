// lib/screens/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:changapp_client/services/chat_service.dart';
import 'package:changapp_client/models/chat/conversacion_model.dart';
import 'package:changapp_client/models/chat/mensaje_model.dart';

class ChatScreen extends StatefulWidget {
  final Conversacion conversacion;
  final int usuarioId;

  const ChatScreen({
    Key? key,
    required this.conversacion,
    required this.usuarioId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isEnviando = false;

  @override
  void initState() {
    super.initState();
    _marcarComoLeido();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

//lib/screens/menu_perfil/chat/chat_screen.dart

  Future<void> _marcarComoLeido() async {
    try {
      await _chatService.marcarComoLeido(
        conversacionId: widget.conversacion.idConversacion,
        usuarioId: widget.usuarioId,
      );

      // Forzar actualización del estado después de un pequeño delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ Error al marcar como leído: $e');
    }
  }

  Future<void> _enviarMensaje() async {
    final contenido = _mensajeController.text.trim();

    if (contenido.isEmpty) return;

    setState(() => _isEnviando = true);

    try {
      await _chatService.enviarMensaje(
        conversacionId: widget.conversacion.idConversacion,
        remitenteId: widget.usuarioId,
        contenido: contenido,
      );

      _mensajeController.clear();

      // Hacer scroll al final después de enviar
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreOtro =
        widget.conversacion.obtenerNombreOtroParticipante(widget.usuarioId) ??
            'Usuario';
    final fotoOtro =
        widget.conversacion.obtenerFotoOtroParticipante(widget.usuarioId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Avatar pequeño
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage:
                      fotoOtro != null ? NetworkImage(fotoOtro) : null,
                  child: fotoOtro == null
                      ? Text(
                          nombreOtro[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                // Indicador online
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombreOtro,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'En línea', // TODO: Implementar estado real
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _mostrarInfoTrabajo();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: StreamBuilder<List<Mensaje>>(
              stream: _chatService
                  .streamMensajes(widget.conversacion.idConversacion),
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
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar mensajes',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final mensajes = snapshot.data ?? [];

                // Auto-scroll al cargar mensajes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: mensajes.length + 1, // +1 para el mensaje inicial
                  itemBuilder: (context, index) {
                    // Mensaje inicial del sistema
                    if (index == 0) {
                      return _buildMensajeInicial();
                    }

                    final mensaje = mensajes[index - 1];
                    final esPropio = mensaje.remitenteId == widget.usuarioId;
                    final mostrarFecha = index == 1 ||
                        !_esMismoDia(
                          mensajes[index - 2].createdAt,
                          mensaje.createdAt,
                        );

                    return Column(
                      children: [
                        // Separador de fecha
                        if (mostrarFecha)
                          _buildFechaSeparador(mensaje.createdAt),

                        // Burbuja de mensaje
                        _MensajeBubble(
                          mensaje: mensaje,
                          esPropio: esPropio,
                          nombreRemitente: esPropio
                              ? 'Tú'
                              : widget.conversacion
                                      .obtenerNombreOtroParticipante(
                                          widget.usuarioId) ??
                                  'Usuario',
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input de mensaje
          _buildMensajeInput(),
        ],
      ),
    );
  }

  // ✅ NUEVO: Mensaje inicial con info del trabajo
  Widget _buildMensajeInicial() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFC5414B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.work_outline,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),

          // Título
          const Text(
            'Conversación iniciada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Trabajo
          if (widget.conversacion.tituloTrabajo != null) ...[
            Text(
              'Trabajo: ${widget.conversacion.tituloTrabajo}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Mensaje
          Text(
            'Esta es una conversación privada entre el empleador y el empleado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarInfoTrabajo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Título
            const Text(
              'Información del trabajo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Info
            if (widget.conversacion.tituloTrabajo != null)
              _buildInfoRow(
                Icons.work,
                'Trabajo',
                widget.conversacion.tituloTrabajo!,
              ),

            _buildInfoRow(
              Icons.person,
              'Empleador',
              widget.conversacion.nombreEmpleador ?? 'No disponible',
            ),

            _buildInfoRow(
              Icons.person_outline,
              'Empleado',
              widget.conversacion.nombreEmpleado ?? 'No disponible',
            ),

            const SizedBox(height: 16),

            // Botón Reportar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implementar funcionalidad
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Función de reporte próximamente')),
                  );
                },
                icon: const Icon(Icons.flag_outlined, color: Colors.orange),
                label: const Text('Reportar usuario',
                    style: TextStyle(color: Colors.orange)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botón Bloquear
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implementar funcionalidad
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Función de bloqueo próximamente')),
                  );
                },
                icon: const Icon(Icons.block, color: Colors.red),
                label: const Text('Bloquear usuario',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botón cerrar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5414B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFC5414B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFechaSeparador(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    String texto;
    if (diferencia.inDays == 0) {
      texto = 'Hoy';
    } else if (diferencia.inDays == 1) {
      texto = 'Ayer';
    } else if (diferencia.inDays < 7) {
      const dias = [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo'
      ];
      texto = dias[fecha.weekday - 1];
    } else {
      texto = '${fecha.day}/${fecha.month}/${fecha.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMensajeInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            // Campo de texto
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _mensajeController,
                  enabled: !_isEnviando,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _enviarMensaje(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Botón enviar
            Material(
              color: _isEnviando ? Colors.grey[300] : const Color(0xFFC5414B),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _isEnviando ? null : _enviarMensaje,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: _isEnviando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _esMismoDia(DateTime fecha1, DateTime fecha2) {
    return fecha1.year == fecha2.year &&
        fecha1.month == fecha2.month &&
        fecha1.day == fecha2.day;
  }
}

// ============================================================
// WIDGET: Burbuja de mensaje
// ============================================================

class _MensajeBubble extends StatelessWidget {
  final Mensaje mensaje;
  final bool esPropio;
  final String nombreRemitente;

  const _MensajeBubble({
    Key? key,
    required this.mensaje,
    required this.esPropio,
    required this.nombreRemitente,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            esPropio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esPropio) const SizedBox(width: 8),

          // Burbuja
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: esPropio ? const Color(0xFFC5414B) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: esPropio
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: esPropio
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contenido del mensaje
                  Text(
                    mensaje.contenido,
                    style: TextStyle(
                      fontSize: 15,
                      color: esPropio ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Hora y estado
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatearHora(mensaje.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: esPropio
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[600],
                        ),
                      ),
                      if (esPropio) ...[
                        const SizedBox(width: 4),
                        Icon(
                          mensaje.leido ? Icons.done_all : Icons.done,
                          size: 14,
                          color: mensaje.leido
                              ? Colors.lightBlueAccent
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (esPropio) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatearHora(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
