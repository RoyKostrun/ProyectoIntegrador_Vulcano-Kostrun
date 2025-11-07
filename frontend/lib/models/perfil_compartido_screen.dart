// lib/screens/profile/perfil_compartido_screen.dart

import 'package:flutter/material.dart';
import '../../services/perfil_service.dart';
import '../../models/reseña_model.dart';
import '../../models/categoria_model.dart';

class PerfilCompartidoScreen extends StatefulWidget {
  final int userId;

  const PerfilCompartidoScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<PerfilCompartidoScreen> createState() => _PerfilCompartidoScreenState();
}

class _PerfilCompartidoScreenState extends State<PerfilCompartidoScreen> {
  final PerfilService _perfilService = PerfilService();

  bool _isLoading = true;
  bool _reseniasExpanded = false;
  bool _categoriasExpanded = false;

  Map<String, dynamic>? _perfilData;
  List<ReseniaModel> _resenias = [];
  List<CategoriaModel> _categorias = [];
  Map<String, dynamic> _estadisticas = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      // Cargar todos los datos en paralelo
      final results = await Future.wait([
        _perfilService.obtenerPerfilCompleto(widget.userId),
        _perfilService.obtenerResenias(widget.userId),
        _perfilService.obtenerCategorias(widget.userId),
        _perfilService.obtenerEstadisticas(widget.userId),
      ]);

      setState(() {
        _perfilData = results[0] as Map<String, dynamic>;
        _resenias = (results[1] as List<Map<String, dynamic>>)
            .map((json) => ReseniaModel.fromJson(json))
            .toList();
        _categorias = (results[2] as List<Map<String, dynamic>>)
            .map((json) => CategoriaModel.fromJson(json))
            .toList();
        _estadisticas = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildEstadisticas(),
                    const SizedBox(height: 16),
                    _buildReseniasSection(),
                    const SizedBox(height: 16),
                    _buildCategoriasSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
  Widget _buildHeader() {
      if (_perfilData == null) return const SizedBox();

      final nombre = (_perfilData!['nombre'] ?? '').toString().trim();
      final apellido = (_perfilData!['apellido'] ?? '').toString().trim();
      final username = (_perfilData!['username'] ?? '').toString();
      final fotoPerfil = _perfilData!['foto_perfil_url'];
      final rating = (_perfilData!['puntaje_promedio'] ?? 0.0).toDouble();
      final trabajosRealizados = _perfilData!['cantidad_trabajos_realizados'] ?? 0;

      // ✅ Helper para obtener iniciales de forma segura
      String getIniciales() {
        if (nombre.isEmpty && apellido.isEmpty) return '?';
        if (nombre.isEmpty) return apellido.isNotEmpty ? apellido[0].toUpperCase() : '?';
        if (apellido.isEmpty) return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
        return '${nombre[0]}${apellido[0]}'.toUpperCase();
      }

      // ✅ Helper para obtener nombre completo
      String getNombreCompleto() {
        if (nombre.isEmpty && apellido.isEmpty) return 'Usuario';
        return '$nombre $apellido'.trim();
      }

      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFC5414B), Color(0xFFE85A4F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 32),
            
            // Foto de perfil
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                backgroundImage: fotoPerfil != null
                    ? NetworkImage(fotoPerfil)
                    : null,
                child: fotoPerfil == null
                    ? Text(
                        getIniciales(),  // ✅ Usa el helper seguro
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC5414B),
                        ),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 16),

            // Nombre completo
            Text(
              getNombreCompleto(),  // ✅ Usa el helper seguro
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 4),

            // Username (solo mostrar si existe)
            if (username.isNotEmpty)
              Text(
                '@$username',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),

            const SizedBox(height: 16),

            // Rating y trabajos
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    ' (${_resenias.length} reseñas)',  // ✅ Muestra cantidad de reseñas
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.work_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '$trabajosRealizados trabajos',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      );
    }

  Widget _buildEstadisticas() {
    final trabajosCompletados = _estadisticas['trabajos_completados'] ?? 0;
    final totalPostulaciones = _estadisticas['total_postulaciones'] ?? 0;
    final totalResenias = _estadisticas['total_reseñas'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildEstadisticaCard(
              icon: Icons.check_circle_outline,
              value: '$trabajosCompletados',
              label: 'Completados',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildEstadisticaCard(
              icon: Icons.send_outlined,
              value: '$totalPostulaciones',
              label: 'Postulaciones',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildEstadisticaCard(
              icon: Icons.rate_review_outlined,
              value: '$totalResenias',
              label: 'Resenias',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReseniasSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header del botón
            InkWell(
              onTap: () {
                setState(() => _reseniasExpanded = !_reseniasExpanded);
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.rate_review,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reseñas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${_resenias.length} reseñas disponibles',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _reseniasExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Colors.grey[600],
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),

            // Contenido expandible
            if (_reseniasExpanded) ...[
              const Divider(height: 1),
              if (_resenias.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aún no hay reseñas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _resenias.length,
                  separatorBuilder: (context, index) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    return _buildReseniaCard(_resenias[index]);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReseniaCard(ReseniaModel resenia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la reseña
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFC5414B),
              backgroundImage: resenia.fotoPerfilEmisor != null
                  ? NetworkImage(resenia.fotoPerfilEmisor!)
                  : null,
              child: resenia.fotoPerfilEmisor == null
                  ? Text(
                      resenia.getIniciales(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resenia.nombreEmisor,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _formatFecha(resenia.fecha),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Estrellas
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < resenia.puntuacion ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Trabajo relacionado
        if (resenia.tituloTrabajo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.work, size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    resenia.tituloTrabajo!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        if (resenia.tituloTrabajo != null) const SizedBox(height: 12),

        // Comentario
        if (resenia.comentario != null && resenia.comentario!.isNotEmpty)
          Text(
            resenia.comentario!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),

        // Badge de recomendación
        if (resenia.recomendacion == true) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.thumb_up, size: 14, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Text(
                  'Recomendado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoriasSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header del botón
            InkWell(
              onTap: () {
                setState(() => _categoriasExpanded = !_categoriasExpanded);
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.category,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Categorías',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${_categorias.length} categorías disponibles',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _categoriasExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Colors.grey[600],
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),

            // Contenido expandible
            if (_categoriasExpanded) ...[
              const Divider(height: 1),
              if (_categorias.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aún no hay categorías',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categorias.map((categoria) {
                      return _buildCategoriaChip(categoria);
                    }).toList(),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaChip(CategoriaModel categoria) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC5414B).withOpacity(0.1),
            const Color(0xFFE85A4F).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC5414B).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.work_outline,
            size: 16,
            color: const Color(0xFFC5414B),
          ),
          const SizedBox(width: 6),
          Text(
            categoria.nombre,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC5414B),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diferencia = now.difference(fecha);

    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes}m';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours}h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays}d';
    } else if (diferencia.inDays < 30) {
      final semanas = (diferencia.inDays / 7).floor();
      return 'Hace ${semanas}sem';
    } else if (diferencia.inDays < 365) {
      final meses = (diferencia.inDays / 30).floor();
      return 'Hace ${meses}m';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}