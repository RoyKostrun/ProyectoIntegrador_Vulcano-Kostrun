// lib/screens/chat/widgets/mensaje_bubble.dart

import 'package:flutter/material.dart';
import 'package:changapp_client/models/chat/mensaje_model.dart';

class MensajeBubble extends StatelessWidget {
  final Mensaje mensaje;
  final bool esPropio;
  final String nombreRemitente;

  const MensajeBubble({
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