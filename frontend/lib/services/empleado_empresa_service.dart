// lib/services/empleado_empresa_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/empleado_empresa_model.dart';
import 'auth_service.dart';

class EmpleadoEmpresaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==============================================================
  // 🔹 OBTENER TODOS LOS EMPLEADOS DE LA EMPRESA ACTUAL
  // ==============================================================
  Future<List<EmpleadoEmpresaModel>> obtenerEmpleados() async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) {
        throw Exception('Usuario no autenticado');
      }

      if (!userData.isEmpresa || userData.empresa == null) {
        throw Exception('Solo las empresas pueden gestionar empleados');
      }

      final response = await _supabase
          .from('empleado_x_empresa')
          .select()
          .eq('id_empresa', userData.empresa!.idEmpresa)
          .eq('activo', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => EmpleadoEmpresaModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error al obtener empleados: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 OBTENER UN EMPLEADO POR ID
  // ==============================================================
  Future<EmpleadoEmpresaModel?> obtenerEmpleadoPorId(int idEmpleado) async {
    try {
      final response = await _supabase
          .from('empleado_x_empresa')
          .select()
          .eq('id_empleado', idEmpleado)
          .single();

      return EmpleadoEmpresaModel.fromJson(response);
    } catch (e) {
      print('❌ Error al obtener empleado: $e');
      return null;
    }
  }

  // ==============================================================
  // 🔹 AGREGAR NUEVO EMPLEADO
  // ==============================================================
  Future<EmpleadoEmpresaModel> agregarEmpleado({
    required String nombre,
    required String apellido,
    String? fotoPerfilUrl,
    String? relacion,
    DateTime? fechaNacimiento,
  }) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) {
        throw Exception('Usuario no autenticado');
      }

      if (!userData.isEmpresa || userData.empresa == null) {
        throw Exception('Solo las empresas pueden agregar empleados');
      }

      final response = await _supabase
          .from('empleado_x_empresa')
          .insert({
            'id_empresa': userData.empresa!.idEmpresa,
            'nombre': nombre,
            'apellido': apellido,
            'foto_de_perfil': fotoPerfilUrl,
            'relacion': relacion,
            'fecha_de_nacimiento': fechaNacimiento?.toIso8601String().split('T')[0],
            'activo': true,
          })
          .select()
          .single();

      print('✅ Empleado agregado exitosamente');
      return EmpleadoEmpresaModel.fromJson(response);
    } catch (e) {
      print('❌ Error al agregar empleado: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 ACTUALIZAR EMPLEADO
  // ==============================================================
  Future<void> actualizarEmpleado({
    required int idEmpleado,
    required String nombre,
    required String apellido,
    String? fotoPerfilUrl,
    String? relacion,
    DateTime? fechaNacimiento,
  }) async {
    try {
      final response = await _supabase
          .from('empleado_x_empresa')
          .update({
            'nombre': nombre,
            'apellido': apellido,
            'foto_de_perfil': fotoPerfilUrl,
            'relacion': relacion,
            'fecha_de_nacimiento': fechaNacimiento?.toIso8601String().split('T')[0],
          })
          .eq('id_empleado', idEmpleado)
          .select();

      if (response.isEmpty) {
        throw Exception('No se pudo actualizar el empleado');
      }

      print('✅ Empleado actualizado exitosamente');
    } catch (e) {
      print('❌ Error al actualizar empleado: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 ELIMINAR EMPLEADO (soft delete)
  // ==============================================================
  Future<void> eliminarEmpleado(int idEmpleado) async {
    try {
      final response = await _supabase
          .from('empleado_x_empresa')
          .update({'activo': false})
          .eq('id_empleado', idEmpleado)
          .select();

      if (response.isEmpty) {
        throw Exception('No se pudo eliminar el empleado');
      }

      print('✅ Empleado eliminado (desactivado)');
    } catch (e) {
      print('❌ Error al eliminar empleado: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 REACTIVAR EMPLEADO
  // ==============================================================
  Future<void> reactivarEmpleado(int idEmpleado) async {
    try {
      final response = await _supabase
          .from('empleado_x_empresa')
          .update({'activo': true})
          .eq('id_empleado', idEmpleado)
          .select();

      if (response.isEmpty) {
        throw Exception('No se pudo reactivar el empleado');
      }

      print('✅ Empleado reactivado');
    } catch (e) {
      print('❌ Error al reactivar empleado: $e');
      rethrow;
    }
  }

  // ==============================================================
  // 🔹 VERIFICAR SI LA EMPRESA TIENE EMPLEADOS
  // ==============================================================
  Future<bool> tieneEmpleados() async {
    try {
      final empleados = await obtenerEmpleados();
      return empleados.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar empleados: $e');
      return false;
    }
  }

  // ==============================================================
  // 🔹 CONTAR EMPLEADOS ACTIVOS
  // ==============================================================
  Future<int> contarEmpleados() async {
    try {
      final empleados = await obtenerEmpleados();
      return empleados.length;
    } catch (e) {
      print('❌ Error al contar empleados: $e');
      return 0;
    }
  }
}