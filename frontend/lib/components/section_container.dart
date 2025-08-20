// lib/components/section_container.dart
import 'package:flutter/material.dart';

class SectionContainer extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final bool isEnabled;
  final List<Widget> children;

  const SectionContainer({
    Key? key,
    required this.title,
    required this.isCompleted,
    required this.isEnabled,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted 
              ? Colors.green 
              : isEnabled 
                  ? const Color(0xFFC5414B) 
                  : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de sección
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? Colors.black : Colors.grey[400],
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? Colors.green 
                      : isEnabled 
                          ? const Color(0xFFC5414B) 
                          : Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isCompleted 
                      ? Icons.check 
                      : isEnabled 
                          ? Icons.edit 
                          : Icons.lock,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          
          if (!isEnabled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.grey[500], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Completa las secciones anteriores para continuar',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (isEnabled) ...[
            const SizedBox(height: 16),
            ...children,
          ],
        ],
      ),
    );
  }
}