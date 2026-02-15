
// lib/models/categoria_model.dart

class CategoriaModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final DateTime fechaAsignacion;

  CategoriaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.fechaAsignacion,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['rubro']['id_rubro'] ?? 0,
      nombre: json['rubro']['nombre'] ?? '',
      descripcion: json['rubro']['descripcion'],
      fechaAsignacion: json['fecha_asignacion'] != null
          ? DateTime.parse(json['fecha_asignacion'])
          : DateTime.now(),
    );
  }
}