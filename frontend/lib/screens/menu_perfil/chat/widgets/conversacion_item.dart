// lib/screens/chat/widgets/conversacion_item.dart

import 'package:flutter/material.dart';
import 'package:changapp_client/models/chat/conversacion_model.dart';

class ConversacionItem extends StatelessWidget {
  final Conversacion conversacion;
  final int usuarioId;
  final VoidCallback onTap;

  const ConversacionItem({
    Key? key,
    required this.conversacion,
    required this.usuarioId,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final noLeidos = conversacion.obtenerNoLeidos(usuarioId);
    final nombreOtro = conversacion.obtenerNombreOtroParticipante(usuarioId) ??
        'Usuario desconocido';
    final fotoOtro = conversacion.obtenerFotoOtroParticipante(usuarioId);

    return Material(
      color: noLeidos > 0 ? const Color(0xFFFFF5F5) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(nombreOtro, fotoOtro, noLeidos),
              const SizedBox(width: 12),

              // Contenido
              Expanded(
                child: _buildContenido(nombreOtro, noLeidos),
              ),

              // Chevron
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String nombre, String? foto, int noLeidos) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFC5414B).withOpacity(0.1),
          backgroundImage: foto != null ? NetworkImage(foto) : null,
          child: foto == null
              ? Text(
                  nombre[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC5414B),
                  ),
                )
              : null,
        ),
        // Badge de no leídos
        if (noLeidos > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFC5414B),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(
                child: Text(
                  noLeidos > 99 ? '99+' : '$noLeidos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContenido(String nombre, int noLeidos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre y hora
        Row(
          children: [
            Expanded(
              child: Text(
                nombre,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: noLeidos > 0 ? FontWeight.bold : FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversacion.timestampUltimoMensaje != null)
              Text(
                _formatearHora(conversacion.timestampUltimoMensaje!),
                style: TextStyle(
                  fontSize: 12,
                  color: noLeidos > 0
                      ? const Color(0xFFC5414B)
                      : Colors.grey[600],
                  fontWeight:
                      noLeidos > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),

        // Título del trabajo
        if (conversacion.tituloTrabajo != null)
          Text(
            conversacion.tituloTrabajo!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

        // Último mensaje
        if (conversacion.ultimoMensaje != null) ...[
          const SizedBox(height: 4),
          Text(
            conversacion.ultimoMensaje!,
            style: TextStyle(
              fontSize: 14,
              color: noLeidos > 0 ? Colors.black87 : Colors.grey[700],
              fontWeight: noLeidos > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _formatearHora(DateTime timestamp) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(timestamp);

    if (diferencia.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return dias[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}