// lib/screens/user/editar_nombre_screen.dart
// ✅ Editar nombre de perfil

import 'package:flutter/material.dart';
import '../../../services/user_service.dart';
import '../../../services/auth_service.dart';

class EditarNombreScreen extends StatefulWidget {
  const EditarNombreScreen({Key? key}) : super(key: key);

  @override
  State<EditarNombreScreen> createState() => _EditarNombreScreenState();
}

class _EditarNombreScreenState extends State<EditarNombreScreen> {
  final UserService _userService = UserService();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _esPersona = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final usuario = await _userService.obtenerUsuarioActual();
      
      if (mounted && usuario != null) {
        setState(() {
          _esPersona = usuario.isPersona;
          
          if (usuario.isPersona && usuario.persona != null) {
            _nombreController.text = usuario.persona!.nombre;
            _apellidoController.text = usuario.persona!.apellido;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _guardar() async {
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre no puede estar vacío'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_esPersona && _apellidoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El apellido no puede estar vacío'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) throw 'Usuario no autenticado';

      if (_esPersona) {
        await _userService.actualizarPersona(
          userData.idUsuario,
          {
            'nombre': _nombreController.text.trim(),
            'apellido': _apellidoController.text.trim(),
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nombre actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 176, 181),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        title: const Text(
          'Editar Nombre',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton(
              onPressed: _guardar,
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              hintText: 'Ingresa tu nombre',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        if (_esPersona)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _apellidoController,
                              decoration: const InputDecoration(
                                labelText: 'Apellido',
                                hintText: 'Ingresa tu apellido',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Este nombre se mostrará en tu perfil público',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}