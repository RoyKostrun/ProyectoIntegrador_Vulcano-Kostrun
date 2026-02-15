// lib/models/perfil_models.dart

// ========================================
// 📝 MODELO DE RESEÑA
// ========================================
class ReseniaModel {
  final int id;
  final int puntuacion;
  final String? comentario;
  final bool? recomendacion;
  final DateTime fecha;
  final String nombreEmisor;
  final String? fotoPerfilEmisor;
  final String? tituloTrabajo;

  ReseniaModel({
    required this.id,
    required this.puntuacion,
    this.comentario,
    this.recomendacion,
    required this.fecha,
    required this.nombreEmisor,
    this.fotoPerfilEmisor,
    this.tituloTrabajo,
  });

  factory ReseniaModel.fromJson(Map<String, dynamic> json) {
    // Obtener nombre del emisor (puede ser persona o empresa)
    String nombreEmisor = 'Usuario';
    String? fotoPerfil;

    if (json['emisor'] != null) {
      final emisor = json['emisor'];
      if (emisor['usuario_persona'] != null && emisor['usuario_persona'].isNotEmpty) {
        final persona = emisor['usuario_persona'][0];
        nombreEmisor = '${persona['nombre']} ${persona['apellido']}';
        fotoPerfil = persona['foto_perfil_url'];
      } else if (emisor['usuario_empresa'] != null && emisor['usuario_empresa'].isNotEmpty) {
        final empresa = emisor['usuario_empresa'][0];
        nombreEmisor = empresa['nombre_corporativo'];
      }
    }

    // Obtener título del trabajo
    String? tituloTrabajo;
    if (json['trabajo'] != null) {
      tituloTrabajo = json['trabajo']['titulo'];
    }

    return ReseniaModel(
      id: json['id_calificacion'] ?? 0,
      puntuacion: json['puntuacion'] ?? 0,
      comentario: json['comentario'],
      recomendacion: json['recomendacion'],
      fecha: json['fecha'] != null 
          ? DateTime.parse(json['fecha']) 
          : DateTime.now(),
      nombreEmisor: nombreEmisor,
      fotoPerfilEmisor: fotoPerfil,
      tituloTrabajo: tituloTrabajo,
    );
  }

  String getIniciales() {
    final palabras = nombreEmisor.split(' ');
    if (palabras.length >= 2) {
      return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
    }
    return nombreEmisor.substring(0, 1).toUpperCase();
  }
}

// ========================================
// 🏷️ MODELO DE CATEGORÍA
// ========================================
class CategoriaModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? icono;

  CategoriaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.icono,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id_categoria'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      icono: json['icono'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_categoria': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
    };
  }
}