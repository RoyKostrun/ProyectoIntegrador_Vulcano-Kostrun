// lib/services/trabajo_foto_service.dart
// ✅ Servicio para manejar fotos de trabajos

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trabajo_foto_model.dart';

class TrabajoFotoService {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Constantes
  static const int MAX_FOTOS = 5; // 1 principal + 4 secundarias
  static const String BUCKET = 'trabajo-fotos';

  // ==============================================================
  // 🔹 OBTENER FOTOS DE UN TRABAJO
  // ==============================================================
  Future<List<TrabajoFoto>> obtenerFotosTrabajo(int idTrabajo) async {
    try {
      final response = await _supabase
          .from('trabajo_foto')
          .select()
          .eq('id_trabajo', idTrabajo)
          .order('orden', ascending: true);

      if (response == null || response.isEmpty) {
        return [];
      }

      return (response as List)
          .map((foto) => TrabajoFoto.fromJson(foto))
          .toList();
    } catch (e) {
      print('❌ Error al obtener fotos: $e');
      return [];
    }
  }

  // ==============================================================
  // 🔹 SELECCIONAR MÚLTIPLES FOTOS
  // ==============================================================
  Future<List<XFile>> seleccionarMultiplesfotos() async {
    try {
      // En web, usar galería simple
      if (kIsWeb) {
        final image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        return image != null ? [image] : [];
      }

      // En móvil, permitir selección múltiple
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      print('✅ Seleccionadas ${images.length} fotos');
      return images;
    } catch (e) {
      print('❌ Error al seleccionar fotos: $e');
      return [];
    }
  }

  // ==============================================================
  // 🔹 SUBIR UNA FOTO A STORAGE
  // ==============================================================
  Future<String?> subirFoto(int idTrabajo, XFile imageFile) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Generar nombre único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'trabajo_${idTrabajo}/${authUser.id}_$timestamp.$extension';

      print('📤 Subiendo foto: $fileName');

      // Subir según plataforma
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        await _supabase.storage
            .from(BUCKET)
            .uploadBinary(fileName, bytes);
      } else {
        final file = File(imageFile.path);
        await _supabase.storage
            .from(BUCKET)
            .upload(fileName, file);
      }

      // Obtener URL pública
      final publicUrl = _supabase.storage
          .from(BUCKET)
          .getPublicUrl(fileName);

      print('✅ Foto subida: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error al subir foto: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 AGREGAR FOTO A LA BASE DE DATOS
  // ==============================================================
  Future<TrabajoFoto?> agregarFoto({
    required int idTrabajo,
    required String fotoUrl,
    required int orden,
    required bool esPrincipal,
  }) async {
    try {
      final data = {
        'id_trabajo': idTrabajo,
        'foto_url': fotoUrl,
        'orden': orden,
        'es_principal': esPrincipal,
      };

      final response = await _supabase
          .from('trabajo_foto')
          .insert(data)
          .select()
          .single();

      print('✅ Foto agregada a BD');
      return TrabajoFoto.fromJson(response);
    } catch (e) {
      print('❌ Error al agregar foto a BD: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 SUBIR FOTOS MÚLTIPLES (PROCESO COMPLETO)
  // ==============================================================
  Future<List<TrabajoFoto>> subirFotosMultiples({
    required int idTrabajo,
    required List<XFile> imageFiles,
    required bool primeraEsPrincipal,
  }) async {
    final List<TrabajoFoto> fotosSubidas = [];

    try {
      // Obtener fotos existentes
      final fotosExistentes = await obtenerFotosTrabajo(idTrabajo);
      final cantidadExistente = fotosExistentes.length;

      // Validar límite
      if (cantidadExistente + imageFiles.length > MAX_FOTOS) {
        throw Exception(
          'Máximo $MAX_FOTOS fotos. Ya tienes $cantidadExistente, '
          'puedes agregar ${MAX_FOTOS - cantidadExistente} más.'
        );
      }

      // Subir cada foto
      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        
        // Subir a Storage
        final fotoUrl = await subirFoto(idTrabajo, imageFile);
        if (fotoUrl == null) continue;

        // Determinar orden y si es principal
        final orden = cantidadExistente + i;
        final esPrincipal = primeraEsPrincipal && i == 0 && cantidadExistente == 0;

        // Guardar en BD
        final foto = await agregarFoto(
          idTrabajo: idTrabajo,
          fotoUrl: fotoUrl,
          orden: orden,
          esPrincipal: esPrincipal,
        );

        if (foto != null) {
          fotosSubidas.add(foto);
        }
      }

      print('✅ Subidas ${fotosSubidas.length} fotos');
      return fotosSubidas;
    } catch (e) {
      print('❌ Error al subir fotos múltiples: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 ESTABLECER FOTO PRINCIPAL
  // ==============================================================
  Future<void> establecerFotoPrincipal(int idFoto, int idTrabajo) async {
    try {
      // Quitar principal de otras fotos
      await _supabase
          .from('trabajo_foto')
          .update({'es_principal': false})
          .eq('id_trabajo', idTrabajo);

      // Establecer nueva principal
      await _supabase
          .from('trabajo_foto')
          .update({'es_principal': true})
          .eq('id_foto', idFoto);

      print('✅ Foto principal actualizada');
    } catch (e) {
      print('❌ Error al establecer foto principal: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 ELIMINAR FOTO
  // ==============================================================
  Future<void> eliminarFoto(int idFoto, String fotoUrl) async {
    try {
      // Eliminar de Storage
      final uri = Uri.parse(fotoUrl);
      final path = uri.pathSegments.sublist(3).join('/');
      
      await _supabase.storage
          .from(BUCKET)
          .remove([path]);

      // Eliminar de BD
      await _supabase
          .from('trabajo_foto')
          .delete()
          .eq('id_foto', idFoto);

      print('✅ Foto eliminada');
    } catch (e) {
      print('❌ Error al eliminar foto: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 OBTENER FOTO PRINCIPAL
  // ==============================================================
  Future<TrabajoFoto?> obtenerFotoPrincipal(int idTrabajo) async {
    try {
      final response = await _supabase
          .from('trabajo_foto')
          .select()
          .eq('id_trabajo', idTrabajo)
          .eq('es_principal', true)
          .maybeSingle();

      if (response == null) return null;

      return TrabajoFoto.fromJson(response);
    } catch (e) {
      print('❌ Error al obtener foto principal: $e');
      return null;
    }
  }
}