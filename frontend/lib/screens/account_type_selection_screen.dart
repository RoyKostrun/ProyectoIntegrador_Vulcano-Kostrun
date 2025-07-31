// lib/screens/account_type_selection_screen.dart
import 'package:flutter/material.dart';
import '../components/app_logo.dart';

class AccountTypeSelectionScreen extends StatelessWidget {
  const AccountTypeSelectionScreen({Key? key}) : super(key: key);

  void _selectPersonal(BuildContext context) {
    // Navegar a la pantalla de registro personal
    Navigator.pushNamed(context, '/register-personal');
    print('Seleccionó: Personal');
  }

  void _selectEmpresarial(BuildContext context) {
    // Navegar a la pantalla de registro empresarial
    Navigator.pushNamed(context, '/register-empresarial');
    print('Seleccionó: Empresarial');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFC5414B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Logo de la aplicación
              const AppLogo(size: 60),
              
              const SizedBox(height: 40),
              
              // Título
              const Text(
                'Tipo de cuenta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Subtítulo
              Text(
                'Selecciona el tipo de cuenta que quieres crear',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Botón Personal
              _AccountTypeCard(
                title: 'Personal',
                subtitle: 'Para personas que buscan o ofrecen trabajos ocasionales',
                icon: Icons.person,
                onTap: () => _selectPersonal(context),
              ),
              
              const SizedBox(height: 16),
              
              // Botón Empresarial
              _AccountTypeCard(
                title: 'Empresarial',
                subtitle: 'Para empresas que necesitan contratar servicios',
                icon: Icons.business,
                onTap: () => _selectEmpresarial(context),
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

class _AccountTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AccountTypeCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícono
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Subtítulo
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            
            // Flecha
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}