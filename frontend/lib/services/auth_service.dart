// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as AppUser;
import '../utils/auth_error_handler.dart';
import 'supabase_client.dart';

class AuthService {
  
  // ✅ MEJORADO: Iniciar sesión con email/DNI y contraseña
  static Future<AuthResponse> signInWithEmail({
    required String emailOrDni,
    required String password,
  }) async {
    try {
      // ✅ VERIFICAR SI EL USUARIO ESTÁ BLOQUEADO PRIMERO
    final blocked = await isUserBlocked(emailOrDni);
    if (blocked) {
      throw Exception('Tu cuenta está bloqueada temporalmente. Intenta nuevamente más tarde.');
    }
      String email = emailOrDni;
      
      // Si parece un DNI (8 dígitos), buscar el email asociado
      if (RegExp(r'^[0-9]{8}$').hasMatch(emailOrDni)) {
        try {
          final response = await supabase
              .from('usuario_persona')
              .select('id_usuario')
              .eq('dni', emailOrDni)
              .maybeSingle();
              
          if (response != null) {
            final userResponse = await supabase
                .from('usuario')
                .select('email')
                .eq('id_usuario', response['id_usuario'])
                .single();
                
            email = userResponse['email'];
          } else {
            throw Exception('DNI no encontrado');
          }
        } catch (e) {
          throw Exception('DNI no encontrado');
        }
      }

      // Intentar login con Supabase
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Registrar intento exitoso en tabla sesion
      await _registerSuccessfulLogin(email);

      return response;
      
    } on AuthException catch (authError) {
      print('❌ AuthException: ${authError.message}');
      throw AuthErrorHandler.getErrorMessage(authError.message);
      
    } catch (error) {
      print('❌ Error general: $error');
      throw AuthErrorHandler.getErrorMessage(error);
    }
  }

  // ✅ NUEVO: Registrar login exitoso y resetear intentos fallidos
  static Future<void> _registerSuccessfulLogin(String email) async {
    try {
      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', email)
          .single();
          
      final idUsuario = userResponse['id_usuario'];
      
      final sesionExistente = await supabase
          .from('sesion')
          .select('id_sesion')
          .eq('id_usuario', idUsuario)
          .maybeSingle();
      
      if (sesionExistente != null) {
        await supabase
            .from('sesion')
            .update({
              'intentos_login_fallidos': 0,
              'bloqueado_hasta': null,
              'activa': true,
              'fecha_inicio': DateTime.now().toIso8601String(),
            })
            .eq('id_sesion', sesionExistente['id_sesion']);
      } else {
        await supabase
            .from('sesion')
            .insert({
              'id_usuario': idUsuario,
              'intentos_login_fallidos': 0,
              'activa': true,
              'fecha_inicio': DateTime.now().toIso8601String(),
            });
      }
      
      print('✅ Login exitoso registrado');
    } catch (e) {
      print('⚠️ Error registrando login exitoso: $e');
    }
  }

// ✅ NUEVO: Registrar intento fallido (CON PRINTS DE DEBUG)
static Future<void> registerFailedLoginAttempt(String emailOrDni) async {
  try {
    print('🟡 INICIO registerFailedLoginAttempt con: $emailOrDni');
    
    String email = emailOrDni;
    
    if (RegExp(r'^[0-9]{8}$').hasMatch(emailOrDni)) {
      print('🟡 Es un DNI, buscando email...');
      try {
        final personaResponse = await supabase
            .from('usuario_persona')
            .select('id_usuario')
            .eq('dni', emailOrDni)
            .maybeSingle();
        
        print('🟡 Respuesta búsqueda DNI: $personaResponse');
            
        if (personaResponse != null) {
          final userResponse = await supabase
              .from('usuario')
              .select('email')
              .eq('id_usuario', personaResponse['id_usuario'])
              .single();
              
          email = userResponse['email'];
          print('🟡 Email encontrado para DNI: $email');
        } else {
          print('🔴 DNI no existe, saliendo');
          return;
        }
      } catch (e) {
        print('🔴 Error buscando DNI: $e');
        return;
      }
    } else {
      print('🟡 Es un email: $email');
    }
    
    // Obtener id_usuario
    print('🟡 Buscando usuario con email: $email');
    final userResponse = await supabase
        .from('usuario')
        .select('id_usuario')
        .eq('email', email)
        .maybeSingle();
    
    print('🟡 Usuario encontrado: $userResponse');
    
    if (userResponse == null) {
      print('🔴 Usuario no existe en tabla usuario, saliendo');
      return;
    }
    
    final idUsuario = userResponse['id_usuario'];
    print('🟡 ID Usuario obtenido: $idUsuario');
    
    // Buscar sesión existente
    print('🟡 Buscando sesión existente para id_usuario: $idUsuario');
    final sesionExistente = await supabase
        .from('sesion')
        .select('id_sesion, intentos_login_fallidos')
        .eq('id_usuario', idUsuario)
        .maybeSingle();
    
    print('🟡 Sesión existente encontrada: $sesionExistente');
    
    int intentos = 1;
    DateTime? bloqueadoHasta;
    
    if (sesionExistente != null) {
      intentos = (sesionExistente['intentos_login_fallidos'] ?? 0) + 1;
      print('🟡 Sesión existe, incrementando intentos a: $intentos');
      
      if (intentos >= 5) {
        bloqueadoHasta = DateTime.now().add(Duration(minutes: 15));
        print('🔴 BLOQUEANDO usuario hasta: $bloqueadoHasta');
      }
      
      print('🟡 Actualizando sesión existente...');
      await supabase
          .from('sesion')
          .update({
            'intentos_login_fallidos': intentos,
            'bloqueado_hasta': bloqueadoHasta?.toIso8601String(),
            'activa': false,
          })
          .eq('id_sesion', sesionExistente['id_sesion']);
      
      print('✅ Sesión actualizada correctamente');
          
    } else {
      print('🟡 No existe sesión, creando nueva con 1 intento...');
      
      await supabase
          .from('sesion')
          .insert({
            'id_usuario': idUsuario,
            'intentos_login_fallidos': 1,
            'activa': false,
          });
      
      print('✅ Nueva sesión creada correctamente');
    }
    
    print('⚠️ Intento fallido registrado. Total de intentos: $intentos');
    
  } catch (e) {
    print('❌ Error registrando intento fallido: $e');
    print('❌ Stack trace completo:');
    print(StackTrace.current);
  }
}

  // ✅ NUEVO: Verificar si el usuario está bloqueado
  static Future<bool> isUserBlocked(String emailOrDni) async {
    try {
      String email = emailOrDni;
      
      if (RegExp(r'^[0-9]{8}$').hasMatch(emailOrDni)) {
        try {
          final personaResponse = await supabase
              .from('usuario_persona')
              .select('id_usuario')
              .eq('dni', emailOrDni)
              .maybeSingle();
              
          if (personaResponse != null) {
            final userResponse = await supabase
                .from('usuario')
                .select('email')
                .eq('id_usuario', personaResponse['id_usuario'])
                .single();
                
            email = userResponse['email'];
          } else {
            return false;
          }
        } catch (e) {
          return false;
        }
      }
      
      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', email)
          .maybeSingle();
      
      if (userResponse == null) return false;
      
      final idUsuario = userResponse['id_usuario'];
      
      final sesion = await supabase
          .from('sesion')
          .select('bloqueado_hasta')
          .eq('id_usuario', idUsuario)
          .maybeSingle();
      
      if (sesion == null || sesion['bloqueado_hasta'] == null) {
        return false;
      }
      
      final bloqueadoHasta = DateTime.parse(sesion['bloqueado_hasta']);
      final ahora = DateTime.now();
      
      return ahora.isBefore(bloqueadoHasta);
      
    } catch (e) {
      print('⚠️ Error verificando bloqueo: $e');
      return false;
    }
  }

  // ✅ NUEVO: Obtener minutos restantes de bloqueo
  static Future<int> getRemainingBlockMinutes(String emailOrDni) async {
    try {
      String email = emailOrDni;
      
      if (RegExp(r'^[0-9]{8}$').hasMatch(emailOrDni)) {
        try {
          final personaResponse = await supabase
              .from('usuario_persona')
              .select('id_usuario')
              .eq('dni', emailOrDni)
              .maybeSingle();
              
          if (personaResponse != null) {
            final userResponse = await supabase
                .from('usuario')
                .select('email')
                .eq('id_usuario', personaResponse['id_usuario'])
                .single();
                
            email = userResponse['email'];
          } else {
            return 0;
          }
        } catch (e) {
          return 0;
        }
      }
      
      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', email)
          .maybeSingle();
      
      if (userResponse == null) return 0;
      
      final idUsuario = userResponse['id_usuario'];
      
      final sesion = await supabase
          .from('sesion')
          .select('bloqueado_hasta')
          .eq('id_usuario', idUsuario)
          .maybeSingle();
      
      if (sesion == null || sesion['bloqueado_hasta'] == null) {
        return 0;
      }
      
      final bloqueadoHasta = DateTime.parse(sesion['bloqueado_hasta']);
      final ahora = DateTime.now();
      final diferencia = bloqueadoHasta.difference(ahora);
      
      return diferencia.inMinutes.clamp(0, 15);
      
    } catch (e) {
      print('⚠️ Error obteniendo minutos restantes: $e');
      return 0;
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

  // Obtener datos completos del usuario desde la BD
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

      final transformedResponse = Map<String, dynamic>.from(response);
      
      if (transformedResponse['usuario_persona'] is List) {
        final personaList = transformedResponse['usuario_persona'] as List;
        transformedResponse['usuario_persona'] = personaList.isNotEmpty ? personaList.first : null;
      }
      
      if (transformedResponse['usuario_empresa'] is List) {
        final empresaList = transformedResponse['usuario_empresa'] as List;
        transformedResponse['usuario_empresa'] = empresaList.isNotEmpty ? empresaList.first : null;
      }
      
      print('🔍 Respuesta transformada: $transformedResponse');
      print('✅ Usuario encontrado, creando modelo...');
      
      return AppUser.User.fromJson(transformedResponse);
      
    } catch (error) {
      print('❌ Error obteniendo datos del usuario: $error');
      print('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  static Future<int> getCurrentUserId() async {
    try {
      final userData = await getCurrentUserData();
      
      if (userData == null) {
        throw Exception('Usuario no autenticado. Por favor inicia sesión.');
      }
      
      return userData.idUsuario;
      
    } catch (e) {
      print('❌ Error obteniendo ID usuario: $e');
      rethrow;
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

  // ✅ Recuperar contraseña
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
  
  // Crear perfil completo después del registro
  static Future<AppUser.User> createUserProfile({
    required String tipoUsuario,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) throw 'Usuario no autenticado';

      print('📌 Usuario autenticado: ${authUser.email}');
      print('📌 Auth User ID (UUID): ${authUser.id}');
      print('📌 Tipo de usuario: $tipoUsuario');
      print('📌 Datos del perfil recibidos: $profileData');

      if (tipoUsuario == 'PERSONA' && profileData['dni'] != null) {
        final existingDNI = await supabase
            .from('usuario_persona')
            .select('dni')
            .eq('dni', profileData['dni'])
            .maybeSingle();

        if (existingDNI != null) {
          throw 'El DNI ya está registrado en el sistema';
        }
      }

      if (tipoUsuario == 'PERSONA' && profileData['username'] != null) {
        final existingUsername = await supabase
            .from('usuario_persona')
            .select('username')
            .eq('username', profileData['username'])
            .maybeSingle();

        if (existingUsername != null) {
          throw 'El nombre de usuario ya está en uso';
        }
      }

      final userResponse = await supabase
          .from('usuario')
          .insert({
            'auth_user_id': authUser.id,
            'email': authUser.email,
            'tipo_usuario': tipoUsuario,
            'telefono': profileData['telefono'],
            'contrasena': profileData['contrasena'],
          })
          .select()
          .single();

      print('✅ Insertado en tabla usuario: $userResponse');
      final userId = userResponse['id_usuario'];

      if (tipoUsuario == 'PERSONA') {
        final personaData = {
          'id_usuario': userId,
          'nombre': profileData['nombre'],
          'apellido': profileData['apellido'],
          'dni': profileData['dni'],
          'username': profileData['username'],
          'fecha_nacimiento': profileData['fechaNacimiento'],
          'genero': profileData['genero'],
          'contacto_emergencia': profileData['contactoEmergencia'],
          'es_empleador': false,
          'es_empleado': false,
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
          'es_empleador': false,
        };

        print('📦 Insertando en usuario_empresa: $empresaData');
        await supabase.from('usuario_empresa').insert(empresaData);
        print('✅ Insertado en usuario_empresa');
      }

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

  // Crear ubicación del usuario
  static Future<Map<String, dynamic>> createUserLocation(Map<String, dynamic> ubicacionData) async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) throw 'Usuario no autenticado';

      print('📍 Creando ubicación para usuario: ${authUser.email}');
      print('📍 Datos de ubicación: $ubicacionData');

      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', authUser.email!)
          .single();

      final userId = userResponse['id_usuario'];

      if (ubicacionData['esPrincipal'] == true) {
        await supabase
            .from('ubicacion')
            .update({'es_principal': false})
            .eq('id_usuario', userId);
        
        print('📍 Ubicaciones anteriores desmarcadas como principales');
      }

      final dataToInsert = {
        'id_usuario': userId,
        'nombre': ubicacionData['nombre'],
        'calle': ubicacionData['calle'],
        'barrio': ubicacionData['barrio'],
        'numero': ubicacionData['numero'],
        'ciudad': ubicacionData['ciudad'],
        'provincia': ubicacionData['provincia'],
        'codigo_postal': ubicacionData['codigoPostal'],
        'es_principal': ubicacionData['esPrincipal'] ?? true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

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

  // Verificar si el usuario completó el onboarding
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

  // Marcar onboarding como completado
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

  // Actualizar roles del usuario
  static Future<void> updateUserRoles({
    required bool esEmpleador,
    required bool esEmpleado,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      print('📋 Actualizando roles: empleador=$esEmpleador, empleado=$esEmpleado');

      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario, tipo_usuario')
          .eq('email', user.email!)
          .single();

      final idUsuario = userResponse['id_usuario'];
      final tipoUsuario = userResponse['tipo_usuario'];

      print('📋 Usuario ID: $idUsuario, Tipo: $tipoUsuario');

      if (tipoUsuario == 'PERSONA') {
        await supabase
            .from('usuario_persona')
            .update({
              'es_empleador': esEmpleador,
              'es_empleado': esEmpleado,
            })
            .eq('id_usuario', idUsuario);
            
        print('✅ Roles actualizados en usuario_persona');
        
      } else if (tipoUsuario == 'EMPRESA') {
        await supabase
            .from('usuario_empresa')
            .update({'es_empleador': esEmpleador})
            .eq('id_usuario', idUsuario);
            
        print('✅ es_empleador actualizado en usuario_empresa');
      }
          
      print('✅ Roles actualizados correctamente');
    } catch (e) {
      print('❌ Error actualizando roles: $e');
      throw 'Error al actualizar roles: $e';
    }
  }

  // Verificar si puede publicar trabajos
  static Future<bool> puedePublicarTrabajos() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario, tipo_usuario')
          .eq('email', user.email!)
          .single();

      final tipoUsuario = userResponse['tipo_usuario'];
      final idUsuario = userResponse['id_usuario'];

      if (tipoUsuario == 'EMPRESA') {
        final empresaResponse = await supabase
            .from('usuario_empresa')
            .select('es_empleador')
            .eq('id_usuario', idUsuario)
            .single();

        return empresaResponse['es_empleador'] == true;
        
      } else if (tipoUsuario == 'PERSONA') {
        final personaResponse = await supabase
            .from('usuario_persona')
            .select('es_empleador')
            .eq('id_usuario', idUsuario)
            .single();

        return personaResponse['es_empleador'] == true;
      }

      return false;
    } catch (e) {
      print('❌ Error verificando permiso de publicación: $e');
      return false;
    }
  }

  // Obtener información del empleador
  static Future<Map<String, dynamic>?> getEmpleadorInfo() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario, tipo_usuario')
          .eq('email', user.email!)
          .single();

      final tipoUsuario = userResponse['tipo_usuario'];
      final idUsuario = userResponse['id_usuario'];

      if (tipoUsuario == 'EMPRESA') {
        final empresaResponse = await supabase
            .from('usuario_empresa')
            .select('id_empresa, es_empleador')
            .eq('id_usuario', idUsuario)
            .single();

        return {
          'tipo': 'EMPRESA',
          'id_empleador': empresaResponse['id_empresa'],
          'puede_publicar': empresaResponse['es_empleador'] == true,
        };
        
      } else if (tipoUsuario == 'PERSONA') {
        final personaResponse = await supabase
            .from('usuario_persona')
            .select('id_persona, es_empleador')
            .eq('id_usuario', idUsuario)
            .single();

        return {
          'tipo': 'PERSONA',
          'id_empleador': personaResponse['id_persona'],
          'puede_publicar': personaResponse['es_empleador'] == true,
        };
      }

      return null;
    } catch (e) {
      print('❌ Error obteniendo info del empleador: $e');
      return null;
    }
  }

  // Guardar rubros seleccionados por el usuario
  static Future<void> saveUserRubros(List<String> rubrosNames) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      print('📋 Iniciando guardado de rubros: $rubrosNames');

      print('📋 Buscando rubros en BD...');
      final rubrosResponse = await supabase
          .from('rubro')
          .select('id_rubro, nombre')
          .inFilter('nombre', rubrosNames);

      print('📋 Rubros encontrados en BD: $rubrosResponse');

      if (rubrosResponse.isEmpty) {
        throw 'No se encontraron rubros con los nombres: $rubrosNames';
      }
      
      print('📋 Buscando usuario con email: ${user.email}');
      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', user.email!)
          .single();

      final idUsuario = userResponse['id_usuario'];
      print('📋 ID Usuario encontrado: $idUsuario');

      print('📋 Limpiando rubros anteriores...');
      await supabase
          .from('usuario_rubro')
          .delete()
          .eq('id_usuario', idUsuario);

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

      final insertResponse = await supabase
          .from('usuario_rubro')
          .insert(relaciones)
          .select();

      print('📋 Rubros insertados exitosamente: $insertResponse');
      print('✅ ${relaciones.length} rubros guardados correctamente');

    } catch (e) {
      print('❌ Error detallado guardando rubros: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      throw 'Error al guardar rubros: $e';
    }
  }

  // Obtener ubicaciones del usuario
  static Future<List<Map<String, dynamic>>> getUserLocations() async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) throw 'Usuario no autenticado';

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
          .order('es_principal', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
      
    } catch (error) {
      print('❌ Error al obtener ubicaciones: $error');
      throw 'Error al obtener ubicaciones: $error';
    }
  }

  // Actualizar ubicación principal
  static Future<void> updatePrimaryLocation(int ubicacionId) async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) throw 'Usuario no autenticado';

      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', authUser.email!)
          .single();

      final userId = userResponse['id_usuario'];

      await supabase
          .from('ubicacion')
          .update({'es_principal': false})
          .eq('id_usuario', userId);

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

  // Eliminar ubicación
  static Future<void> deleteUserLocation(int ubicacionId) async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) throw 'Usuario no autenticado';

      final userResponse = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('email', authUser.email!)
          .single();

      final userId = userResponse['id_usuario'];

      final ubicacion = await supabase
          .from('ubicacion')
          .select('es_principal')
          .eq('id_ubicacion', ubicacionId)
          .eq('id_usuario', userId)
          .single();

      await supabase
          .from('ubicacion')
          .delete()
          .eq('id_ubicacion', ubicacionId)
          .eq('id_usuario', userId);

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

  // Verificar disponibilidad de DNI
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

  // Verificar disponibilidad de username
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