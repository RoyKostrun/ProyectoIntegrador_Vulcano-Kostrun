// lib/screen/user/ubicacion_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UbicacionesScreen extends StatefulWidget {
  const UbicacionesScreen({Key? key}) : super(key: key);

  @override
  State<UbicacionesScreen> createState() => _UbicacionesScreenState();
}

class _UbicacionesScreenState extends State<UbicacionesScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> ubicaciones = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUbicaciones();
  }

  Future<void> _cargarUbicaciones() async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) throw Exception('Usuario no autenticado');

      // Buscar id_usuario en tu tabla usuario
      final usuarioDb = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', authUser.email!)
          .maybeSingle();

      if (usuarioDb == null) {
        throw Exception('No se encontró el usuario en la tabla usuario');
      }

      final int idUsuario = usuarioDb['id_usuario'];

      final response = await supabase
          .from('ubicacion')
          .select()
          .eq('id_usuario', idUsuario);

      setState(() {
        ubicaciones = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('❌ Error al cargar ubicaciones: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar ubicaciones: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        title: const Text(
          'Mis Ubicaciones',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ubicaciones.isEmpty
              ? const Center(child: Text("No tienes ubicaciones registradas"))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: ubicaciones.length,
                  itemBuilder: (context, index) {
                    final u = ubicaciones[index];
                    return _buildUbicacionCard(u);
                  },
                ),
    );
  }

  Widget _buildUbicacionCard(Map<String, dynamic> ubicacion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Icon(Icons.location_on, color: const Color(0xFFC5414B), size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ubicacion['nombre'] ?? 'Ubicación sin nombre',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${ubicacion['calle'] ?? ''} ${ubicacion['numero'] ?? ''}, ${ubicacion['barrio'] ?? ''}, ${ubicacion['ciudad'] ?? ''}, ${ubicacion['provincia'] ?? ''}",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
