// lib/widgets/trabajo_propio_card.dart

import 'package:flutter/material.dart';
import '../models/menu_perfil/trabajo_model.dart';
import '../screens/jobs/detalle_trabajo_propio_screen.dart';
import '../services/menu_perfil/trabajo_service.dart';

class TrabajoPropioCard extends StatelessWidget {
  final TrabajoModel trabajo;
  final VoidCallback? onDeleted;

  const TrabajoPropioCard({
    Key? key,
    required this.trabajo,
    this.onDeleted,
  }) : super(key: key);

  bool _estaVencido() {
    if (trabajo.estadoPublicacion == EstadoPublicacion.VENCIDO ||
        trabajo.estadoPublicacion == EstadoPublicacion.CANCELADO ||
        trabajo.estadoPublicacion == EstadoPublicacion.COMPLETO ||
        trabajo.estadoPublicacion == EstadoPublicacion.FINALIZADO) {
      return true;
    }
    
    final fechaFin = trabajo.fechaFin ?? trabajo.fechaInicio;
    final hoy = DateTime.now();
    final fechaFinNormalizada = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);
    
    return fechaFinNormalizada.isBefore(hoyNormalizado);
  }

  String _getEstadoLabel(EstadoPublicacion estado) {
    switch (estado) {
      case EstadoPublicacion.PUBLICADO:
        return 'Publicado';
      case EstadoPublicacion.EN_PROGRESO:
        return 'En Progreso';
      case EstadoPublicacion.COMPLETO:
        return 'Completo';
      case EstadoPublicacion.FINALIZADO:
        return 'Finalizado';
      case EstadoPublicacion.VENCIDO:
        return 'Vencido';
      case EstadoPublicacion.CANCELADO:
        return 'Cancelado';
    }
  }

  Color _getEstadoColor(EstadoPublicacion estado) {
    switch (estado) {
      case EstadoPublicacion.PUBLICADO:
        return const Color(0xFF4CAF50);
      case EstadoPublicacion.EN_PROGRESO:
        return const Color(0xFFFF9800);
      case EstadoPublicacion.COMPLETO:
      case EstadoPublicacion.FINALIZADO:
        return const Color(0xFF2196F3);
      case EstadoPublicacion.VENCIDO:
        return Colors.grey;
      case EstadoPublicacion.CANCELADO:
        return Colors.red;
    }
  }

  String _formatDateRange(DateTime inicio, DateTime? fin) {
    final meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    final inicioStr = '${inicio.day} ${meses[inicio.month - 1]}';

    if (fin != null && fin != inicio) {
      final finStr = '${fin.day} ${meses[fin.month - 1]}';
      return '$inicioStr - $finStr';
    }

    return inicioStr;
  }

  String _getPeriodoLabel(String? periodo) {
    switch (periodo?.toUpperCase()) {
      case 'POR_HORA':
        return 'por hora';
      case 'POR_DIA':
        return 'por día';
      case 'POR_TRABAJO':
        return 'total';
      default:
        return '';
    }
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Trabajo'),
        content: Text('¿Estás seguro de eliminar "${trabajo.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      try {
        await TrabajoService().deleteTrabajo(trabajo.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Trabajo eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          onDeleted?.call();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vencido = _estaVencido();
    
    return GestureDetector(
      onTap: () async {
        final resultado = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalleTrabajoPropio(trabajo: trabajo),
          ),
        );
        
        if (resultado == true) {
          onDeleted?.call();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: vencido ? const Color.fromARGB(255, 98, 98, 98) : const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 95, 49, 49).withOpacity(vencido ? 0.5 : 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ IMAGEN - PRIORIZA FOTO PRINCIPAL
            _buildImageSection(vencido),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + Estado
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trabajo.titulo,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: vencido ? const Color.fromARGB(255, 0, 0, 0) : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getEstadoColor(trabajo.estadoPublicacion).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getEstadoColor(trabajo.estadoPublicacion).withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          _getEstadoLabel(trabajo.estadoPublicacion),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getEstadoColor(trabajo.estadoPublicacion),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Rubro 
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 20,
                        color: vencido ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 161, 0, 0),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        trabajo.nombreRubro ?? 'Sin categoría',
                        style: TextStyle(
                          fontSize: 17,
                          color: vencido ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 197, 0, 0),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Descripción
                  Text(
                    trabajo.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      height: 2,
                      color: vencido ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Fechas
                  _buildInfoRow(
                    Icons.calendar_today,
                    _formatDateRange(trabajo.fechaInicio, trabajo.fechaFin),
                    vencido,
                  ),

                  if (trabajo.horarioInicio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.access_time,
                      '${trabajo.horarioInicio} - ${trabajo.horarioFin}',
                      vencido,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Ubicación
                  _buildInfoRow(
                    Icons.location_on,
                    trabajo.direccionCompleta ?? 'Ubicación no especificada',
                    vencido,
                  ),

                  const SizedBox(height: 16),

                  // Salario
                  Row(
                    children: [
                      Icon(
                        Icons.payments,
                        size: 20,
                        color: vencido ? const Color.fromARGB(255, 57, 57, 57) : Colors.green[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trabajo.salario != null
                            ? '\$${trabajo.salario!.toStringAsFixed(0)} ${_getPeriodoLabel(trabajo.periodoPago)}'
                            : 'A convenir',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: vencido ? const Color.fromARGB(255, 0, 0, 0) : Colors.green[700],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final resultado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetalleTrabajoPropio(trabajo: trabajo),
                              ),
                            );
                            if (resultado == true) onDeleted?.call();
                          },
                          icon: const Icon(Icons.visibility, size: 22),
                          label: const Text('Ver Detalle'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: vencido ? const Color.fromARGB(255, 0, 0, 0) : const Color(0xFFC5414B),
                            side: BorderSide(
                              color: vencido ? const Color.fromARGB(255, 255, 255, 255) : const Color(0xFFC5414B),
                            ),
                          ),
                        ),
                      ),
                      if (!vencido) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Editar próximamente')),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 20),
                          color: const Color(0xFFC5414B),
                        ),
                        IconButton(
                          onPressed: () => _confirmarEliminar(context),
                          icon: const Icon(Icons.delete, size: 20),
                          color: Colors.red,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NUEVO MÉTODO: Construir sección de imagen (prioriza foto principal)
  Widget _buildImageSection(bool vencido) {
    final imageUrl = trabajo.fotoPrincipalUrl ?? trabajo.imagenUrl;
    
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.network(
          imageUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 180,
              width: double.infinity,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('⚠️ Error cargando imagen: $error');
            return _buildImagePlaceholder(vencido);
          },
        ),
      );
    }
    
    return _buildImagePlaceholder(vencido);
  }

  Widget _buildImagePlaceholder(bool vencido) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: vencido ? const Color.fromARGB(255, 191, 191, 191) : const Color.fromARGB(255, 255, 129, 129),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: vencido ? Colors.grey[600] : const Color.fromARGB(255, 85, 0, 0),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool vencido) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: vencido ? const Color.fromARGB(255, 255, 255, 255) : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: vencido ? const Color.fromARGB(255, 204, 204, 204) : Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}