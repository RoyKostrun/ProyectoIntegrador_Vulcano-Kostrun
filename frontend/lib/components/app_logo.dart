// lib/components/app_logo.dart
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool isDarkBackground; // ← NUEVO PARÁMETRO
  
  const AppLogo({
    Key? key, 
    this.size = 80,
    this.isDarkBackground = false, // ← NUEVO PARÁMETRO
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            // ← CAMBIO: Fondo bordó cuando está en fondo negro
            color: isDarkBackground ? const Color(0xFFC5414B) : Colors.white,
            borderRadius: BorderRadius.circular(size * 0.2),
            border: Border.all(
              // ← CAMBIO: Borde blanco cuando está en fondo negro
              color: isDarkBackground ? Colors.white : const Color(0xFFC5414B),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkBackground 
                    ? Colors.black.withOpacity(0.3) // ← CAMBIO: Sombra negra
                    : const Color(0xFFC5414B).withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.2),
            child: Image.asset(
              'assets/images/changapp_logo.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: isDarkBackground ? const Color(0xFFC5414B) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(size * 0.2),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.business, // ← CAMBIO: Ícono más apropiado
                      size: size * 0.5,
                      color: Colors.white, // ← CAMBIO: Siempre blanco
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ChangApp', // ← YA ESTÁ CORRECTO
          style: TextStyle(
            fontSize: 28, // ← CAMBIO: Más grande como pediste
            fontWeight: FontWeight.bold,
            color: isDarkBackground ? Colors.white : Colors.black, // ← CAMBIO: Color según fondo
            letterSpacing: 1.2, // ← CAMBIO: Espaciado para elegancia
          ),
        ),
        const SizedBox(height: 8), // ← NUEVO
        Text(
          'Polo 52 - Parque industrial', // ← NUEVO SUBTÍTULO
          style: TextStyle(
            fontSize: 14,
            color: isDarkBackground 
                ? Colors.white.withOpacity(0.7) 
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}