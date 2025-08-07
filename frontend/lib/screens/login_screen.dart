// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../components/app_logo.dart';
import '../components/custom_text_field.dart';
import '../components/primary_button.dart';
import '../services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _emailOrDniController.addListener(_clearErrors);
    _passwordController.addListener(_clearErrors);
  }

  @override
  void dispose() {
    _emailOrDniController.removeListener(_clearErrors);
    _passwordController.removeListener(_clearErrors);
    _emailOrDniController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_emailError || _passwordError) {
      setState(() {
        _emailError = false;
        _passwordError = false;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _onLogin() async {
    setState(() {
      _emailError = _emailOrDniController.text.isEmpty;
      _passwordError = _passwordController.text.isEmpty;
    });
    if (_emailError || _passwordError) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.signInWithEmail(
        emailOrDni: _emailOrDniController.text.trim(),
        password: _passwordController.text,
      );
      if (response.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sesión iniciada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                child: Padding(
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
                      CustomTextField(
                        controller: _emailOrDniController,
                        hintText: 'Email o DNI',
                        keyboardType: TextInputType.text,
                        hasError: _emailError,
                        errorText: _emailError ? 'Campo obligatorio*' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        hintText: 'Contraseña',
                        obscureText: _obscurePassword,
                        hasError: _passwordError,
                        errorText: _passwordError ? 'Campo obligatorio*' : null,
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
                          onPressed: () => print('Recuperar contraseña'),
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
                      const Spacer(),
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
