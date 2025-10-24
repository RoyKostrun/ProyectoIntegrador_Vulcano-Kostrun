// lib/screens/login/forgot_password_screen.dart
import 'package:flutter/material.dart';
import '../../components/app_logo.dart';
import '../../components/custom_text_field.dart';
import '../../components/primary_button.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  
  // Variables para errores
  bool _emailError = false;
  String? _emailErrorMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmailOnTyping);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmailOnTyping);
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmailOnTyping() {
    final value = _emailController.text.trim();
    
    if (value.isEmpty) {
      setState(() {
        _emailError = false;
        _emailErrorMessage = null;
      });
      return;
    }
    
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      setState(() {
        _emailError = true;
        _emailErrorMessage = 'Ejemplo válido: nombre@dominio.com';
      });
    } else {
      setState(() {
        _emailError = false;
        _emailErrorMessage = null;
      });
    }
  }

  Future<void> _sendRecoveryEmail() async {
    setState(() {
      _emailError = false;
      _emailErrorMessage = null;
    });

    // Validar email vacío
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = true;
        _emailErrorMessage = 'Este campo es requerido';
      });
      return;
    }

    // Validar formato de email
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      setState(() {
        _emailError = true;
        _emailErrorMessage = 'Email inválido';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.resetPassword(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
              child: Stack(
                children: [
                  // Botón back
                  Positioned(
                    left: 16,
                    top: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  // Logo centrado
                  Center(
                    child: AppLogo(size: 100, isDarkBackground: true),
                  ),
                ],
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
                      
                      if (!_emailSent) ...[
                        // Pantalla de solicitud
                        const Text(
                          '¿Olvidaste tu contraseña?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),
                        CustomTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          hasError: _emailError,
                          errorText: _emailErrorMessage,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: 'Enviar enlace de recuperación',
                          onPressed: _sendRecoveryEmail,
                          isLoading: _isLoading,
                          isDarkStyle: true,
                        ),
                      ] else ...[
                        // Pantalla de confirmación
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mark_email_read,
                                  size: 40,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                '¡Email enviado!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Hemos enviado un enlace de recuperación a:',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _emailController.text.trim(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC5414B),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'El enlace es válido por 1 hora. Si no ves el email, revisa tu carpeta de spam.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: 'Volver al inicio de sesión',
                          onPressed: () => Navigator.pop(context),
                          isDarkStyle: true,
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          width: 50,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(2),
                          ),
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