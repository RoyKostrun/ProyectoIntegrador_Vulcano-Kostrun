// lib/screens/login/role_selection_screen.dart
import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false;
  
  // ✅ Permitir selección múltiple
  bool _esEmpleador = false;
  bool _esEmpleado = false;

  void _continuar() {
    // Validar que al menos uno esté seleccionado
    if (!_esEmpleador && !_esEmpleado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un rol'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ PASAR LOS ROLES SIN GUARDAR
    Navigator.pushReplacementNamed(
      context, 
      '/rubros-bubbles',
      arguments: {
        'esEmpleador': _esEmpleador,
        'esEmpleado': _esEmpleado,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC5414B),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botón back
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _isLoading ? null : () {
                          Navigator.pushReplacementNamed(context, '/account-type-selection');
                        },
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
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Título
                  const Text(
                    '¿Cómo quieres usar ChangApp?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Subtítulo
                  Text(
                    'Puedes seleccionar uno o ambos roles',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // ✅ Checkbox Empleador
                  _RoleCheckbox(
                    title: 'EMPLEADOR',
                    subtitle: 'Demandante de servicios',
                    description: 'Busca y contrata profesionales para tus proyectos',
                    icon: Icons.business_center,
                    isSelected: _esEmpleador,
                    onChanged: _isLoading ? null : (value) {
                      setState(() => _esEmpleador = value);
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // ✅ Checkbox Empleado
                  _RoleCheckbox(
                    title: 'EMPLEADO',
                    subtitle: 'Oferente de servicios',
                    description: 'Ofrece tus servicios y encuentra oportunidades laborales',
                    icon: Icons.work_outline,
                    isSelected: _esEmpleado,
                    onChanged: _isLoading ? null : (value) {
                      setState(() => _esEmpleado = value);
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Botón continuar
                  ElevatedButton(
                    onPressed: (_esEmpleador || _esEmpleado) && !_isLoading
                        ? _continuar
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFC5414B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.white.withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
                            ),
                          )
                        : const Text(
                            'Continuar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Indicador de página
                  Center(
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Widget para checkbox de rol
class _RoleCheckbox extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final bool isSelected;
  final Function(bool)? onChanged;

  const _RoleCheckbox({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.isSelected,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!isSelected) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFC5414B) : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFFC5414B).withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFC5414B) : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFFC5414B) : Colors.grey.shade400,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // Ícono
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFC5414B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFC5414B), size: 24),
            ),
            
            const SizedBox(width: 16),
            
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC5414B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}