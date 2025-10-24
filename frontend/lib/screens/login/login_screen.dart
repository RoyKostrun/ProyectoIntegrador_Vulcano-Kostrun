// lib/screens/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../components/app_logo.dart';
import '../../components/custom_text_field.dart';
import '../../components/primary_button.dart';
import '../../services/auth_service.dart';
import '../../utils/auth_error_handler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailOrDniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Variables para errores
  bool _emailError = false;
  bool _passwordError = false;
  String? _emailErrorMessage;
  String? _passwordErrorMessage;
  String? _generalErrorMessage; // ✅ NUEVO: Error general del login

  @override
  void initState() {
    super.initState();
    _emailOrDniController.addListener(_validateEmailOnTyping);
    _passwordController.addListener(_clearErrors);
  }

  @override
  void dispose() {
    _emailOrDniController.removeListener(_validateEmailOnTyping);
    _passwordController.removeListener(_clearErrors);
    _emailOrDniController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ NUEVO: Validar email mientras escribe
  void _validateEmailOnTyping() {
    final value = _emailOrDniController.text.trim();
    
    // Si está vacío, no mostrar error aún
    if (value.isEmpty) {
      setState(() {
        _emailError = false;
        _emailErrorMessage = null;
        _generalErrorMessage = null;
      });
      return;
    }
    
    // Si parece ser un DNI (8 dígitos), no validar como email
    if (RegExp(r'^[0-9]{1,8}$').hasMatch(value)) {
      setState(() {
        _emailError = false;
        _emailErrorMessage = null;
        _generalErrorMessage = null;
      });
      return;
    }
    
    // Validar formato de email
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      setState(() {
        _emailError = true;
        _emailErrorMessage = 'Ejemplo válido: nombre@dominio.com';
        _generalErrorMessage = null;
      });
    } else {
      setState(() {
        _emailError = false;
        _emailErrorMessage = null;
        _generalErrorMessage = null;
      });
    }
  }

  void _clearErrors() {
    if (_emailError || _passwordError || _generalErrorMessage != null) {
      setState(() {
        _emailError = false;
        _passwordError = false;
        _emailErrorMessage = null;
        _passwordErrorMessage = null;
        _generalErrorMessage = null;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  // ✅ MEJORADO: Login con validaciones y manejo de errores
  void _onLogin() async {
    // Limpiar errores previos
    setState(() {
      _emailError = false;
      _passwordError = false;
      _emailErrorMessage = null;
      _passwordErrorMessage = null;
      _generalErrorMessage = null;
    });

    // Validar campos vacíos
    if (_emailOrDniController.text.trim().isEmpty) {
      setState(() {
        _emailError = true;
        _emailErrorMessage = 'Este campo es requerido';
      });
    }
    
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = true;
        _passwordErrorMessage = 'Este campo es requerido';
      });
    }

    if (_emailError || _passwordError) return;

    // ✅ NUEVO: Verificar si el usuario está bloqueado ANTES de intentar login
    final emailOrDni = _emailOrDniController.text.trim();
    final isBlocked = await AuthService.isUserBlocked(emailOrDni);
    
    if (isBlocked) {
      final minutosRestantes = await AuthService.getRemainingBlockMinutes(emailOrDni);
      setState(() {
        _generalErrorMessage = 'Cuenta bloqueada temporalmente. Intente nuevamente en $minutosRestantes minutos.';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.signInWithEmail(
        emailOrDni: emailOrDni,
        password: _passwordController.text,
      );
      
      if (response.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sesión iniciada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Verificar si completó onboarding
        final hasCompleted = await AuthService.hasCompletedOnboarding();
        if (hasCompleted) {
          Navigator.pushReplacementNamed(context, '/main-nav');
        } else {
          Navigator.pushReplacementNamed(context, '/role-selection');
        }
      }
    } catch (error) {
  // ✅ Registrar intento fallido en la base de datos
  await AuthService.registerFailedLoginAttempt(emailOrDni);
  
  if (mounted) {
    // El error ya viene procesado desde AuthService
    final errorMessage = error.toString();
    
    setState(() {
      _generalErrorMessage = errorMessage;
    });
    
    // También mostrar en SnackBar para mayor visibilidad
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ NUEVO: Navegación a recuperación de contraseña
  void _onForgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  void _goToCreateAccount() {
    Navigator.pushNamed(context, '/account-type-selection');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // Sección superior
          Container(
            height: screenHeight * 0.4,
            width: double.infinity,
            color: Colors.black,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: AppLogo(size: 100, isDarkBackground: true),
              ),
            ),
          ),

          // Sección inferior
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFC5414B),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        'Iniciar Sesión',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // ✅ NUEVO: Mensaje de error general
                      if (_generalErrorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _generalErrorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      CustomTextField(
                        controller: _emailOrDniController,
                        hintText: 'Email o DNI',
                        keyboardType: TextInputType.text,
                        hasError: _emailError,
                        errorText: _emailErrorMessage,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        hintText: 'Contraseña',
                        obscureText: _obscurePassword,
                        hasError: _passwordError,
                        errorText: _passwordErrorMessage,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey[600],
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _onForgotPassword, // ✅ CORREGIDO
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: 'Iniciar Sesión',
                        onPressed: _onLogin,
                        isLoading: _isLoading,
                        isDarkStyle: true,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.4))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('O', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.4))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(fontSize: 15, color: Colors.white),
                            children: [
                              const TextSpan(text: '¿No tienes cuenta? '),
                              TextSpan(
                                text: 'Crear cuenta',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 2,
                                ),
                                recognizer: TapGestureRecognizer()..onTap = _goToCreateAccount,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          width: 50,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}