// lib/screens/jobs/gestionar_fotos_trabajo_screen.dart
// ✅ Gestionar fotos de un trabajo (máximo 5)

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/trabajo_foto_model.dart';
import '../../services/trabajo_foto_service.dart';

class GestionarFotosTrabajoScreen extends StatefulWidget {
  final int idTrabajo;

  const GestionarFotosTrabajoScreen({
    Key? key,
    required this.idTrabajo,
  }) : super(key: key);

  @override
  State<GestionarFotosTrabajoScreen> createState() =>
      _GestionarFotosTrabajoScreenState();
}

class _GestionarFotosTrabajoScreenState
    extends State<GestionarFotosTrabajoScreen> {
  final TrabajoFotoService _fotoService = TrabajoFotoService();

  List<TrabajoFoto> _fotos = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _cargarFotos();
  }

  Future<void> _cargarFotos() async {
    setState(() => _isLoading = true);

    try {
      final fotos = await _fotoService.obtenerFotosTrabajo(widget.idTrabajo);
      
      if (mounted) {
        setState(() {
          _fotos = fotos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Error al cargar fotos: $e');
      }
    }
  }

  Future<void> _agregarFotos() async {
    if (_fotos.length >= TrabajoFotoService.MAX_FOTOS) {
      _mostrarError('Máximo ${TrabajoFotoService.MAX_FOTOS} fotos permitidas');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Seleccionar fotos
      final imageFiles = await _fotoService.seleccionarMultiplesfotos();
      
      if (imageFiles.isEmpty) {
        setState(() => _isUploading = false);
        return;
      }

      // Validar cantidad
      final espacioDisponible = TrabajoFotoService.MAX_FOTOS - _fotos.length;
      if (imageFiles.length > espacioDisponible) {
        _mostrarError(
          'Solo puedes agregar $espacioDisponible foto(s) más. '
          'Seleccionaste ${imageFiles.length}.'
        );
        setState(() => _isUploading = false);
        return;
      }

      // Subir fotos
      final nuevasFotos = await _fotoService.subirFotosMultiples(
        idTrabajo: widget.idTrabajo,
        imageFiles: imageFiles,
        primeraEsPrincipal: _fotos.isEmpty, // Primera foto es principal si no hay ninguna
      );

      if (mounted) {
        setState(() {
          _fotos.addAll(nuevasFotos);
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${nuevasFotos.length} foto(s) agregada(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _mostrarError('Error al subir fotos: $e');
      }
    }
  }

  Future<void> _establecerPrincipal(int idFoto) async {
    try {
      await _fotoService.establecerFotoPrincipal(idFoto, widget.idTrabajo);
      await _cargarFotos(); // Recargar

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto principal actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al cambiar foto principal: $e');
    }
  }

  Future<void> _eliminarFoto(TrabajoFoto foto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Estás seguro de eliminar esta foto?'),
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

    try {
      await _fotoService.eliminarFoto(foto.idFoto, foto.fotoUrl);
      await _cargarFotos(); // Recargar

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto eliminada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al eliminar foto: $e');
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
        ),
      );
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
          'Fotos del Trabajo',
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contador
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fotos agregadas:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_fotos.length}/${TrabajoFotoService.MAX_FOTOS}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _fotos.length >= TrabajoFotoService.MAX_FOTOS
                                ? Colors.red
                                : const Color(0xFFC5414B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón agregar fotos
                  if (_fotos.length < TrabajoFotoService.MAX_FOTOS)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _agregarFotos,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.add_photo_alternate, color: Colors.white),
                        label: Text(
                          _isUploading ? 'Subiendo...' : 'Agregar Fotos',
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

                  const SizedBox(height: 24),

                  // Grid de fotos
                  if (_fotos.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(
                            Icons.photo_library_outlined,
                            size: 80,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay fotos agregadas',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: _fotos.length,
                      itemBuilder: (context, index) {
                        final foto = _fotos[index];
                        return _buildFotoCard(foto);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFotoCard(TrabajoFoto foto) {
    return Container(
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
      child: Stack(
        children: [
          // Imagen
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              foto.fotoUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.error_outline, color: Colors.red, size: 40),
                );
              },
            ),
          ),

          // Badge "Principal"
          if (foto.esPrincipal)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5414B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PRINCIPAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Botones de acción
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
              ),
              onSelected: (value) {
                if (value == 'principal') {
                  _establecerPrincipal(foto.idFoto);
                } else if (value == 'eliminar') {
                  _eliminarFoto(foto);
                }
              },
              itemBuilder: (context) => [
                if (!foto.esPrincipal)
                  const PopupMenuItem(
                    value: 'principal',
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 20, color: Color(0xFFC5414B)),
                        SizedBox(width: 8),
                        Text('Establecer como principal'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}