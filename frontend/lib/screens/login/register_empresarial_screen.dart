// lib/screens/register_empresarial_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para CUIT validation
import '../../components/section_container.dart';
import '../../components/custom_text_field.dart';
import '../../components/primary_button.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../utils/provinces_cities.dart';

class RegisterEmpresarialScreen extends StatefulWidget {
  const RegisterEmpresarialScreen({Key? key}) : super(key: key);

  @override
  State<RegisterEmpresarialScreen> createState() => _RegisterEmpresarialScreenState();
}

class _RegisterEmpresarialScreenState extends State<RegisterEmpresarialScreen> {
  // Controllers para todos los campos
  final _nombreCorporativoController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _cuitController = TextEditingController();
  final _representanteController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _nombreUbicacionController = TextEditingController();
  final _provinciaController = TextEditingController(); // ✅ REORDENADO: Provincia primero
  final _ciudadController = TextEditingController(); // ✅ REORDENADO: Ciudad segundo
  final _calleController = TextEditingController();
  final _barrioController = TextEditingController();
  final _numeroController = TextEditingController();
  final _codigoPostalController = TextEditingController();

  // Estados de progreso de secciones
  bool _datosEmpresaCompletos = false;
  bool _informacionCuentaCompleta = false;
  bool _informacionContactoCompleta = false;
  bool _informacionUbicacionCompleta = false;

  // Estados de UI
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Estados de error para cada campo
  String? _errorNombreCorporativo;
  String? _errorRazonSocial;
  String? _errorCuit;
  String? _errorRepresentante;
  String? _errorEmail;
  String? _errorPassword;
  String? _errorConfirmPassword;
  String? _errorTelefono;
  String? _errorNombreUbicacion;
  String? _errorProvincia;
  String? _errorCiudad;
  String? _errorCalle;
  String? _errorNumero;

  @override
  void initState() {
    super.initState();
    
    // Listeners para validación en tiempo real
    _nombreCorporativoController.addListener(_validateDatosEmpresa);
    _razonSocialController.addListener(_validateDatosEmpresa);
    _cuitController.addListener(_validateDatosEmpresa);
    _representanteController.addListener(_validateDatosEmpresa);
    
    _emailController.addListener(_validateInformacionCuenta);
    _passwordController.addListener(_validateInformacionCuenta);
    _confirmPasswordController.addListener(_validateInformacionCuenta);
    
    _telefonoController.addListener(_validateInformacionContacto);
    
    _nombreUbicacionController.addListener(_validateInformacionUbicacion);
    _provinciaController.addListener(_validateInformacionUbicacion);
    _ciudadController.addListener(_validateInformacionUbicacion);
    _calleController.addListener(_validateInformacionUbicacion);
    _numeroController.addListener(_validateInformacionUbicacion);
  }

  @override
  void dispose() {
    // Dispose controllers
    _nombreCorporativoController.dispose();
    _razonSocialController.dispose();
    _cuitController.dispose();
    _representanteController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telefonoController.dispose();
    _nombreUbicacionController.dispose();
    _calleController.dispose();
    _barrioController.dispose();
    _numeroController.dispose();
    _provinciaController.dispose();
    _ciudadController.dispose();
    _codigoPostalController.dispose();
    
    super.dispose();
  }

  // ✅ MEJORADO: Validación de Datos de Empresa con CUIT
  void _validateDatosEmpresa() {
    setState(() {
      _errorNombreCorporativo = Validators.validateRequired(
        _nombreCorporativoController.text,
        'Nombre de la Empresa',
      );
      _errorRazonSocial = Validators.validateRequired(
        _razonSocialController.text,
        'Razón Social',
      );
      // ✅ VALIDACIÓN CUIT MEJORADA (11 dígitos)
      _errorCuit = _validateCUIT(_cuitController.text);
      _errorRepresentante = Validators.validateRequired(
        _representanteController.text,
        'Representante Legal',
      );

      _datosEmpresaCompletos = _errorNombreCorporativo == null &&
                              _errorRazonSocial == null &&
                              _errorCuit == null &&
                              _errorRepresentante == null &&
                              _nombreCorporativoController.text.trim().isNotEmpty &&
                              _razonSocialController.text.trim().isNotEmpty &&
                              _cuitController.text.trim().isNotEmpty &&
                              _representanteController.text.trim().isNotEmpty;
    });
  }

  // ✅ NUEVO: Validador específico para CUIT
  String? _validateCUIT(String value) {
    if (value.isEmpty) return 'CUIT es obligatorio';
    
    // Remover guiones y espacios
    String cleanCuit = value.replaceAll(RegExp(r'[-\s]'), '');
    
    // Verificar que tenga exactamente 11 dígitos
    if (cleanCuit.length != 11) return 'CUIT debe tener 11 dígitos';
    
    // Verificar que solo contenga números
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanCuit)) return 'CUIT debe contener solo números';
    
    return null;
  }

  // Validación de Información de Cuenta (Sección 2)
  void _validateInformacionCuenta() {
    if (!_datosEmpresaCompletos) return;
    
    setState(() {
      _errorEmail = Validators.validateEmail(_emailController.text);
      _errorPassword = Validators.validatePassword(_passwordController.text);
      _errorConfirmPassword = Validators.validateConfirmPassword(
        _passwordController.text, 
        _confirmPasswordController.text
      );
      
      _informacionCuentaCompleta = _errorEmail == null &&
                                  _errorPassword == null &&
                                  _errorConfirmPassword == null &&
                                  _emailController.text.trim().isNotEmpty &&
                                  _passwordController.text.isNotEmpty &&
                                  _confirmPasswordController.text.isNotEmpty;
    });
  }

  // Validación de Información de Contacto (Sección 3)
  void _validateInformacionContacto() {
    if (!_informacionCuentaCompleta) return;
    
    setState(() {
      _errorTelefono = Validators.validatePhone(_telefonoController.text);
      
      _informacionContactoCompleta = _errorTelefono == null &&
                                    _telefonoController.text.trim().isNotEmpty;
    });
  }

  // ✅ ACTUALIZADO: Validación de Información de Ubicación (nuevo orden)
  void _validateInformacionUbicacion() {
    if (!_informacionContactoCompleta) return;
    
    setState(() {
      _errorNombreUbicacion = Validators.validateRequired(_nombreUbicacionController.text, 'Nombre ubicación');
      _errorProvincia = Validators.validateRequired(_provinciaController.text, 'Provincia');
      _errorCiudad = Validators.validateRequired(_ciudadController.text, 'Ciudad');
      _errorCalle = Validators.validateStreet(_calleController.text);
      _errorNumero = Validators.validateRequired(_numeroController.text, 'Número');
      
      _informacionUbicacionCompleta = _errorNombreUbicacion == null &&
                                     _errorProvincia == null &&
                                     _errorCiudad == null &&
                                     _errorCalle == null &&
                                     _errorNumero == null &&
                                     _nombreUbicacionController.text.trim().isNotEmpty &&
                                     _provinciaController.text.trim().isNotEmpty &&
                                     _ciudadController.text.trim().isNotEmpty &&
                                     _calleController.text.trim().isNotEmpty &&
                                     _numeroController.text.trim().isNotEmpty;
    });
  }

  bool get _canRegister => _datosEmpresaCompletos &&
                          _informacionCuentaCompleta &&
                          _informacionContactoCompleta &&
                          _informacionUbicacionCompleta;

  Future<void> _register() async {
    if (!_canRegister) return;

    setState(() => _isLoading = true);

    try {
      // 1. Crear usuario en Supabase Auth
      final authResponse = await AuthService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        tipoUsuario: 'EMPRESA',
      );

      if (authResponse.user != null) {
        // 2. Crear perfil de empresa
        final profileData = {
          'nombreCorporativo': _nombreCorporativoController.text.trim(),
          'razonSocial': _razonSocialController.text.trim(),
          'cuit': _cuitController.text.trim(),
          'representanteLegal': _representanteController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'contrasena': _passwordController.text,
        };

        await AuthService.createUserProfile(
          tipoUsuario: 'EMPRESA',
          profileData: profileData,
        );

        // 3. Crear ubicación principal
        final ubicacionData = {
          'nombre': _nombreUbicacionController.text.trim(),
          'calle': _calleController.text.trim(),
          'barrio': _barrioController.text.trim().isEmpty ? null : _barrioController.text.trim(),
          'numero': _numeroController.text.trim(),
          'ciudad': _ciudadController.text.trim(),
          'provincia': _provinciaController.text.trim(),
          'codigoPostal': _codigoPostalController.text.trim().isEmpty ? null : _codigoPostalController.text.trim(),
          'esPrincipal': true,
        };

        await AuthService.createUserLocation(ubicacionData);

        // ✅ CORREGIDO: Navegar al flujo de onboarding (rol → rubros)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cuenta empresarial creada exitosamente!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // ✅ CAMBIO IMPORTANTE: Navegar a selección de roles (igual que personas)
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/role-selection');
            }
          });
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Registro Empresarial',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicador visual
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Completa todos los campos requeridos',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),

              // SECCIÓN 1: Datos de Empresa
              SectionContainer(
                title: '1. Datos de Empresa',
                isCompleted: _datosEmpresaCompletos,
                isEnabled: true,
                children: [
                  CustomTextField(
                    controller: _nombreCorporativoController,
                    hintText: 'Nombre de la Empresa',
                    hasError: _errorNombreCorporativo != null,
                    errorText: _errorNombreCorporativo,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _razonSocialController,
                    hintText: 'Razón Social',
                    hasError: _errorRazonSocial != null,
                    errorText: _errorRazonSocial,
                  ),
                  const SizedBox(height: 16),
                  // ✅ MEJORADO: CUIT con validación estricta
                  TextFormField(
                    controller: _cuitController,
                    keyboardType: TextInputType.number,
                    maxLength: 13, // 11 dígitos + 2 guiones
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')), // Solo números y guiones
                      LengthLimitingTextInputFormatter(13),
                      _CUITInputFormatter(), // ✅ Formatter personalizado
                    ],
                    decoration: InputDecoration(
                      hintText: 'CUIT (XX-XXXXXXXX-X)',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _errorCuit != null ? Colors.red : const Color(0xFF012345),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _errorCuit != null ? Colors.red : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _errorCuit != null ? Colors.red : const Color(0xFF012345),
                          width: 2,
                        ),
                      ),
                      errorText: _errorCuit,
                      counterText: '${_cuitController.text.replaceAll(RegExp(r'[-\s]'), '').length}/11',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _representanteController,
                    hintText: 'Representante Legal',
                    hasError: _errorRepresentante != null,
                    errorText: _errorRepresentante,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // SECCIÓN 2: Información de Cuenta
              SectionContainer(
                title: '2. Información de Cuenta',
                isCompleted: _informacionCuentaCompleta,
                isEnabled: _datosEmpresaCompletos,
                children: [
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email Corporativo',
                    keyboardType: TextInputType.emailAddress,
                    hasError: _errorEmail != null,
                    errorText: _errorEmail,
                    enabled: _datosEmpresaCompletos,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Contraseña',
                    obscureText: _obscurePassword,
                    hasError: _errorPassword != null,
                    errorText: _errorPassword,
                    enabled: _datosEmpresaCompletos,
                    suffixIcon: _datosEmpresaCompletos ? IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ) : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirmar Contraseña',
                    obscureText: _obscureConfirmPassword,
                    hasError: _errorConfirmPassword != null,
                    errorText: _errorConfirmPassword,
                    enabled: _datosEmpresaCompletos,
                    suffixIcon: _datosEmpresaCompletos ? IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ) : null,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // SECCIÓN 3: Información de Contacto
              SectionContainer(
                title: '3. Información de Contacto',
                isCompleted: _informacionContactoCompleta,
                isEnabled: _informacionCuentaCompleta,
                children: [
                  CustomTextField(
                    controller: _telefonoController,
                    hintText: 'Teléfono Corporativo',
                    keyboardType: TextInputType.phone,
                    hasError: _errorTelefono != null,
                    errorText: _errorTelefono,
                    enabled: _informacionCuentaCompleta,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ✅ SECCIÓN 4: Información de Ubicación (REORDENADA como personas)
              SectionContainer(
                title: '4. Información de Ubicación',
                isCompleted: _informacionUbicacionCompleta,
                isEnabled: _informacionContactoCompleta,
                children: [
                  CustomTextField(
                    controller: _nombreUbicacionController,
                    hintText: 'Nombre de la ubicación (ej: Sede Central, Oficina)',
                    hasError: _errorNombreUbicacion != null,
                    errorText: _errorNombreUbicacion,
                    enabled: _informacionContactoCompleta,
                  ),
                  const SizedBox(height: 16),
                  // ✅ 1. PROVINCIA (primero)
                  CustomTextField(
                    controller: _provinciaController,
                    hintText: 'Seleccionar Provincia',
                    isDropdown: true,
                    options: ProvincesCities.provinces,
                    hasError: _errorProvincia != null,
                    errorText: _errorProvincia,
                    enabled: _informacionContactoCompleta,
                    onOptionSelected: (province) {
                      _ciudadController.clear();
                      _validateInformacionUbicacion();
                    },
                  ),
                  const SizedBox(height: 16),
                  // ✅ 2. CIUDAD (segundo)
                  CustomTextField(
                    controller: _ciudadController,
                    hintText: 'Seleccionar Ciudad',
                    isDropdown: true,
                    options: ProvincesCities.getCitiesByProvince(_provinciaController.text),
                    hasError: _errorCiudad != null,
                    errorText: _errorCiudad,
                    enabled: _informacionContactoCompleta && _provinciaController.text.isNotEmpty,
                  ),
                  const SizedBox(height: 16),
                  // ✅ 3. CALLE Y NÚMERO (tercero)
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          controller: _calleController,
                          hintText: 'Calle',
                          hasError: _errorCalle != null,
                          errorText: _errorCalle,
                          enabled: _informacionContactoCompleta,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: CustomTextField(
                          controller: _numeroController,
                          hintText: 'Número',
                          keyboardType: TextInputType.number,
                          hasError: _errorNumero != null,
                          errorText: _errorNumero,
                          enabled: _informacionContactoCompleta,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ✅ 4. BARRIO (cuarto - opcional)
                  CustomTextField(
                    controller: _barrioController,
                    hintText: 'Barrio (Opcional)',
                    enabled: _informacionContactoCompleta,
                  ),
                  const SizedBox(height: 16),
                  // ✅ 5. CÓDIGO POSTAL (quinto - opcional)
                  CustomTextField(
                    controller: _codigoPostalController,
                    hintText: 'Código Postal (Opcional)',
                    keyboardType: TextInputType.number,
                    enabled: _informacionContactoCompleta,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Botón usando componente reutilizable
              PrimaryButton(
                text: _canRegister ? 'Crear Cuenta Empresarial' : 'Completa todos los campos',
                onPressed: _canRegister ? _register : () {},
                isLoading: _isLoading,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ NUEVO: Formatter para CUIT con formato XX-XXXXXXXX-X
class _CUITInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (text.length <= 2) {
      return newValue.copyWith(text: text);
    } else if (text.length <= 10) {
      String formatted = '${text.substring(0, 2)}-${text.substring(2)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else if (text.length <= 11) {
      String formatted = '${text.substring(0, 2)}-${text.substring(2, 10)}-${text.substring(10)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    
    return oldValue;
  }
}