import 'package:flutter/material.dart';
import '../../models/trabajo_model.dart';
import '../../services/trabajo_service.dart';

class NavegadorTrabajosScreen extends StatefulWidget {
  const NavegadorTrabajosScreen({Key? key}) : super(key: key);

  @override
  State<NavegadorTrabajosScreen> createState() => _NavegadorTrabajosScreenState();
}

class _NavegadorTrabajosScreenState extends State<NavegadorTrabajosScreen> {
  final servicio = TrabajoService();
  List<TrabajoModel> trabajos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarTrabajos();
  }

  Future<void> _cargarTrabajos() async {
    try {
      trabajos = await servicio.getTrabajos(from: 0, to: 19);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar trabajos: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trabajos Disponibles')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: trabajos.length,
              itemBuilder: (context, index) {
                final trabajo = trabajos[index];
                return ListTile(
                  title: Text(trabajo.titulo),
                  subtitle: Text(trabajo.descripcion),
                  trailing: Text('\$${trabajo.salario ?? 0}'),
                  onTap: () {
                    // navegación a detalle futuro
                  },
                );
              },
            ),
    );
  }
}
