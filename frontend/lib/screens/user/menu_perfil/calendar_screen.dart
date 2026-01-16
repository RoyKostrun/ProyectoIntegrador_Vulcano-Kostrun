// lib/screens/user/menu_perfil/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../services/calendario_service.dart';
import '../../../models/trabajo_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<Map<String, dynamic>>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  Map<DateTime, List<Map<String, dynamic>>> _eventos = {};
  bool _isLoading = true;
  String _filtroActivo = 'TODOS'; // TODOS, PROPIOS, POSTULACIONES

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _cargarEventos();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _cargarEventos() async {
    setState(() => _isLoading = true);

    try {
      final data = await CalendarioService.getEventosMes(_focusedDay);
      setState(() {
        _eventos = data['eventos'] as Map<DateTime, List<Map<String, dynamic>>>;
        _isLoading = false;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar eventos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dayNormalized = DateTime(day.year, day.month, day.day);
    final eventos = _eventos[dayNormalized] ?? [];

    // Aplicar filtro
    if (_filtroActivo == 'PROPIOS') {
      return eventos.where((e) => e['tipo'] == 'PROPIO').toList();
    } else if (_filtroActivo == 'POSTULACIONES') {
      return eventos.where((e) => e['tipo'] == 'POSTULACION').toList();
    }
    
    return eventos;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);

      // Mostrar bottom sheet con eventos del día
      if (_selectedEvents.value.isNotEmpty) {
        _mostrarEventosDia(selectedDay);
      }
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _cargarEventos();
  }

  void _cambiarFiltro(String nuevoFiltro) {
    setState(() {
      _filtroActivo = nuevoFiltro;
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
  }

  void _mostrarEventosDia(DateTime dia) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event,
                      color: Color(0xFFC5414B),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatearFecha(dia),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_selectedEvents.value.length} evento${_selectedEvents.value.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Lista de eventos
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _selectedEvents.value.length,
                  itemBuilder: (context, index) {
                    final evento = _selectedEvents.value[index];
                    return _buildEventoCard(evento);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} ${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        title: const Text(
          'Calendario',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarEventos,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildFiltroChip('TODOS', 'Todos'),
                const SizedBox(width: 8),
                _buildFiltroChip('PROPIOS', 'Mis Trabajos'),
                const SizedBox(width: 8),
                _buildFiltroChip('POSTULACIONES', 'Postulaciones'),
              ],
            ),
          ),

          // Calendario
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar<Map<String, dynamic>>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: 'es_ES',
              
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: Colors.red),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFFC5414B).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFFC5414B),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Color(0xFFC5414B),
                  shape: BoxShape.circle,
                ),
              ),
              
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              onDaySelected: _onDaySelected,
              onPageChanged: _onPageChanged,
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },

              // Personalizar markers con colores específicos por estado
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;

                  final eventosDelDia = events.cast<Map<String, dynamic>>();
                  
                  // ✅ Agrupar por estado para mostrar múltiples colores
                  final colores = <Color>{};
                  
                  for (var evento in eventosDelDia) {
                    final isPasado = evento['isPasado'] == true;
                    final tipo = evento['tipo'];
                    final estado = evento['estado']?.toString().toUpperCase() ?? '';
                    
                    if (isPasado) {
                      colores.add(Colors.grey);
                    } else if (tipo == 'PROPIO') {
                      // Trabajos propios - diferentes colores por estado
                      if (estado == 'PUBLICADO') {
                        colores.add(const Color(0xFF4CAF50)); // Verde
                      } else if (estado == 'EN_PROGRESO') {
                        colores.add(const Color(0xFFFF9800)); // Naranja
                      } else {
                        colores.add(const Color(0xFF4CAF50)); // Verde por defecto
                      }
                    } else if (tipo == 'POSTULACION') {
                      colores.add(const Color(0xFF2196F3)); // Azul
                    }
                  }

                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: colores.map((color) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      )).toList(),
                    ),
                  );
                },
              ),
            ),
          ),

          // Leyenda de colores - MEJORADA Y COMPLETA
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leyenda de Colores',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildLeyendaItem(
                      const Color(0xFF4CAF50), 
                      'Publicado (Activo)',
                    ),
                    _buildLeyendaItem(
                      const Color(0xFFFF9800), 
                      'En Progreso',
                    ),
                    _buildLeyendaItem(
                      const Color(0xFF2196F3), 
                      'Postulación',
                    ),
                    _buildLeyendaItem(
                      Colors.grey, 
                      'Pasado/Vencido/Completo',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de eventos del día seleccionado
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: _selectedEvents,
                    builder: (context, eventos, _) {
                      if (eventos.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay eventos este día',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: eventos.length,
                        itemBuilder: (context, index) {
                          return _buildEventoCard(eventos[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String valor, String label) {
    final isSelected = _filtroActivo == valor;
    
    return GestureDetector(
      onTap: () => _cambiarFiltro(valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC5414B) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLeyendaItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEventoCard(Map<String, dynamic> evento) {
    final esPropio = evento['tipo'] == 'PROPIO';
    final isPasado = evento['isPasado'] ?? false;
    final estado = evento['estado']?.toString().toUpperCase() ?? 'PUBLICADO';
    
    // ✅ Colores específicos por estado
    Color color;
    if (isPasado) {
      color = Colors.grey;
    } else if (esPropio) {
      // Trabajos propios
      if (estado == 'PUBLICADO') {
        color = const Color(0xFF4CAF50); // Verde
      } else if (estado == 'EN_PROGRESO') {
        color = const Color(0xFFFF9800); // Naranja
      } else {
        color = const Color(0xFF4CAF50); // Verde por defecto
      }
    } else {
      // Postulaciones
      color = const Color(0xFF2196F3); // Azul
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // ✅ CORREGIDO: Navegar correctamente según el tipo
            if (esPropio) {
              // Trabajo propio → pantalla de detalle propio
              Navigator.pushNamed(
                context,
                '/detalle-trabajo-propio',
                arguments: evento['id'],
              );
            } else {
              // Postulación → pantalla de detalle normal
              Navigator.pushNamed(
                context,
                '/detalle-trabajo',
                arguments: evento['id'],
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador de tipo
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo y estado
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              esPropio ? 'PROPIO' : 'POSTULACIÓN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Badge de estado específico
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              estado,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (isPasado) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PASADO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Título del trabajo
                      Text(
                        evento['titulo'] ?? 'Sin título',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Ícono de navegación
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}