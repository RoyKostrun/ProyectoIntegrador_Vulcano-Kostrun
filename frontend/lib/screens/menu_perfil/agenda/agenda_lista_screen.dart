// lib/screens/user/menu_perfil/agenda_lista_screen.dart
// ✅ Pantalla principal de Agenda - Lista de notas

import 'package:flutter/material.dart';
import '../../../services/menu_perfil/nota_service.dart';
import '../../../models/menu_perfil/nota_model.dart';
import 'agenda_editor_screen.dart';

class AgendaListaScreen extends StatefulWidget {
  const AgendaListaScreen({Key? key}) : super(key: key);

  @override
  State<AgendaListaScreen> createState() => _AgendaListaScreenState();
}

class _AgendaListaScreenState extends State<AgendaListaScreen> {
  final NotaService _notaService = NotaService();
  List<NotaModel> _notas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarNotas();
  }

  Future<void> _cargarNotas() async {
    setState(() {
      isLoading = true;
    });

    try {
      final notas = await _notaService.getNotasUsuario();
      
      setState(() {
        _notas = notas;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar notas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _crearNuevaNota() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AgendaEditorScreen(),
      ),
    );

    if (resultado == true) {
      _cargarNotas();
    }
  }

  Future<void> _abrirNota(NotaModel nota) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgendaEditorScreen(nota: nota),
      ),
    );

    if (resultado == true) {
      _cargarNotas();
    }
  }

  Future<void> _eliminarNota(NotaModel nota) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: Text('¿Estás seguro de eliminar "${nota.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _notaService.eliminarNota(nota.idNotas!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Nota eliminada'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        _cargarNotas();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getPreview(String contenido) {
    if (contenido.isEmpty) return 'Sin contenido';
    
    // Tomar las primeras 2 líneas o 100 caracteres
    final lineas = contenido.split('\n');
    final preview = lineas.take(2).join('\n');
    
    if (preview.length > 100) {
      return '${preview.substring(0, 100)}...';
    }
    
    return preview;
  }

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);
    
    if (diff.inMinutes < 1) {
      return 'Hace un momento';
    } else if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays}d';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 176, 181),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        title: const Text(
          'Mi Agenda',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
              ),
            )
          : _notas.isEmpty
              ? _buildEmptyState()
              : _buildNotasList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearNuevaNota,
        backgroundColor: const Color(0xFFC5414B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Nota',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_outlined,
            size: 100,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'No tienes notas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera nota',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _crearNuevaNota,
            icon: const Icon(Icons.add),
            label: const Text('Crear Nota'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5414B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotasList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notas.length,
      itemBuilder: (context, index) {
        final nota = _notas[index];
        return _buildNotaCard(nota);
      },
    );
  }

  Widget _buildNotaCard(NotaModel nota) {
    return Dismissible(
      key: Key(nota.idNotas.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar nota'),
            content: Text('¿Estás seguro de eliminar "${nota.titulo}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          await _notaService.eliminarNota(nota.idNotas!);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Nota eliminada'),
                backgroundColor: Colors.green,
              ),
            );
          }
          
          _cargarNotas();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al eliminar: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: GestureDetector(
        onTap: () => _abrirNota(nota),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nota.titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getPreview(nota.contenido),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatFecha(nota.fechaModificacion),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}