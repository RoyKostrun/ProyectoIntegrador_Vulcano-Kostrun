class TrabajoModel {
  final int id;
  final String titulo;
  final String descripcion;
  final double? salario;
  final String metodoPago;
  final String estado;
  final String urgencia;

  TrabajoModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.salario,
    required this.metodoPago,
    required this.estado,
    required this.urgencia,
  });

  factory TrabajoModel.fromJson(Map<String, dynamic> json) {
    return TrabajoModel(
      id: json['id'] as int,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      salario: (json['salario'] as num?)?.toDouble(),
      metodoPago: json['metodo_pago'] ?? '',
      estado: json['estado_publicacion'] ?? '',
      urgencia: json['urgencia'] ?? '',
    );
  }
}
