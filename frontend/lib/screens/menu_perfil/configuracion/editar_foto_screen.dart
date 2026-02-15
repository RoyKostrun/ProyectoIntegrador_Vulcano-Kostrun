// lib/screens/user/menu_perfil/configuracion/editar_foto_screen.dart
// ✅ FUNCIONAL - Editar foto de perfil (Persona y Empresa)

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/menu_perfil/foto_service.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';

class EditarFotoScreen extends StatefulWidget {
  const EditarFotoScreen({Key? key}) : super(key: key);

  @override
  State<EditarFotoScreen> createState() => _EditarFotoScreenState();
}

class _EditarFotoScreenState extends State<EditarFotoScreen> {
  final FotoService _fotoService = FotoService();
  final UserService _userService = UserService();
  
  String? _fotoUrlActual;
  User? _usuario;
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
      
      if (mounted && usuario != null) {
        String? fotoUrl;
        
        // Obtener URL según tipo de usuario
        if (usuario.isPersona && usuario.persona != null) {
          fotoUrl = usuario.persona!.fotoPerfilUrl;
        } else if (usuario.isEmpresa && usuario.empresa != null) {
          fotoUrl = usuario.empresa!.logoUrl;
        }
        
        setState(() {
          _usuario = usuario;
          _fotoUrlActual = fotoUrl;
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

  String get _tituloFoto {
    if (_usuario == null) return 'Foto de Perfil';
    return _usuario!.isEmpresa ? 'Logo de la Empresa' : 'Foto de Perfil';
  }

  String get _textoBotonCambiar {
    if (_usuario == null) return 'Agregar foto';
    final tieneImagen = _fotoUrlActual != null && _fotoUrlActual!.isNotEmpty;
    if (_usuario!.isEmpresa) {
      return tieneImagen ? 'Cambiar logo' : 'Agregar logo';
    }
    return tieneImagen ? 'Cambiar foto' : 'Agregar foto';
  }

  String get _textoBotonEliminar {
    if (_usuario == null) return 'Eliminar';
    return _usuario!.isEmpresa ? 'Eliminar logo' : 'Eliminar foto';
  }

  String get _mensajeConfirmacion {
    if (_usuario == null) return '¿Estás seguro de que deseas eliminar la imagen?';
    return _usuario!.isEmpresa 
        ? '¿Estás seguro de que deseas eliminar el logo de tu empresa?'
        : '¿Estás seguro de que deseas eliminar tu foto de perfil?';
  }

  String get _mensajeInfo {
    if (_usuario == null) return 'Tu imagen será visible públicamente en la plataforma.';
    return _usuario!.isEmpresa
        ? 'El logo de tu empresa será visible públicamente en la plataforma.'
        : 'Tu foto de perfil será visible públicamente en la plataforma.';
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
          SnackBar(
            content: Text(
              _usuario!.isEmpresa 
                  ? '✅ Logo actualizado correctamente'
                  : '✅ Foto actualizada correctamente'
            ),
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
            content: Text('Error al cambiar imagen: $e'),
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
        title: Text(_textoBotonEliminar),
        content: Text(_mensajeConfirmacion),
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

      // Actualizar BD con null/empty
      await _fotoService.actualizarFotoPerfilEnBD('');

      if (mounted) {
        setState(() {
          _fotoUrlActual = null;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _usuario!.isEmpresa
                  ? '✅ Logo eliminado correctamente'
                  : '✅ Foto eliminada correctamente'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar imagen: $e'),
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
        title: Text(
          _tituloFoto,
          style: const TextStyle(
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
                  
                  // Foto/Logo actual
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
                                      return Icon(
                                        _usuario?.isEmpresa == true 
                                            ? Icons.business 
                                            : Icons.person,
                                        size: 100,
                                        color: Colors.grey,
                                      );
                                    },
                                  )
                                : Icon(
                                    _usuario?.isEmpresa == true 
                                        ? Icons.business 
                                        : Icons.person,
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

                  // Botón: Cambiar foto/logo
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _cambiarFoto,
                      icon: Icon(
                        _usuario?.isEmpresa == true 
                            ? Icons.add_photo_alternate 
                            : Icons.camera_alt,
                        color: Colors.white,
                      ),
                      label: Text(
                        _textoBotonCambiar,
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

                  // Botón: Eliminar foto/logo (solo si hay imagen)
                  if (_fotoUrlActual != null && _fotoUrlActual!.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _eliminarFoto,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: Text(
                          _textoBotonEliminar,
                          style: const TextStyle(
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
                            _mensajeInfo,
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