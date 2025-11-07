import 'package:flutter/material.dart';
import '../../components/section_container.dart';
import '../../components/custom_text_field.dart';
import '../../components/primary_button.dart';
import '../../services/ubicacion_service.dart';
import '../../utils/validators.dart';
import '../../utils/provinces_cities.dart';

class CrearUbicacionScreen extends StatefulWidget {
  const CrearUbicacionScreen({Key? key}) : super(key: key);

  @override
  State<CrearUbicacionScreen> createState() => _CrearUbicacionScreenState();
}

class _CrearUbicacionScreenState extends State<CrearUbicacionScreen> {
  final _nombreUbicacionController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _calleController = TextEditingController();
  final _numeroController = TextEditingController();
  final _barrioController = TextEditingController();
  final _codigoPostalController = TextEditingController();

  final _ubicacionService = UbicacionService();
  bool _isLoading = false;
  bool _esPrincipal = false;

  // Errores
  String? _errorNombreUbicacion;
  String? _errorProvincia;
  String? _errorCiudad;
  String? _errorCalle;
  String? _errorNumero;

  bool get _canSave =>
      _errorNombreUbicacion == null &&
      _errorProvincia == null &&
      _errorCiudad == null &&
      _errorCalle == null &&
      _errorNumero == null &&
      _nombreUbicacionController.text.trim().isNotEmpty &&
      _provinciaController.text.trim().isNotEmpty &&
      _ciudadController.text.trim().isNotEmpty &&
      _calleController.text.trim().isNotEmpty &&
      _numeroController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Escuchar cambios para validar automáticamente
    _nombreUbicacionController.addListener(_validateForm);
    _provinciaController.addListener(_validateForm);
    _ciudadController.addListener(_validateForm);
    _calleController.addListener(_validateForm);
    _numeroController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _errorNombreUbicacion =
          Validators.validateRequired(_nombreUbicacionController.text, 'Nombre ubicación');
      _errorProvincia =
          Validators.validateRequired(_provinciaController.text, 'Provincia');
      _errorCiudad =
          Validators.validateRequired(_ciudadController.text, 'Ciudad');
      _errorCalle = Validators.validateStreet(_calleController.text);
      _errorNumero =
          Validators.validateRequired(_numeroController.text, 'Número');
    });
  }

  // ✅ MODIFICADO: Ahora devuelve la ubicación creada
  Future<void> _guardarUbicacion() async {
    _validateForm();
    if (!_canSave) return;

    setState(() => _isLoading = true);

    try {
      // ✅ Capturar la ubicación creada
      final nuevaUbicacion = await _ubicacionService.crearUbicacion({
        'nombre': _nombreUbicacionController.text.trim(),
        'provincia': _provinciaController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
        'calle': _calleController.text.trim(),
        'numero': _numeroController.text.trim(),
        'barrio': _barrioController.text.trim().isEmpty
            ? null
            : _barrioController.text.trim(),
        'codigo_postal': _codigoPostalController.text.trim().isEmpty
            ? null
            : _codigoPostalController.text.trim(),
        'es_principal': _esPrincipal,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ubicación creada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // ✅ CAMBIO CLAVE: Devolver la ubicación creada
        Navigator.pop(context, nuevaUbicacion);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nombreUbicacionController.dispose();
    _provinciaController.dispose();
    _ciudadController.dispose();
    _calleController.dispose();
    _numeroController.dispose();
    _barrioController.dispose();
    _codigoPostalController.dispose();
    super.dispose();
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
          'Nueva Ubicación',
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
                'Completa los datos de tu nueva ubicación',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              SectionContainer(
                title: 'Información de Ubicación',
                isCompleted: _canSave,
                isEnabled: true,
                children: [
                  CustomTextField(
                    controller: _nombreUbicacionController,
                    hintText: 'Nombre de la ubicación (ej: Casa, Trabajo)',
                    hasError: _errorNombreUbicacion != null,
                    errorText: _errorNombreUbicacion,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _provinciaController,
                    hintText: 'Seleccionar Provincia',
                    isDropdown: true,
                    options: ProvincesCities.provinces,
                    hasError: _errorProvincia != null,
                    errorText: _errorProvincia,
                    onOptionSelected: (province) {
                      _ciudadController.clear();
                      _validateForm();
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _ciudadController,
                    hintText: 'Seleccionar Ciudad',
                    isDropdown: true,
                    options: ProvincesCities.getCitiesByProvince(_provinciaController.text),
                    hasError: _errorCiudad != null,
                    errorText: _errorCiudad,
                    enabled: _provinciaController.text.isNotEmpty,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          controller: _calleController,
                          hintText: 'Calle',
                          hasError: _errorCalle != null,
                          errorText: _errorCalle,
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
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _barrioController,
                    hintText: 'Barrio (Opcional)',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _codigoPostalController,
                    hintText: 'Código Postal (Opcional)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Marcar como ubicación principal'),
                    value: _esPrincipal,
                    onChanged: (v) => setState(() => _esPrincipal = v),
                    activeColor: const Color(0xFFC5414B),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              PrimaryButton(
                text: _canSave ? 'Guardar Ubicación' : 'Completa todos los campos',
                onPressed: _canSave ? _guardarUbicacion : () {},
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