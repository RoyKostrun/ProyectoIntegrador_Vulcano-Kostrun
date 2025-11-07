// lib/screens/login/register_personal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para input formatters
import '../../components/section_container.dart';
import '../../components/custom_text_field.dart';
import '../../components/primary_button.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../utils/provinces_cities.dart';


class RegisterPersonalScreen extends StatefulWidget {
  const RegisterPersonalScreen({Key? key}) : super(key: key);

  @override
  State<RegisterPersonalScreen> createState() => _RegisterPersonalScreenState();
}

class _RegisterPersonalScreenState extends State<RegisterPersonalScreen> {
  // Controllers para todos los campos
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _generoController = TextEditingController(); // ✅ NUEVO: Género
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _contactoEmergenciaController = TextEditingController();
  final _nombreUbicacionController = TextEditingController();
  final _provinciaController = TextEditingController(); // ✅ REORDENADO: Provincia primero
  final _ciudadController = TextEditingController(); // ✅ REORDENADO: Ciudad segundo
  final _calleController = TextEditingController();
  final _barrioController = TextEditingController();
  final _numeroController = TextEditingController();
  final _codigoPostalController = TextEditingController();

  // Estados de progreso de secciones
  bool _datosPersonalesCompletos = false;
  bool _informacionCuentaCompleta = false;
  bool _informacionContactoCompleta = false;
  bool _informacionUbicacionCompleta = false;

  // Estados de UI
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Estados de error para cada campo
  String? _errorNombre;
  String? _errorApellido;
  String? _errorDni;
  String? _errorFechaNacimiento;
  String? _errorGenero; // ✅ NUEVO: Error género
  String? _errorEmail;
  String? _errorPassword;
  String? _errorConfirmPassword;
  String? _errorUsername;
  String? _errorTelefono;
  String? _errorContactoEmergencia;
  String? _errorNombreUbicacion;
  String? _errorProvincia;
  String? _errorCiudad;
  String? _errorCalle;
  String? _errorNumero;

  // ✅ NUEVO: Opciones de género
  final List<String> _generoOptions = ['M', 'F', 'X'];
  final Map<String, String> _generoLabels = {
    'M': 'Masculino',
    'F': 'Femenino',
    'X': 'No binario/Prefiero no decir',
  };

  @override
  void initState() {
    super.initState();
    
    // Listeners para validación en tiempo real
    _nombreController.addListener(_validateDatosPersonales);
    _apellidoController.addListener(_validateDatosPersonales);
    _dniController.addListener(_validateDatosPersonales);
    _fechaNacimientoController.addListener(_validateDatosPersonales);
    _generoController.addListener(_validateDatosPersonales); // ✅ NUEVO
    
    _emailController.addListener(_validateInformacionCuenta);
    _passwordController.addListener(_validateInformacionCuenta);
    _confirmPasswordController.addListener(_validateInformacionCuenta);
    _usernameController.addListener(_validateInformacionCuenta);
    
    _telefonoController.addListener(_validateInformacionContacto);
    _contactoEmergenciaController.addListener(_validateInformacionContacto);
    
    _nombreUbicacionController.addListener(_validateInformacionUbicacion);
    _provinciaController.addListener(_validateInformacionUbicacion);
    _ciudadController.addListener(_validateInformacionUbicacion);
    _calleController.addListener(_validateInformacionUbicacion);
    _numeroController.addListener(_validateInformacionUbicacion);
  }

  @override
  void dispose() {
    // Dispose controllers
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _fechaNacimientoController.dispose();
    _generoController.dispose(); // ✅ NUEVO
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _telefonoController.dispose();
    _contactoEmergenciaController.dispose();
    _nombreUbicacionController.dispose();
    _calleController.dispose();
    _barrioController.dispose();
    _numeroController.dispose();
    _provinciaController.dispose();
    _ciudadController.dispose();
    _codigoPostalController.dispose();
    
    super.dispose();
  }

  // ✅ MEJORADO: Validación de Datos Personales (incluye género)
  void _validateDatosPersonales() {
    setState(() {
      _errorNombre = Validators.validateName(_nombreController.text);
      _errorApellido = Validators.validateName(_apellidoController.text);
      _errorDni = Validators.validateDNI(_dniController.text);
      _errorFechaNacimiento = Validators.validateBirthDate(_fechaNacimientoController.text);
      _errorGenero = _generoController.text.isEmpty ? 'Selecciona un género' : null; // ✅ NUEVO
      
      _datosPersonalesCompletos = _errorNombre == null &&
                                 _errorApellido == null &&
                                 _errorDni == null &&
                                 _errorFechaNacimiento == null &&
                                 _errorGenero == null && // ✅ NUEVO
                                 _nombreController.text.trim().isNotEmpty &&
                                 _apellidoController.text.trim().isNotEmpty &&
                                 _dniController.text.trim().isNotEmpty &&
                                 _fechaNacimientoController.text.trim().isNotEmpty &&
                                 _generoController.text.trim().isNotEmpty; // ✅ NUEVO
    });
  }

  // Validación de Información de Cuenta (Sección 2)
  void _validateInformacionCuenta() {
    if (!_datosPersonalesCompletos) return;
    
    setState(() {
      _errorEmail = Validators.validateEmail(_emailController.text);
      _errorPassword = Validators.validatePassword(_passwordController.text);
      _errorConfirmPassword = Validators.validateConfirmPassword(
        _passwordController.text, 
        _confirmPasswordController.text
      );
      _errorUsername = Validators.validateRequired(_usernameController.text, 'Username');
      
      _informacionCuentaCompleta = _errorEmail == null &&
                                  _errorPassword == null &&
                                  _errorConfirmPassword == null &&
                                  _errorUsername == null &&
                                  _emailController.text.trim().isNotEmpty &&
                                  _passwordController.text.isNotEmpty &&
                                  _confirmPasswordController.text.isNotEmpty &&
                                  _usernameController.text.trim().isNotEmpty;
    });
  }

  // Validación de Información de Contacto (Sección 3)
  void _validateInformacionContacto() {
    if (!_informacionCuentaCompleta) return;
    
    setState(() {
      _errorTelefono = Validators.validatePhone(_telefonoController.text);
      _errorContactoEmergencia = Validators.validatePhone(_contactoEmergenciaController.text);
      
      _informacionContactoCompleta = _errorTelefono == null &&
                                    _errorContactoEmergencia == null &&
                                    _telefonoController.text.trim().isNotEmpty &&
                                    _contactoEmergenciaController.text.trim().isNotEmpty;
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

  bool get _canRegister => _datosPersonalesCompletos &&
                          _informacionCuentaCompleta &&
                          _informacionContactoCompleta &&
                          _informacionUbicacionCompleta;

  void _register() async {
    if (!_canRegister) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Crear usuario en Supabase Auth
      final authResponse = await AuthService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        tipoUsuario: 'PERSONA',
      );

      if (authResponse.user != null) {
        // 2. Crear perfil de usuario
        final profileData = {
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
          'dni': _dniController.text.trim(),
          'username': _usernameController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'contactoEmergencia': _contactoEmergenciaController.text.trim(),
          'fechaNacimiento': _fechaNacimientoController.text,
          'genero': _generoController.text,
        };

        await AuthService.createUserProfile(
          tipoUsuario: 'PERSONA',
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


        // 4. Mostrar éxito y navegar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cuenta creada exitosamente!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Navegar a selección de roles
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
        setState(() {
          _isLoading = false;
        });
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
          'Registro Personal',
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

              // ✅ SECCIÓN 1: Datos Personales (con género)
              SectionContainer(
                title: '1. Datos Personales',
                isCompleted: _datosPersonalesCompletos,
                isEnabled: true,
                children: [
                  CustomTextField(
                    controller: _nombreController,
                    hintText: 'Nombre',
                    hasError: _errorNombre != null,
                    errorText: _errorNombre,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _apellidoController,
                    hintText: 'Apellido',
                    hasError: _errorApellido != null,
                    errorText: _errorApellido,
                  ),
                  const SizedBox(height: 16),
                  // ✅ MEJORADO: DNI con validación estricta de 8 dígitos
                  TextFormField(
                    controller: _dniController,
                    keyboardType: TextInputType.number,
                    maxLength: 8, // ✅ Máximo 8 caracteres
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // ✅ Solo números
                      LengthLimitingTextInputFormatter(8), // ✅ Límite estricto
                    ],
                    decoration: InputDecoration(
                      hintText: 'DNI (8 dígitos)',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _errorDni != null ? Colors.red : const Color(0xFF012345),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _errorDni != null ? Colors.red : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _errorDni != null ? Colors.red : const Color(0xFF012345),
                          width: 2,
                        ),
                      ),
                      errorText: _errorDni,
                      counterText: '${_dniController.text.length}/8', // ✅ Contador visible
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ✅ NUEVO: Selector de género
                  CustomTextField(
                    controller: _generoController,
                    hintText: 'Seleccionar Género',
                    isDropdown: true,
                    options: _generoOptions.map((value) => _generoLabels[value]!).toList(),
                    hasError: _errorGenero != null,
                    errorText: _errorGenero,
                    onOptionSelected: (selected) {
                      // Convertir el label seleccionado de vuelta al valor
                      final selectedValue = _generoLabels.entries
                          .firstWhere((entry) => entry.value == selected)
                          .key;
                      _generoController.text = selectedValue;
                      _validateDatosPersonales();
                    },
                  ),
                  const SizedBox(height: 16),
                  // Selector de fecha
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                        helpText: 'Selecciona tu fecha de nacimiento',
                        cancelText: 'Cancelar',
                        confirmText: 'Confirmar',
                        locale: const Locale('es', 'ES'),
                      );
                      if (date != null) {
                        _fechaNacimientoController.text = date.toIso8601String().split('T')[0];
                        
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _validateDatosPersonales();
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _fechaNacimientoController,
                        hintText: 'Fecha de Nacimiento (Mayor de 18 años)',
                        hasError: _errorFechaNacimiento != null,
                        errorText: _errorFechaNacimiento,
                        suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // SECCIÓN 2: Información de Cuenta
              SectionContainer(
                title: '2. Información de Cuenta',
                isCompleted: _informacionCuentaCompleta,
                isEnabled: _datosPersonalesCompletos,
                children: [
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    hasError: _errorEmail != null,
                    errorText: _errorEmail,
                    enabled: _datosPersonalesCompletos,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _usernameController,
                    hintText: 'Nombre de Usuario',
                    hasError: _errorUsername != null,
                    errorText: _errorUsername,
                    enabled: _datosPersonalesCompletos,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Contraseña',
                    obscureText: _obscurePassword,
                    hasError: _errorPassword != null,
                    errorText: _errorPassword,
                    enabled: _datosPersonalesCompletos,
                    suffixIcon: _datosPersonalesCompletos ? IconButton(
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
                    enabled: _datosPersonalesCompletos,
                    suffixIcon: _datosPersonalesCompletos ? IconButton(
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
                    hintText: 'Teléfono',
                    keyboardType: TextInputType.phone,
                    hasError: _errorTelefono != null,
                    errorText: _errorTelefono,
                    enabled: _informacionCuentaCompleta,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _contactoEmergenciaController,
                    hintText: 'Contacto de Emergencia',
                    keyboardType: TextInputType.phone,
                    hasError: _errorContactoEmergencia != null,
                    errorText: _errorContactoEmergencia,
                    enabled: _informacionCuentaCompleta,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ✅ SECCIÓN 4: Información de Ubicación (REORDENADA)
              SectionContainer(
                title: '4. Información de Ubicación',
                isCompleted: _informacionUbicacionCompleta,
                isEnabled: _informacionContactoCompleta,
                children: [
                  CustomTextField(
                    controller: _nombreUbicacionController,
                    hintText: 'Nombre de la ubicación (ej: Casa, Trabajo)',
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
                      _ciudadController.clear(); // Limpiar ciudad cuando cambia provincia
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
                text: _canRegister ? 'Crear Cuenta' : 'Completa todos los campos',
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