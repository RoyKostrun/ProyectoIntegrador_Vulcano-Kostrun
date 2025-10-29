// lib/utils/auth_error_handler.dart

class AuthErrorHandler {
  /// Convierte errores de Supabase en mensajes amigables para el usuario
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // ❌ ERRORES DE CREDENCIALES (captura múltiples variantes)
    if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid_credentials') ||
        errorString.contains('invalid password') ||
        errorString.contains('email not confirmed') ||
        errorString.contains('user not found') ||
        errorString.contains('incorrect password')) {
      return 'Email o contraseña no válidos. Verifique e intente nuevamente';
    }
    
    // ❌ ERRORES DE EMAIL
    if (errorString.contains('invalid email') ||
        errorString.contains('email not found')) {
      return 'Email no válido o no registrado';
    }
    
    // ❌ ERRORES DE RED
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'Error de conexión. Verifique su internet e intente nuevamente';
    }
    
    // ❌ USUARIO YA EXISTE
    if (errorString.contains('user already registered') ||
        errorString.contains('already exists')) {
      return 'Este email ya está registrado';
    }
    
    // ❌ EMAIL NO VERIFICADO
    if (errorString.contains('email not confirmed')) {
      return 'Debe verificar su email antes de iniciar sesión';
    }
    
    // ❌ CUENTA BLOQUEADA/SUSPENDIDA
    if (errorString.contains('blocked') ||
        errorString.contains('suspended')) {
      return 'Su cuenta está temporalmente bloqueada. Contacte a soporte';
    }
    
    // ❌ DEMASIADOS INTENTOS
    if (errorString.contains('too many requests') ||
        errorString.contains('rate limit')) {
      return 'Demasiados intentos. Por favor espere unos minutos';
    }
    
    // ❌ DNI NO ENCONTRADO (para tu caso específico)
    if (errorString.contains('dni no encontrado')) {
      return 'DNI no registrado en el sistema';
    }
    
    // ❌ ERROR GENÉRICO (último recurso)
    return 'Ocurrió un error inesperado. Intente nuevamente más tarde';
  }
  
  /// Verifica si el error es de credenciales inválidas
  static bool isInvalidCredentials(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('invalid login credentials') ||
           errorString.contains('invalid_credentials');
  }
  
  /// Verifica si el error es de red/conexión
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout');
  }
}