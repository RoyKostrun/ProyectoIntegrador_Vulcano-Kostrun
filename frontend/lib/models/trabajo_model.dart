// lib/models/trabajo_model.dart
class TrabajoModel {
  final int id;
  final String titulo;
  final String descripcion;
  final double? salario;
  final String metodoPago;
  final String estado;
  final String urgencia;
  final int empleadorId; // ✅ Cambiado de idUsuario a empleadorId
  
  // Relaciones opcionales
  final Map<String, dynamic>? rubro;
  final Map<String, dynamic>? ubicacion;
  final Map<String, dynamic>? pago;

  TrabajoModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.salario,
    required this.metodoPago,
    required this.estado,
    required this.urgencia,
    required this.empleadorId, // ✅ Cambiado
    this.rubro,
    this.ubicacion,
    this.pago,
  });

  factory TrabajoModel.fromJson(Map<String, dynamic> json) {
    print('🔍 Parseando trabajo: ${json['titulo']} - empleador_id: ${json['empleador_id']}');
    
    return TrabajoModel(
      id: json['id_trabajo'] as int, // ✅ Usa id_trabajo
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      salario: json['salario'] != null 
          ? (json['salario'] as num).toDouble() 
          : null,
      metodoPago: json['metodo_pago']?.toString() ?? '',
      estado: json['estado_publicacion']?.toString() ?? '',
      urgencia: json['urgencia']?.toString() ?? 'ESTANDAR',
      empleadorId: json['empleador_id'] as int, // ✅ Usa empleador_id (sin nullable)
      rubro: json['rubro'] is Map ? json['rubro'] : null,
      ubicacion: json['ubicacion'] is Map ? json['ubicacion'] : null,
      pago: json['pago'] is Map ? json['pago'] : null,
    );
  }

  // Helpers para acceder a las relaciones fácilmente
  String get nombreRubro => rubro?['nombre'] ?? 'Sin rubro';
  String get nombreUbicacion => ubicacion?['nombre'] ?? 'Sin ubicación';
  String get direccionCompleta {
    if (ubicacion == null) return 'Sin dirección';
    return '${ubicacion!['calle']} ${ubicacion!['numero']}, ${ubicacion!['ciudad']}';
  }
  
  double get montoTotal {
    if (pago == null) return 0;
    final monto = pago!['monto'];
    return monto is num ? monto.toDouble() : 0;
  }
  
  String get periodoPago => pago?['periodo']?.toString() ?? '';
}