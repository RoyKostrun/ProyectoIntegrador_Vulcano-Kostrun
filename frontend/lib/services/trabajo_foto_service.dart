// lib/services/trabajo_foto_service.dart
// ✅ Servicio para manejar fotos de trabajos

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trabajo_foto_model.dart';

class TrabajoFotoService {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  
  // Getter para acceso interno
  SupabaseClient get supabase => _supabase;

  // Constantes
  static const int MAX_FOTOS = 5;
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
      if (kIsWeb) {
        final image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        return image != null ? [image] : [];
      }

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
  Future<String> subirFoto(int idTrabajo, XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final userId = _supabase.auth.currentUser!.id; // ✅ CAMBIADO A _supabase
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'trabajo_$idTrabajo/$fileName';

      print('📤 Subiendo archivo a: $filePath');

      await _supabase.storage.from(BUCKET).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
            ),
          );

      final publicUrl = _supabase.storage.from(BUCKET).getPublicUrl(filePath);

      print('📸 URL pública generada: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('❌ Error subiendo foto: $e');
      throw Exception('Error al subir foto: $e');
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
      final fotosExistentes = await obtenerFotosTrabajo(idTrabajo);
      final cantidadExistente = fotosExistentes.length;

      if (cantidadExistente + imageFiles.length > MAX_FOTOS) {
        throw Exception(
            'Máximo $MAX_FOTOS fotos. Ya tienes $cantidadExistente, '
            'puedes agregar ${MAX_FOTOS - cantidadExistente} más.');
      }

      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];

        final fotoUrl = await subirFoto(idTrabajo, imageFile);

        final orden = cantidadExistente + i;
        final esPrincipal = primeraEsPrincipal && i == 0 && cantidadExistente == 0;

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
      await _supabase
          .from('trabajo_foto')
          .update({'es_principal': false})
          .eq('id_trabajo', idTrabajo);

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
      final uri = Uri.parse(fotoUrl);
      final path = uri.pathSegments.sublist(3).join('/');

      await _supabase.storage.from(BUCKET).remove([path]);

      await _supabase.from('trabajo_foto').delete().eq('id_foto', idFoto);

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