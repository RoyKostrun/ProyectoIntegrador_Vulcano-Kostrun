// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../components/app_logo.dart';
import '../components/custom_text_field.dart';
import '../components/primary_button.dart';

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

  @override
  void dispose() {
    _emailOrDniController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _onLogin() async {
    if (_emailOrDniController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simular proceso de login
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // Aquí implementarás la lógica de login
    print('Login con: ${_emailOrDniController.text}');
    print('Contraseña: ${_passwordController.text}');
    
    // Navegar a la pantalla principal después del login
    // Navigator.pushReplacementNamed(context, '/home');
  }

  void _goToCreateAccount() {
    // Navegar a la pantalla de selección de tipo de cuenta
    Navigator.pushNamed(context, '/account-type-selection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // Logo de la aplicación
              const AppLogo(),
              
              const SizedBox(height: 50),
              
              // Título
              const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Campo Email o DNI
              CustomTextField(
                controller: _emailOrDniController,
                hintText: 'Email o DNI',
                keyboardType: TextInputType.text,
              ),
              
              const SizedBox(height: 16),
              
              // Campo Contraseña
              CustomTextField(
                controller: _passwordController,
                hintText: 'Contraseña',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey[600],
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Link "¿Olvidaste tu contraseña?"
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Navegar a recuperar contraseña
                    print('Recuperar contraseña');
                  },
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botón Iniciar Sesión
              PrimaryButton(
                text: 'Iniciar Sesión',
                onPressed: _onLogin,
                isLoading: _isLoading,
              ),
              
              const SizedBox(height: 24),
              
              // Separador "O"
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey[400],
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'O',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.grey[400],
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Link "Crear cuenta"
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  children: [
                    const TextSpan(text: '¿No tienes cuenta? '),
                    TextSpan(
                      text: 'Crear cuenta',
                      style: const TextStyle(
                        color: Color(0xFFC5414B), // Rojo POLO 52
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = _goToCreateAccount,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Indicador de página
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5414B), // Rojo POLO 52
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}