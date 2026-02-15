// lib/services/foto_service.dart
// ✅ Servicio para manejar fotos de perfil (Persona y Empresa)

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth_service.dart';

class FotoService {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // ==============================================================
  // 🔹 SELECCIONAR FOTO (GALERÍA O CÁMARA)
  // ==============================================================
  Future<XFile?> seleccionarFoto({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        print('⚠️ Usuario canceló la selección');
      } else {
        print('✅ Imagen seleccionada: ${image.path}');
      }

      return image;
    } on Exception catch (e) {
      // Errores específicos de la cámara
      final errorMsg = e.toString().toLowerCase();
      
      if (errorMsg.contains('camera') || errorMsg.contains('permission')) {
        print('❌ Error de permisos de cámara: $e');
        throw Exception('No se puede acceder a la cámara. Verifica los permisos en Configuración.');
      } else if (errorMsg.contains('denied')) {
        print('❌ Permiso denegado: $e');
        throw Exception('Permiso denegado. Ve a Configuración y habilita el acceso a la cámara/galería.');
      } else {
        print('❌ Error al seleccionar imagen: $e');
        throw Exception('Error al acceder a la cámara/galería.');
      }
    } catch (e) {
      print('❌ Error inesperado al seleccionar imagen: $e');
      return null;
    }
  }

  // ==============================================================
  // 🔹 SUBIR FOTO DE PERFIL A SUPABASE STORAGE
  // ==============================================================
  Future<String?> subirFotoPerfil(XFile imageFile) async {
    try {
      // Obtener auth user (UUID de Supabase)
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Generar nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = '${authUser.id}/$timestamp.$extension';

      print('📤 Subiendo foto: $fileName');

      // Subir archivo según la plataforma
      if (kIsWeb) {
        // Web: usar bytes
        final bytes = await imageFile.readAsBytes();
        await _supabase.storage
            .from('perfil-fotos')
            .uploadBinary(fileName, bytes);
      } else {
        // Mobile: usar File
        final file = File(imageFile.path);
        await _supabase.storage
            .from('perfil-fotos')
            .upload(fileName, file);
      }

      // Obtener URL pública
      final publicUrl = _supabase.storage
          .from('perfil-fotos')
          .getPublicUrl(fileName);

      print('✅ Foto subida exitosamente: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error al subir foto: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 ACTUALIZAR URL DE FOTO EN BASE DE DATOS (UNIVERSAL)
  // ==============================================================
  Future<void> actualizarFotoPerfilEnBD(String fotoUrl) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) {
        throw Exception('Usuario no autenticado');
      }

      // Determinar si es persona o empresa
      if (userData.tipoUsuario == 'PERSONA') {
        await _supabase
            .from('usuario_persona')
            .update({
              'foto_perfil_url': fotoUrl,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id_usuario', userData.idUsuario);
        print('✅ URL de foto actualizada en usuario_persona');
      } else if (userData.tipoUsuario == 'EMPRESA') {
        await _supabase
            .from('usuario_empresa')
            .update({
              'logo_url': fotoUrl,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id_usuario', userData.idUsuario);
        print('✅ URL de logo actualizada en usuario_empresa');
      }
    } catch (e) {
      print('❌ Error al actualizar URL en BD: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 ELIMINAR FOTO ANTERIOR (LIMPIEZA)
  // ==============================================================
  Future<void> eliminarFotoAnterior(String? fotoUrlAnterior) async {
    if (fotoUrlAnterior == null || fotoUrlAnterior.isEmpty) return;

    try {
      // Extraer path del archivo de la URL
      final uri = Uri.parse(fotoUrlAnterior);
      final path = uri.pathSegments.sublist(3).join('/'); // Quitar /storage/v1/object/public/perfil-fotos/

      await _supabase.storage
          .from('perfil-fotos')
          .remove([path]);

      print('✅ Foto anterior eliminada: $path');
    } catch (e) {
      print('⚠️ Error al eliminar foto anterior: $e');
      // No lanzar error, es solo limpieza
    }
  }

  // ==============================================================
  // 🔹 PROCESO COMPLETO: SELECCIONAR Y SUBIR FOTO
  // ==============================================================
  Future<String?> cambiarFotoPerfil({
    required ImageSource source,
    String? fotoUrlAnterior,
  }) async {
    try {
      // 1. Seleccionar imagen
      final imageFile = await seleccionarFoto(source: source);
      if (imageFile == null) {
        print('⚠️ No se seleccionó ninguna imagen');
        return null;
      }

      // 2. Subir nueva foto
      final nuevaUrl = await subirFotoPerfil(imageFile);
      if (nuevaUrl == null) {
        throw Exception('Error al subir la foto');
      }

      // 3. Actualizar BD (detecta automáticamente si es persona o empresa)
      await actualizarFotoPerfilEnBD(nuevaUrl);

      // 4. Eliminar foto anterior (limpieza)
      if (fotoUrlAnterior != null) {
        await eliminarFotoAnterior(fotoUrlAnterior);
      }

      return nuevaUrl;
    } catch (e) {
      print('❌ Error en cambiarFotoPerfil: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 MOSTRAR DIÁLOGO DE SELECCIÓN (GALERÍA O CÁMARA)
  // ==============================================================
  static Future<ImageSource?> mostrarOpcionesSeleccion(context) async {
    // ✅ En web, la cámara no funciona bien, abrir galería directamente
    if (kIsWeb) {
      return ImageSource.gallery;
    }
    
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar foto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFC5414B)),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFC5414B)),
                title: const Text('Cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}