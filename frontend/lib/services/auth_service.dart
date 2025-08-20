// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as AppUser;
import 'supabase_client.dart';

class AuthService {
  
  // Iniciar sesión con email/DNI y contraseña
  static Future<AuthResponse> signInWithEmail({
    required String emailOrDni,
    required String password,
  }) async {
    try {
      // Si parece un DNI (8 dígitos), buscar el email asociado
      String email = emailOrDni;
      if (RegExp(r'^[0-9]{8}$').hasMatch(emailOrDni)) {
        // Buscar email por DNI en la tabla usuario_persona
        final response = await supabase
            .from('usuario_persona')
            .select('id_usuario')
            .eq('dni', emailOrDni)
            .maybeSingle();
            
        if (response != null) {
          // Obtener email del usuario
          final userResponse = await supabase
              .from('usuario')
              .select('email')
              .eq('id_usuario', response['id_usuario'])
              .single();
              
          email = userResponse['email'];
        } else {
          throw 'DNI no encontrado';
        }
      }

      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } catch (error) {
      throw 'Error al iniciar sesión: $error';
    }
  }

  // Registrar nuevo usuario
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String tipoUsuario,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'tipo_usuario': tipoUsuario,
          ...?metadata,
        },
      );

      return response;
    } catch (error) {
      throw 'Error al registrarse: $error';
    }
  }

  // Cerrar sesión
  static Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (error) {
      throw 'Error al cerrar sesión: $error';
    }
  }

  // Obtener usuario actual
  static AppUser.User? get currentUser {
    final authUser = supabase.auth.currentUser;
    return authUser != null ? _mapAuthUserToUser(authUser) : null;
  }

  // Verificar si está autenticado
  static bool get isAuthenticated {
    return supabase.auth.currentUser != null;
  }

  // Stream para escuchar cambios en la autenticación
  static Stream<AuthState> get authStateChanges {
    return supabase.auth.onAuthStateChange;
  }

  // ✅ Obtener datos completos del usuario desde la BD - CORREGIDO
  static Future<AppUser.User?> getCurrentUserData() async {
    try {
      final authUser = supabase.auth.currentUser;
      print('🔍 Auth user: $authUser');
      
      if (authUser == null) {
        print('❌ No hay usuario autenticado');
        return null;
      }

      print('🔍 Email del usuario: ${authUser.email}');
      
      if (authUser.email == null) {
        print('❌ Email del usuario es null');
        return null;
      }

      // Buscar usuario en la tabla usuario
      print('🔍 Buscando usuario en BD con email: ${authUser.email}');
      
      final response = await supabase
          .from('usuario')
          .select('''
            *,
            ubicacion(*),
            usuario_persona(*),
            usuario_empresa(*)
          ''')
          .eq('email', authUser.email!)
          .maybeSingle();

      print('🔍 Respuesta de la BD: $response');

      if (response == null) {
        print('❌ No se encontró usuario en la BD');
        return null;
      }

      // ✅ TRANSFORMAR LISTAS EN OBJETOS ÚNICOS
      final transformedResponse = Map<String, dynamic>.from(response);
      
      // Convertir usuario_persona de lista a objeto único (si existe)
      if (transformedResponse['usuario_persona'] is List) {
        final personaList = transformedResponse['usuario_persona'] as List;
        transformedResponse['usuario_persona'] = personaList.isNotEmpty ? personaList.first : null;
      }
      
      // Convertir usuario_empresa de lista a objeto único (si existe)
      if (transformedResponse['usuario_empresa'] is List) {
        final empresaList = transformedResponse['usuario_empresa'] as List;
        transformedResponse['usuario_empresa'] = empresaList.isNotEmpty ? empresaList.first : null;
      }
      
      // Mantener ubicacion como lista (puede tener múltiples ubicaciones)
      // No necesita transformación
      
      print('🔍 Respuesta transformada: $transformedResponse');
      print('✅ Usuario encontrado, creando modelo...');
      
      return AppUser.User.fromJson(transformedResponse);
      
    } catch (error) {
      print('❌ Error obteniendo datos del usuario: $error');
      print('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Actualizar perfil
  static Future<void> updateProfile({
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? data,
  }) async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(
          email: attributes?['email'],
          phone: attributes?['phone'],
          data: data,
        ),
      );
    } catch (error) {
      throw 'Error actualizando perfil: $error';
    }
  }

  // Recuperar contraseña
  static Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } catch (error) {
      throw 'Error enviando email de recuperación: $error';
    }
  }

  // Verificar email
  static Future<void> resendConfirmation(String email) async {
    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (error) {
      throw 'Error reenviando confirmación: $error';
    }
  }

  // Función auxiliar para mapear AuthUser a nuestro modelo User
  static AppUser.User _mapAuthUserToUser(User authUser) {
    return AppUser.User(
      idUsuario: 0,
      tipoUsuario: authUser.userMetadata?['tipo_usuario'] ?? 'PERSONA',
      email: authUser.email ?? '',
      fechaRegistro: authUser.createdAt is String 
          ? DateTime.parse(authUser.createdAt)
          : authUser.createdAt as DateTime,
      estadoCuenta: 'ACTIVO',
      cantidadTrabajosRealizados: 0,
      puntosReputacion: 0,
      createdAt: authUser.createdAt is String 
          ? DateTime.parse(authUser.createdAt)
          : authUser.createdAt as DateTime,
      updatedAt: authUser.updatedAt != null
          ? (authUser.updatedAt is String 
              ? DateTime.parse(authUser.updatedAt!)
              : authUser.updatedAt as DateTime)
          : (authUser.createdAt is String 
              ? DateTime.parse(authUser.createdAt)
              : authUser.createdAt as DateTime),
    );
  }
  
  // ✅ Crear perfil completo después del registro - CORREGIDO
  static Future<AppUser.User> createUserProfile({
    required String tipoUsuario,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) throw 'Usuario no autenticado';

      print('📌 Usuario autenticado: ${authUser.email}');
      print('📌 Tipo de usuario: $tipoUsuario');
      print('📌 Datos del perfil recibidos: $profileData');

      // Verificar si DNI ya existe
      if (profileData['dni'] != null) {
        final existingDNI = await supabase
            .from('usuario_persona')
            .select('dni')
            .eq('dni', profileData['dni'])
            .maybeSingle();

        if (existingDNI != null) {
          throw 'El DNI ya está registrado en el sistema';
        }
      }

      // Verificar si username ya existe
      if (profileData['username'] != null) {
        final existingUsername = await supabase
            .from('usuario_persona')
            .select('username')
            .eq('username', profileData['username'])
            .maybeSingle();

        if (existingUsername != null) {
          throw 'El nombre de usuario ya está en uso';
        }
      }

      // 1. Insertar en tabla usuario
      final userResponse = await supabase
          .from('usuario')
          .insert({
            'email': authUser.email,
            'tipo_usuario': tipoUsuario,
            'telefono': profileData['telefono'],
            'contrasena': profileData['contrasena'],
          })
          .select()
          .single();

      print('✅ Insertado en tabla usuario: $userResponse');
      final userId = userResponse['id_usuario'];

      // 2. Insertar en tabla específica según tipo de usuario
      if (tipoUsuario == 'PERSONA') {
        final personaData = {
          'id_usuario': userId,
          'nombre': profileData['nombre'],
          'apellido': profileData['apellido'],
          'dni': profileData['dni'],
          'username': profileData['username'],
          'fecha_nacimiento': profileData['fechaNacimiento'],
          'genero': profileData['genero'],
          'rol': profileData['rol'],
          'contacto_emergencia': profileData['contactoEmergencia'],
        };

        print('📦 Insertando en usuario_persona: $personaData');
        await supabase.from('usuario_persona').insert(personaData);
        print('✅ Insertado en usuario_persona');
      } else if (tipoUsuario == 'EMPRESA') {
        final empresaData = {
          'id_usuario': userId,
          'nombre_corporativo': profileData['nombreCorporativo'],
          'razon_social': profileData['razonSocial'],
          'cuit': profileData['cuit'],
          'representante_legal': profileData['representanteLegal'],
        };

        print('📦 Insertando en usuario_empresa: $empresaData');
        await supabase.from('usuario_empresa').insert(empresaData);
        print('✅ Insertado en usuario_empresa');
      }

      // 3. Obtener usuario completo con manejo de null
      print('🔍 Obteniendo usuario completo...');
      final completeUser = await getCurrentUserData();
      
      if (completeUser == null) {
        print('❌ No se pudo obtener el usuario completo');
        throw 'Error: No se pudo obtener los datos del usuario después del registro';
      }
      
      print('✅ Usuario completo obtenido: ${completeUser.email}');
      return completeUser;
      
    } catch (error) {
      print('❌ Error creando perfil: $error');
      throw 'Error creando perfil: $error';
    }
  }

  // ✅ Crear ubicación del usuario
  static Future<Map<String, dynamic>> createUserLocation(Map<String, dynamic> ubicacionData) async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) throw 'Usuario no autenticado';

      print('📍 Creando ubicación para usuario: ${authUser.email}');
      print('📍 Datos de ubicación: $ubicacionData');

      // Obtener el ID del usuario desde la tabla usuario
      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', authUser.email!)
          .single();

      final userId = userResponse['id_usuario'];

      // Si es ubicación principal, desmarcar otras ubicaciones principales
      if (ubicacionData['esPrincipal'] == true) {
        await supabase
            .from('ubicacion')
            .update({'es_principal': false})
            .eq('id_usuario', userId);
        
        print('📍 Ubicaciones anteriores desmarcadas como principales');
      }

      // Preparar datos para insertar
      final dataToInsert = {
        'id_usuario': userId,
        'nombre': ubicacionData['nombre'],
        'calle': ubicacionData['calle'],
        'barrio': ubicacionData['barrio'], // Puede ser null
        'numero': ubicacionData['numero'],
        'ciudad': ubicacionData['ciudad'],
        'provincia': ubicacionData['provincia'],
        'codigo_postal': ubicacionData['codigoPostal'], // Puede ser null
        'es_principal': ubicacionData['esPrincipal'] ?? true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Insertar en la tabla ubicacion
      final response = await supabase
          .from('ubicacion')
          .insert(dataToInsert)
          .select()
          .single();

      print('✅ Ubicación creada exitosamente: ${response['id_ubicacion']}');
      return response;
      
    } catch (error) {
      print('❌ Error al crear ubicación: $error');
      throw 'Error al crear ubicación: $error';
    }
  }

  // ========================================
  // MÉTODOS DE ONBOARDING - NUEVOS
  // ========================================
  
  /// Verificar si el usuario completó el onboarding
  static Future<bool> hasCompletedOnboarding() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final response = await supabase
          .from('usuario')
          .select('onboarding_completed')
          .eq('email', user.email!)
          .single();

      return response['onboarding_completed'] ?? false;
    } catch (e) {
      print('❌ Error verificando onboarding: $e');
      return false;
    }
  }

  /// Marcar onboarding como completado
  static Future<void> markOnboardingCompleted() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      await supabase
          .from('usuario')
          .update({'onboarding_completed': true})
          .eq('email', user.email!);
          
      print('✅ Onboarding marcado como completado');
    } catch (e) {
      print('❌ Error marcando onboarding: $e');
      throw 'Error al marcar onboarding: $e';
    }
  }

  /// Actualizar rol del usuario
// Reemplaza el método updateUserRole en tu AuthService

  static Future<void> updateUserRole(String role) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      print('📋 Actualizando rol a: $role');

      // Obtener datos del usuario para saber si es PERSONA o EMPRESA
      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario, tipo_usuario')
          .eq('email', user.email!)
          .single();

      final idUsuario = userResponse['id_usuario'];
      final tipoUsuario = userResponse['tipo_usuario'];

      print('📋 Usuario ID: $idUsuario, Tipo: $tipoUsuario');

      // Actualizar según el tipo de usuario
      if (tipoUsuario == 'PERSONA') {
        // Para personas, actualizar en usuario_persona
        await supabase
            .from('usuario_persona')
            .update({'rol': role})
            .eq('id_usuario', idUsuario);
            
        print('✅ Rol actualizado en usuario_persona');
        
      } else if (tipoUsuario == 'EMPRESA') {
        // Para empresas, actualizar en usuario_empresa
        // NOTA: Necesitas agregar el campo 'rol' a la tabla usuario_empresa
        await supabase
            .from('usuario_empresa')
            .update({'rol': role})
            .eq('id_usuario', idUsuario);
            
        print('✅ Rol actualizado en usuario_empresa');
      }
          
      print('✅ Rol de usuario actualizado a: $role');
    } catch (e) {
      print('❌ Error actualizando rol: $e');
      throw 'Error al actualizar rol: $e';
    }
  }

  /// Guardar rubros seleccionados por el usuario
  static Future<void> saveUserRubros(List<String> rubrosNames) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      print('📋 Iniciando guardado de rubros: $rubrosNames');

      // 1. Obtener IDs de los rubros por nombre
      print('📋 Buscando rubros en BD...');
      final rubrosResponse = await supabase
          .from('rubro')
          .select('id_rubro, nombre')
          .inFilter('nombre', rubrosNames);

      print('📋 Rubros encontrados en BD: $rubrosResponse');

      if (rubrosResponse.isEmpty) {
        throw 'No se encontraron rubros con los nombres: $rubrosNames';
      }
      
      // 2. Obtener el id_usuario desde la tabla usuario
      print('📋 Buscando usuario con email: ${user.email}');
      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', user.email!)
          .single();

      final idUsuario = userResponse['id_usuario'];
      print('📋 ID Usuario encontrado: $idUsuario');

      // 3. Verificar si ya tiene rubros asignados (limpiar primero)
      print('📋 Limpiando rubros anteriores...');
      await supabase
          .from('usuario_rubro')
          .delete()
          .eq('id_usuario', idUsuario);

      // 4. Preparar las relaciones para insertar
      final List<Map<String, dynamic>> relaciones = [];
      for (final rubro in rubrosResponse) {
        relaciones.add({
          'id_usuario': idUsuario,
          'id_rubro': rubro['id_rubro'],
          'fecha_asignacion': DateTime.now().toIso8601String(),
          'activo': true,
        });
      }

      print('📋 Relaciones a insertar: $relaciones');

      // 5. Insertar las nuevas relaciones
      final insertResponse = await supabase
          .from('usuario_rubro')
          .insert(relaciones)
          .select(); // Para confirmar la inserción

      print('📋 Rubros insertados exitosamente: $insertResponse');
      print('✅ ${relaciones.length} rubros guardados correctamente');

    } catch (e) {
      print('❌ Error detallado guardando rubros: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      throw 'Error al guardar rubros: $e';
    }
  }

  // ========================================
  // MÉTODOS DE UBICACIONES - EXISTENTES
  // ========================================

  // ✅ Obtener ubicaciones del usuario
  static Future<List<Map<String, dynamic>>> getUserLocations() async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) throw 'Usuario no autenticado';

      // Obtener el ID del usuario desde la tabla usuario
      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', authUser.email!)
          .single();

      final userId = userResponse['id_usuario'];

      final response = await supabase
          .from('ubicacion')
          .select('*')
          .eq('id_usuario', userId)
          .order('es_principal', ascending: false) // Principal primero
          .order('created_at', ascending: false); // Más recientes primero

      return List<Map<String, dynamic>>.from(response);
      
    } catch (error) {
      print('❌ Error al obtener ubicaciones: $error');
      throw 'Error al obtener ubicaciones: $error';
    }
  }

  // ✅ Actualizar ubicación principal
  static Future<void> updatePrimaryLocation(int ubicacionId) async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) throw 'Usuario no autenticado';

      // Obtener el ID del usuario desde la tabla usuario
      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', authUser.email!)
          .single();

      final userId = userResponse['id_usuario'];

      // Primero, quitar es_principal de todas las ubicaciones del usuario
      await supabase
          .from('ubicacion')
          .update({'es_principal': false})
          .eq('id_usuario', userId);

      // Luego, marcar la ubicación seleccionada como principal
      await supabase
          .from('ubicacion')
          .update({
            'es_principal': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_ubicacion', ubicacionId)
          .eq('id_usuario', userId);

      print('✅ Ubicación principal actualizada');
      
    } catch (error) {
      print('❌ Error al actualizar ubicación principal: $error');
      throw 'Error al actualizar ubicación principal: $error';
    }
  }

  // ✅ Eliminar ubicación
  static Future<void> deleteUserLocation(int ubicacionId) async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) throw 'Usuario no autenticado';

      // Obtener el ID del usuario desde la tabla usuario
      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', authUser.email!)
          .single();

      final userId = userResponse['id_usuario'];

      // Verificar que la ubicación pertenece al usuario
      final ubicacion = await supabase
          .from('ubicacion')
          .select('es_principal')
          .eq('id_ubicacion', ubicacionId)
          .eq('id_usuario', userId)
          .single();

      // Eliminar la ubicación
      await supabase
          .from('ubicacion')
          .delete()
          .eq('id_ubicacion', ubicacionId)
          .eq('id_usuario', userId);

      // Si era la ubicación principal, marcar otra como principal
      if (ubicacion['es_principal'] == true) {
        final otherLocations = await getUserLocations();
        if (otherLocations.isNotEmpty) {
          await updatePrimaryLocation(otherLocations.first['id_ubicacion']);
        }
      }

      print('✅ Ubicación eliminada exitosamente');
      
    } catch (error) {
      print('❌ Error al eliminar ubicación: $error');
      throw 'Error al eliminar ubicación: $error';
    }
  }

  // ✅ Verificar disponibilidad de DNI
  static Future<bool> isDNIAvailable(String dni) async {
    try {
      final response = await supabase
          .from('usuario_persona')
          .select('dni')
          .eq('dni', dni)
          .maybeSingle();
          
      return response == null;
    } catch (error) {
      return false;
    }
  }

  // ✅ Verificar disponibilidad de username
  static Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await supabase
          .from('usuario_persona')
          .select('username')
          .eq('username', username)
          .maybeSingle();
          
      return response == null;
    } catch (error) {
      return false;
    }
  }
}