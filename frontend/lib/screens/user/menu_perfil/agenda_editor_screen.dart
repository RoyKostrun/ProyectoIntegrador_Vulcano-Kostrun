// lib/screens/user/agenda_editor_screen.dart
// ✅ Editor con checkboxes GRANDES y tocables

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../services/nota_service.dart';
import '../../../models/nota_model.dart';

class AgendaEditorScreen extends StatefulWidget {
  final NotaModel? nota;

  const AgendaEditorScreen({Key? key, this.nota}) : super(key: key);

  @override
  State<AgendaEditorScreen> createState() => _AgendaEditorScreenState();
}

class _AgendaEditorScreenState extends State<AgendaEditorScreen> {
  final NotaService _notaService = NotaService();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _contenidoController = TextEditingController();
  
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _modoChecklist = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.nota != null) {
      _tituloController.text = widget.nota!.titulo;
      _contenidoController.text = widget.nota!.contenido;
      
      if (widget.nota!.contenido.contains('[ ]') || widget.nota!.contenido.contains('[x]')) {
        _modoChecklist = true;
      }
    }
    
    _tituloController.addListener(_onTextChanged);
    _contenidoController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<bool> _guardarNota() async {
    if (_isSaving) return false;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final titulo = _tituloController.text.trim();
      final contenido = _contenidoController.text.trim();

      if (titulo.isEmpty && contenido.isEmpty) {
        setState(() {
          _isSaving = false;
        });
        return true;
      }

      if (widget.nota == null) {
        await _notaService.crearNota(titulo, contenido);
      } else {
        await _notaService.actualizarNota(
          widget.nota!.idNotas!,
          titulo,
          contenido,
        );
      }

      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });

      return true;
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return false;
    }
  }

  Future<void> _onWillPop() async {
    if (_hasChanges) {
      final guardado = await _guardarNota();
      if (guardado && mounted) {
        Navigator.pop(context, true);
      }
    } else {
      Navigator.pop(context, false);
    }
  }

  void _toggleModoChecklist() {
    setState(() {
      _modoChecklist = !_modoChecklist;
      
      if (_modoChecklist && _contenidoController.text.isEmpty) {
        _contenidoController.text = '[ ] ';
        _contenidoController.selection = TextSelection.collapsed(
          offset: _contenidoController.text.length,
        );
      }
    });
  }

  void _onContenidoChanged(String text) {
    if (!_modoChecklist) return;
    
    if (text.endsWith('\n')) {
      final newText = text + '[ ] ';
      _contenidoController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  void _toggleCheckboxEnLinea(int lineIndex) {
    final lines = _contenidoController.text.split('\n');
    
    if (lineIndex >= lines.length) return;
    
    String line = lines[lineIndex];
    
    if (line.startsWith('[ ] ')) {
      lines[lineIndex] = line.replaceFirst('[ ] ', '[x] ');
    } else if (line.startsWith('[x] ')) {
      lines[lineIndex] = line.replaceFirst('[x] ', '[ ] ');
    }
    
    setState(() {
      _contenidoController.text = lines.join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _onWillPop();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 245, 247),
        appBar: AppBar(
          backgroundColor: const Color(0xFFC5414B),
          elevation: 0,
          title: Row(
            children: [
              Text(
                widget.nota == null ? 'Nueva Nota' : 'Editar Nota',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              if (_isSaving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _onWillPop,
          ),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: () async {
                  final guardado = await _guardarNota();
                  if (guardado && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Nota guardada'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                tooltip: 'Guardar',
              ),
          ],
        ),
        body: Column(
          children: [
            // Barra de herramientas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Material(
                    color: _modoChecklist 
                        ? const Color(0xFFC5414B) 
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _toggleModoChecklist,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: _modoChecklist ? Colors.white : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Checklist',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _modoChecklist ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_hasChanges)
                    Text(
                      'Sin guardar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),

            // Editor
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    TextField(
                      controller: _tituloController,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Título',
                        hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
                        border: InputBorder.none,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Contenido con checkboxes interactivos
                    _buildContenidoConCheckboxes(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenidoConCheckboxes() {
    if (!_modoChecklist) {
      // Modo normal sin checkboxes
      return Stack(
        children: [
          CustomPaint(
            painter: LinedPaperPainter(),
            size: Size(
              double.infinity,
              _calcularAlturaContenido(),
            ),
          ),
          TextField(
            controller: _contenidoController,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(
              fontSize: 17,
              height: 2.2,
              color: Color(0xFF424242),
            ),
            decoration: const InputDecoration(
              hintText: '',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: _onContenidoChanged,
            autofocus: widget.nota == null,
          ),
        ],
      );
    }

    // Modo checklist con botones grandes
    final lines = _contenidoController.text.split('\n');
    
    return Stack(
      children: [
        CustomPaint(
          painter: LinedPaperPainter(),
          size: Size(
            double.infinity,
            _calcularAlturaContenido(),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < lines.length; i++)
              _buildLineaConCheckbox(i, lines[i]),
            
            // Campo invisible para agregar nuevas líneas
            SizedBox(
              height: 40,
              child: TextField(
                controller: _contenidoController,
                maxLines: null,
                style: const TextStyle(
                  fontSize: 17,
                  height: 2.2,
                  color: Colors.transparent,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (text) {
                  setState(() {
                    _onContenidoChanged(text);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLineaConCheckbox(int index, String line) {
    bool tieneCheckbox = line.startsWith('[ ] ') || line.startsWith('[x] ');
    bool estaCompletado = line.startsWith('[x] ');
    String texto = tieneCheckbox ? line.substring(4) : line;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (tieneCheckbox)
            GestureDetector(
              onTap: () => _toggleCheckboxEnLinea(index),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: estaCompletado 
                      ? const Color(0xFFC5414B)
                      : Colors.transparent,
                  border: Border.all(
                    color: estaCompletado 
                        ? const Color(0xFFC5414B)
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: estaCompletado
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            ),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 17,
                height: 2.2,
                color: estaCompletado 
                    ? Colors.grey.shade400
                    : const Color(0xFF424242),
                decoration: estaCompletado 
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calcularAlturaContenido() {
    final lineas = '\n'.allMatches(_contenidoController.text).length + 1;
    final alturaMinima = MediaQuery.of(context).size.height - 200;
    final alturaCalculada = lineas * 37.4;
    return alturaCalculada > alturaMinima ? alturaCalculada : alturaMinima;
  }
}

class LinedPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..strokeWidth = 1.0;

    const lineHeight = 37.4;
    
    for (double y = lineHeight; y < size.height; y += lineHeight) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}