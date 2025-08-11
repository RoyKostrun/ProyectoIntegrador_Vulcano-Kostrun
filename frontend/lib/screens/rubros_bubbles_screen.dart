//lib/screens/rubros_bubbles_screen.dart
import 'package:flutter/material.dart';
import '../models/rubro.dart';
import '../services/rubro_service.dart';
import '../services/auth_service.dart'; // 👈 Agregar import
import '../utils/icon_helper.dart';

class RubrosBubblesScreen extends StatefulWidget {
  const RubrosBubblesScreen({Key? key}) : super(key: key);

  @override
  State<RubrosBubblesScreen> createState() => _RubrosBubblesScreenState();
}

class _RubrosBubblesScreenState extends State<RubrosBubblesScreen> {
  Set<int> selectedRubros = {};
  Set<int> hoveredRubros = {};
  List<Rubro> rubros = [];
  bool isLoading = true;
  bool isSaving = false; // 👈 Agregar estado de guardado
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRubros();
  }

  Future<void> _loadRubros() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final loadedRubros = await RubroService.getRubros();
      
      setState(() {
        rubros = loadedRubros;
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _handleBubbleTap(int rubroId) {
    setState(() {
      if (selectedRubros.contains(rubroId)) {
        selectedRubros.remove(rubroId);
      } else {
        selectedRubros.add(rubroId);
      }
    });
  }

  void _handleBubbleHover(int rubroId, bool isHovering) {
    setState(() {
      if (isHovering) {
        hoveredRubros.add(rubroId);
      } else {
        hoveredRubros.remove(rubroId);
      }
    });
  }

  Future<void> _refreshRubros() async {
    await _loadRubros();
  }

  // ✅ MÉTODO PARA CONTINUAR Y GUARDAR RUBROS
  Future<void> _continueWithSelectedRubros() async {
    if (selectedRubros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un rubro'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // Obtener los nombres de los rubros seleccionados
      final nombresSeleccionados = rubros
          .where((r) => selectedRubros.contains(r.id))
          .map((r) => r.nombre)
          .toList();

      print('📋 Guardando rubros: $nombresSeleccionados');

      // Guardar rubros en la base de datos
      await AuthService.saveUserRubros(nombresSeleccionados);
      
      // Marcar onboarding como completado
      await AuthService.markOnboardingCompleted();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Configuración completada! Rubros: ${nombresSeleccionados.join(', ')}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // ✅ NAVEGAR A LA PANTALLA DE INICIO
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/inicio', // 👈 Navegar a la pantalla INICIO
          (route) => false, // Eliminar todas las rutas previas
        );
      }
    } catch (error) {
      print('❌ Error guardando rubros: $error');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF374151),
      appBar: AppBar(
        backgroundColor: const Color(0xFF374151),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: isSaving ? null : () => Navigator.pop(context), // 👈 Deshabilitar si está guardando
        ),
        title: const Text(
          'Selecciona Rubros',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isSaving ? null : _refreshRubros, // 👈 Deshabilitar si está guardando
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack( // 👈 Cambiar a Stack para overlay de loading
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'Explora Nuestros Rubros',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecciona uno o más rubros de tu interés',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Contador de seleccionados
                      if (selectedRubros.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC5414B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${selectedRubros.length} seleccionado${selectedRubros.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _buildContent(),
                ),

                // Bottom Button - ✅ BOTÓN CORREGIDO
                if (selectedRubros.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _continueWithSelectedRubros, // 👈 Método correcto
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC5414B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isSaving
                          ? const Row( // 👈 Mostrar loading cuando está guardando
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Guardando...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Continuar (${selectedRubros.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
            
            // ✅ OVERLAY DE LOADING GENERAL
            if (isSaving)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Completando configuración...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando rubros...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFC5414B),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar los rubros',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshRubros,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5414B),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (rubros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay rubros disponibles',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ GRID EXACTO COMO LA IMAGEN: 3 COLUMNAS, N FILAS
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // EXACTAMENTE 3 COLUMNAS
          crossAxisSpacing: 16, // Espaciado horizontal uniforme
          mainAxisSpacing: 16, // Espaciado vertical uniforme
          childAspectRatio: 1.0, // Círculos perfectos
        ),
        itemCount: rubros.length,
        itemBuilder: (context, index) {
          final rubro = rubros[index];
          final isSelected = selectedRubros.contains(rubro.id);
          final isHovered = hoveredRubros.contains(rubro.id);

          return _buildBubble(rubro, isSelected, isHovered);
        },
      ),
    );
  }

  Widget _buildBubble(Rubro rubro, bool isSelected, bool isHovered) {
    return MouseRegion(
      onEnter: (_) => _handleBubbleHover(rubro.id, true),
      onExit: (_) => _handleBubbleHover(rubro.id, false),
      child: GestureDetector(
        onTap: () => _handleBubbleTap(rubro.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFC5414B)
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFC5414B)
                  : const Color(0xFFE5E7EB),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFFC5414B).withOpacity(0.4)
                    : Colors.black.withOpacity(0.15),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isHovered
                ? _buildDescriptionContent(rubro, isSelected)
                : _buildNormalContent(rubro, isSelected),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalContent(Rubro rubro, bool isSelected) {
    return Column(
      key: const ValueKey('normal'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          IconHelper.getIcon(rubro.iconName),
          size: 42, // Ícono más grande para el círculo más grande
          color: isSelected
              ? Colors.white
              : const Color(0xFFC5414B),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            rubro.nombre,
            style: TextStyle(
              fontSize: 13, // Texto más grande y legible
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFFC5414B),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionContent(Rubro rubro, bool isSelected) {
    return Container(
      key: const ValueKey('description'),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 28,
            color: isSelected
                ? Colors.white
                : const Color(0xFFC5414B),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              child: Text(
                rubro.descripcion,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF374151),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}