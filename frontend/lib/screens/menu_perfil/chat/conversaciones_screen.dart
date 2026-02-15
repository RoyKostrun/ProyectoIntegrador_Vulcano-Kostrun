//lib/screens/menu_perfil/chat/conversaciones_screen.dart

import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';
import '../../../models/chat/conversacion_model.dart';

class ConversacionesScreen extends StatefulWidget {
  const ConversacionesScreen({Key? key}) : super(key: key);

  @override
  State<ConversacionesScreen> createState() => _ConversacionesScreenState();
}

class _ConversacionesScreenState extends State<ConversacionesScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {  // ← AGREGADO
  
  final ChatService _chatService = ChatService();
  int? _usuarioId;
  bool _isLoadingUser = true;
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;  // ← AGREGADO: Mantener estado vivo

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarUsuarioActual();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ← AGREGADO: Refrescar cuando vuelves a la pantalla
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _cargarUsuarioActual() async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (mounted) {
        setState(() {
          _usuarioId = userData?.idUsuario;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando usuario: $e');
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  List<Conversacion> _filtrarConversaciones(
      List<Conversacion> conversaciones, String filtro) {
    if (_usuarioId == null) return [];

    switch (filtro) {
      case 'empleador':
        return conversaciones
            .where((c) => c.empleadorId == _usuarioId)
            .toList();
      case 'empleado':
        return conversaciones.where((c) => c.empleadoId == _usuarioId).toList();
      default:
        return conversaciones;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);  // ← IMPORTANTE: Necesario para AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Mensajes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implementar búsqueda
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Como empleador'),
            Tab(text: 'Como empleado'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingUser) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
        ),
      );
    }

    if (_usuarioId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error al cargar usuario'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarUsuarioActual,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<Conversacion>>(
      stream: _chatService.streamConversaciones(_usuarioId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final todasConversaciones = snapshot.data ?? [];

        return TabBarView(
          controller: _tabController,
          children: [
            _buildListaConversaciones(todasConversaciones, 'empleador'),
            _buildListaConversaciones(todasConversaciones, 'empleado'),
          ],
        );
      },
    );
  }

  Widget _buildListaConversaciones(
      List<Conversacion> conversaciones, String filtro) {
    final conversacionesFiltradas =
        _filtrarConversaciones(conversaciones, filtro);

    if (conversacionesFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay conversaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filtro == 'empleador'
                  ? 'Acepta postulaciones para empezar a chatear'
                  : 'Postúlate a trabajos para empezar a chatear',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFC5414B),
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: conversacionesFiltradas.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[200],
        ),
        itemBuilder: (context, index) {
          return _ConversacionItem(
            conversacion: conversacionesFiltradas[index],
            usuarioId: _usuarioId!,
            onTap: () async {  // ← AGREGADO: async
              await Navigator.pushNamed(  // ← AGREGADO: await
                context,
                '/chat',
                arguments: {
                  'conversacion': conversacionesFiltradas[index],
                  'usuarioId': _usuarioId!,
                },
              );
              
              // ← AGREGADO: Refrescar al volver del chat
              if (mounted) {
                setState(() {});
              }
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// RESTO DEL CÓDIGO SIN CAMBIOS
// ============================================================

class _ConversacionItem extends StatelessWidget {
  final Conversacion conversacion;
  final int usuarioId;
  final VoidCallback onTap;

  const _ConversacionItem({
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                height: 64,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (conversacion.fotoTrabajo != null)
                      Positioned(
                        left: 0,
                        top: 5,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              conversacion.fotoTrabajo!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.work,
                                    size: 24,
                                    color: Colors.grey[500],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    Positioned(
                      left: 30,
                      top: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor:
                                  const Color(0xFFC5414B).withOpacity(0.1),
                              backgroundImage: fotoOtro != null
                                  ? NetworkImage(fotoOtro)
                                  : null,
                              child: fotoOtro == null
                                  ? Text(
                                      nombreOtro[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFC5414B),
                                      ),
                                    )
                                  : null,
                            ),

                            if (noLeidos > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC5414B),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  child: Center(
                                    child: Text(
                                      noLeidos > 99 ? '99+' : '$noLeidos',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: nombreOtro,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: noLeidos > 0
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (conversacion.tituloTrabajo != null) ...[
                            TextSpan(
                              text: ' - ',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            TextSpan(
                              text: conversacion.tituloTrabajo!,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    if (conversacion.timestampUltimoMensaje != null)
                      Text(
                        _formatearFecha(conversacion.timestampUltimoMensaje!),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.normal,
                        ),
                      ),

                    const SizedBox(height: 6),

                    Text(
                      conversacion.ultimoMensaje ?? 'No hay mensajes aún',
                      style: TextStyle(
                        fontSize: 15,
                        color: noLeidos > 0 ? Colors.black87 : Colors.grey[600],
                        fontWeight:
                            noLeidos > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatearFecha(DateTime timestamp) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(timestamp);

    if (diferencia.inDays == 0) {
      return 'Hoy ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return dias[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}