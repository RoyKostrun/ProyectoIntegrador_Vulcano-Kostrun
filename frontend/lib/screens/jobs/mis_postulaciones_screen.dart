// lib/screens/jobs/mis_postulaciones_screen.dart
// Pantalla para que el EMPLEADO vea sus propias postulaciones

import 'package:flutter/material.dart';
import '../../services/postulacion_service.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../models/postulacion_model.dart';

class MisPostulacionesScreen extends StatefulWidget {
  const MisPostulacionesScreen({Key? key}) : super(key: key);

  @override
  State<MisPostulacionesScreen> createState() => _MisPostulacionesScreenState();
}

class _MisPostulacionesScreenState extends State<MisPostulacionesScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService();
  List<PostulacionModel> _todasPostulaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarPostulaciones();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarPostulaciones() async {
    setState(() => _isLoading = true);
    try {
      final postulaciones = await PostulacionService.getMisPostulaciones();
      setState(() {
        _todasPostulaciones = postulaciones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<PostulacionModel> _filtrarPorEstado(String? estado) {
    if (estado == null) return _todasPostulaciones;
    return _todasPostulaciones
        .where((p) => p.estado.toUpperCase() == estado.toUpperCase())
        .toList();
  }

  int _contarPorEstado(String estado) {
    return _todasPostulaciones
        .where((p) => p.estado.toUpperCase() == estado.toUpperCase())
        .length;
  }

  Future<void> _abrirChat(PostulacionModel postulacion) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFC5414B)),
        ),
      );

      final userData = await AuthService.getCurrentUserData();
      if (userData == null) throw Exception('Usuario no autenticado');

      final conversacion = await _chatService.obtenerOCrearConversacion(postulacion.id);

      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'conversacion': conversacion,
            'usuarioId': userData.idUsuario,
          },
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        title: const Text('Mis Postulaciones', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarPostulaciones,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Todas (${_todasPostulaciones.length})'),
            Tab(text: 'Pendientes (${_contarPorEstado('PENDIENTE')})'),
            Tab(text: 'Aceptadas (${_contarPorEstado('ACEPTADO')})'),
            Tab(text: 'Rechazadas (${_contarPorEstado('RECHAZADO')})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC5414B)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLista(_filtrarPorEstado(null)),
                _buildLista(_filtrarPorEstado('PENDIENTE')),
                _buildLista(_filtrarPorEstado('ACEPTADO')),
                _buildLista(_filtrarPorEstado('RECHAZADO')),
              ],
            ),
    );
  }

  Widget _buildLista(List<PostulacionModel> postulaciones) {
    if (postulaciones.isEmpty) {
      return Center(
        child: Text('No hay postulaciones', style: TextStyle(color: Colors.grey[600])),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: postulaciones.length,
      itemBuilder: (context, index) => _buildCard(postulaciones[index]),
    );
  }

  Widget _buildCard(PostulacionModel postulacion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    postulacion.trabajo?.titulo ?? 'Trabajo',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(postulacion.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    postulacion.getEstadoLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getEstadoColor(postulacion.estado),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // ✅ BOTÓN DE CHAT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _abrirChat(postulacion),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chatear con empleador'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5414B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE': return Colors.orange;
      case 'ACEPTADO': return Colors.green;
      case 'RECHAZADO': return Colors.red;
      default: return Colors.grey;
    }
  }
}