import 'package:flutter_test/flutter_test.dart';
import 'package:changapp_client/utils/auth_error_handler.dart';

void main() {
  group('AuthErrorHandler.getErrorMessage', () {
    test('credenciales inválidas', () {
      expect(
        AuthErrorHandler.getErrorMessage('Invalid login credentials'),
        contains('Email o contraseña no válidos'),
      );
    });

    test('email inválido', () {
      expect(
        AuthErrorHandler.getErrorMessage('invalid email'),
        contains('Email no válido'),
      );
    });

    test('error de red', () {
      expect(
        AuthErrorHandler.getErrorMessage('Network timeout'),
        contains('Error de conexión'),
      );
    });

    test('usuario existente', () {
      expect(
        AuthErrorHandler.getErrorMessage('User already registered'),
        contains('ya está registrado'),
      );
    });

    test('cuenta bloqueada', () {
      expect(
        AuthErrorHandler.getErrorMessage('blocked'),
        contains('temporalmente bloqueada'),
      );
    });

    test('demasiados intentos', () {
      expect(
        AuthErrorHandler.getErrorMessage('Too many requests'),
        contains('Demasiados intentos'),
      );
    });

    test('dni no encontrado', () {
      expect(
        AuthErrorHandler.getErrorMessage('DNI no encontrado'),
        contains('DNI no registrado'),
      );
    });

    test('mensaje genérico', () {
      expect(
        AuthErrorHandler.getErrorMessage('otro error cualquiera'),
        contains('error inesperado'),
      );
    });
  });
}
