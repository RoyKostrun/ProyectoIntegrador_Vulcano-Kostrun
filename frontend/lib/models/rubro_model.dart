// lib/models/rubro_model.dart
import 'dart:math';

class Rubro {
  final int idRubro; // ✅ Cambiado de 'id' a 'idRubro'
  final String nombre;
  final String descripcion;
  final String iconName;
  final String size;
  final Map<String, double> position;

  Rubro({
    required this.idRubro, // ✅ Cambiado
    required this.nombre,
    required this.descripcion,
    required this.iconName,
    required this.size,
    required this.position,
  });

  factory Rubro.fromMap(Map<String, dynamic> map) {
    return Rubro(
      idRubro: map['id_rubro'], // ✅ Mapea a idRubro
      nombre: map['nombre'],
      descripcion: map['descripcion'] ?? '',
      iconName: _getDefaultIcon(map['nombre']),
      size: _getRandomSize(),
      position: _generateRandomPosition(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_rubro': idRubro, // ✅ Usa el nombre correcto de la columna
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }

  // Método para obtener ícono basado en el nombre del rubro
  static String _getDefaultIcon(String nombre) {
    final iconMap = {
      'limpieza': 'cleaning_services',
      'jardinería': 'grass',
      'jardineria': 'grass',
      'cuidado de niños': 'child_care',
      'cuidado de niños': 'child_care',
      'cuidado de adultos mayores': 'elderly',
      'delivery': 'delivery_dining',
      'construcción': 'construction',
      'construccion': 'construction',
      'electricidad': 'electrical_services',
      'plomería': 'plumbing',
      'plomeria': 'plumbing',
      'pintura': 'format_paint',
      'mudanzas': 'local_shipping',
      'eventos': 'event',
      'cocina': 'restaurant',
      'mascotas': 'pets',
      'tecnología': 'computer',
      'tecnologia': 'computer',
      'educación': 'school',
      'educacion': 'school',
    };
    
    return iconMap[nombre.toLowerCase()] ?? 'work';
  }

  static String _getRandomSize() {
    final sizes = ['small', 'medium', 'large'];
    final random = Random();
    return sizes[random.nextInt(sizes.length)];
  }

  static Map<String, double> _generateRandomPosition() {
    final random = Random();
    return {
      'x': (random.nextInt(70) + 15) / 100.0,
      'y': (random.nextInt(60) + 20) / 100.0,
    };
  }

  @override
  String toString() {
    return 'Rubro{idRubro: $idRubro, nombre: $nombre, descripcion: $descripcion}';
  }
}