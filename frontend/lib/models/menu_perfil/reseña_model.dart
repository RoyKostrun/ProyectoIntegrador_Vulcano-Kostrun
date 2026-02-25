// lib/models/reseña_model.dart

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
    String nombreEmisor = 'Usuario';
    String? fotoPerfil;

    if (json['emisor'] != null) {
      final emisor = json['emisor'];

      // ✅ Manejar tanto List como Map
      dynamic personaRaw = emisor['usuario_persona'];
      dynamic empresaRaw = emisor['usuario_empresa'];

      Map<String, dynamic>? persona;
      Map<String, dynamic>? empresa;

      if (personaRaw is List && personaRaw.isNotEmpty) {
        persona = personaRaw[0] as Map<String, dynamic>;
      } else if (personaRaw is Map<String, dynamic>) {
        persona = personaRaw;
      }

      if (empresaRaw is List && empresaRaw.isNotEmpty) {
        empresa = empresaRaw[0] as Map<String, dynamic>;
      } else if (empresaRaw is Map<String, dynamic>) {
        empresa = empresaRaw;
      }

      if (persona != null) {
        final nombre = persona['nombre']?.toString() ?? '';
        final apellido = persona['apellido']?.toString() ?? '';
        nombreEmisor = '$nombre $apellido'.trim();
        fotoPerfil = persona['foto_perfil_url']?.toString();
        print('👤 Emisor persona: $nombreEmisor | foto: $fotoPerfil');
      } else if (empresa != null) {
        nombreEmisor = empresa['nombre_corporativo']?.toString() ?? 'Empresa';
        fotoPerfil = empresa['logo_url']?.toString();
        print('🏢 Emisor empresa: $nombreEmisor | foto: $fotoPerfil');
      } else {
        print('⚠️ emisor sin persona ni empresa: $emisor');
      }
    } else {
      print('⚠️ json sin emisor: $json');
    }

    String? tituloTrabajo;
    if (json['trabajo'] != null) {
      tituloTrabajo = json['trabajo']['titulo']?.toString();
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
