// lib/screens/user/menu_perfil/configuracion/editar_foto_screen.dart
// ✅ FUNCIONAL - Editar foto de perfil

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../services/foto_service.dart';
import '../../../../services/user_service.dart';

class EditarFotoScreen extends StatefulWidget {
  const EditarFotoScreen({Key? key}) : super(key: key);

  @override
  State<EditarFotoScreen> createState() => _EditarFotoScreenState();
}

class _EditarFotoScreenState extends State<EditarFotoScreen> {
  final FotoService _fotoService = FotoService();
  final UserService _userService = UserService();
  
  String? _fotoUrlActual;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _cargarFotoActual();
  }

  Future<void> _cargarFotoActual() async {
    setState(() => _isLoading = true);

    try {
      final usuario = await _userService.obtenerUsuarioActual();
      
      if (mounted && usuario != null && usuario.isPersona) {
        setState(() {
          _fotoUrlActual = usuario.persona?.fotoPerfil;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cambiarFoto() async {
    // Mostrar opciones: Galería o Cámara
    final source = await FotoService.mostrarOpcionesSeleccion(context);
    if (source == null) return;

    setState(() => _isUploading = true);

    try {
      final nuevaUrl = await _fotoService.cambiarFotoPerfil(
        source: source,
        fotoUrlAnterior: _fotoUrlActual,
      );

      if (nuevaUrl != null && mounted) {
        setState(() {
          _fotoUrlActual = nuevaUrl;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Notificar a la pantalla anterior que hubo cambios
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarFoto() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Estás seguro de que deseas eliminar tu foto de perfil?'),
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

    if (confirmar != true) return;

    setState(() => _isUploading = true);

    try {
      // Eliminar foto anterior
      if (_fotoUrlActual != null) {
        await _fotoService.eliminarFotoAnterior(_fotoUrlActual);
      }

      // Actualizar BD con null
      await _fotoService.actualizarFotoPerfilEnBD('');

      if (mounted) {
        setState(() {
          _fotoUrlActual = null;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar foto: $e'),
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
          'Foto de Perfil',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Foto actual
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _fotoUrlActual != null && _fotoUrlActual!.isNotEmpty
                                ? Image.network(
                                    _fotoUrlActual!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFFC5414B),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 100,
                                        color: Colors.grey,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        if (_isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Botón: Cambiar foto
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _cambiarFoto,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: Text(
                        _fotoUrlActual != null ? 'Cambiar foto' : 'Agregar foto',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC5414B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botón: Eliminar foto (solo si hay foto)
                  if (_fotoUrlActual != null && _fotoUrlActual!.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _eliminarFoto,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text(
                          'Eliminar foto',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Información
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
                            'Tu foto de perfil será visible públicamente en la plataforma.',
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