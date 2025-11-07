import 'package:flutter/material.dart';
import '../../services/ubicacion_service.dart';

class UbicacionesScreen extends StatefulWidget {
  const UbicacionesScreen({Key? key}) : super(key: key);

  @override
  State<UbicacionesScreen> createState() => _UbicacionesScreenState();
}

class _UbicacionesScreenState extends State<UbicacionesScreen> {
  final _ubicacionService = UbicacionService();
  List<Map<String, dynamic>> ubicaciones = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUbicaciones();
  }

  Future<void> _cargarUbicaciones() async {
    try {
      final data = await _ubicacionService.getUbicacionesDelUsuario();
      setState(() {
        ubicaciones = data;
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

      // ✅ Botón flotante para agregar nueva ubicación
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFC5414B),
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/crear-ubicacion');
          if (result == true) {
            _cargarUbicaciones(); // recargar después de crear
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ubicaciones.isEmpty
              ? const Center(
                  child: Text(
                    "No tienes ubicaciones registradas",
                    style: TextStyle(fontSize: 16),
                  ),
                )
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
          const Icon(Icons.location_on, color: Color(0xFFC5414B), size: 30),
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
                  "${ubicacion['calle'] ?? ''} ${ubicacion['numero'] ?? ''}, "
                  "${ubicacion['barrio'] ?? ''}, "
                  "${ubicacion['ciudad'] ?? ''}, "
                  "${ubicacion['provincia'] ?? ''}",
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
