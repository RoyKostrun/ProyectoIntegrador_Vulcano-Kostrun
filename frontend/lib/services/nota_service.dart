// lib/services/nota_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nota_model.dart';
import 'auth_service.dart';

class NotaService {
  final _supabase = Supabase.instance.client;

  /// Obtener todas las notas del usuario ordenadas por última modificación
  Future<List<NotaModel>> getNotasUsuario() async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) throw 'Usuario no autenticado';

      final idUsuario = userData.idUsuario;

      final response = await _supabase
          .from('notas_privadas')
          .select()
          .eq('id_usuario', idUsuario)
          .order('fecha_modificacion', ascending: false);

      return (response as List)
          .map((nota) => NotaModel.fromJson(nota))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo notas: $e');
      rethrow;
    }
  }

  /// Obtener una nota específica por ID
  Future<NotaModel?> getNotaPorId(int idNotas) async {
    try {
      final response = await _supabase
          .from('notas_privadas')
          .select()
          .eq('id_notas', idNotas)
          .maybeSingle();

      if (response == null) return null;

      return NotaModel.fromJson(response);
    } catch (e) {
      print('❌ Error obteniendo nota: $e');
      rethrow;
    }
  }

  /// Crear nota del usuario
  Future<NotaModel> crearNota(String titulo, String contenido) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) throw 'Usuario no autenticado';

      final idUsuario = userData.idUsuario;
      final now = DateTime.now();

      final data = {
        'id_usuario': idUsuario,
        'titulo': titulo.isEmpty ? 'Sin título' : titulo,
        'contenido': contenido,
        'fecha_creacion': now.toIso8601String(),
        'fecha_modificacion': now.toIso8601String(),
      };

      final response = await _supabase
          .from('notas_privadas')
          .insert(data)
          .select()
          .single();

      print('✅ Nota creada: ${response['id_notas']}');
      return NotaModel.fromJson(response);
    } catch (e) {
      print('❌ Error creando nota: $e');
      rethrow;
    }
  }

  /// Actualizar nota del usuario
  Future<void> actualizarNota(int idNotas, String titulo, String contenido) async {
    try {
      final now = DateTime.now();

      final data = {
        'titulo': titulo.isEmpty ? 'Sin título' : titulo,
        'contenido': contenido,
        'fecha_modificacion': now.toIso8601String(),
      };

      await _supabase
          .from('notas_privadas')
          .update(data)
          .eq('id_notas', idNotas);

      print('✅ Nota actualizada: $idNotas');
    } catch (e) {
      print('❌ Error actualizando nota: $e');
      rethrow;
    }
  }

  /// Eliminar nota del usuario
  Future<void> eliminarNota(int idNotas) async {
    try {
      await _supabase
          .from('notas_privadas')
          .delete()
          .eq('id_notas', idNotas);

      print('✅ Nota eliminada: $idNotas');
    } catch (e) {
      print('❌ Error eliminando nota: $e');
      rethrow;
    }
  }
}