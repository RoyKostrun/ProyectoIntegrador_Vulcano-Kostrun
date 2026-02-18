// lib/widgets/ios_time_picker.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IOSTimePicker extends StatefulWidget {
  final TimeOfDay? initialTime;
  final Function(TimeOfDay) onTimeSelected;
  final String title;

  const IOSTimePicker({
    Key? key,
    this.initialTime,
    required this.onTimeSelected,
    this.title = 'Seleccionar Hora',
  }) : super(key: key);

  @override
  State<IOSTimePicker> createState() => _IOSTimePickerState();
}

class _IOSTimePickerState extends State<IOSTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    final now = widget.initialTime ?? TimeOfDay.now();
    _selectedHour = now.hour;
    _selectedMinute = now.minute;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Color(0xFFC5414B),
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final selectedTime = TimeOfDay(
                      hour: _selectedHour,
                      minute: _selectedMinute,
                    );
                    widget.onTimeSelected(selectedTime);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Listo',
                    style: TextStyle(
                      color: Color(0xFFC5414B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Time Picker Wheels
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hours
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: _selectedHour,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedHour = index;
                      });
                    },
                    children: List.generate(24, (index) {
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Separator
                const Text(
                  ':',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Minutes
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: _selectedMinute,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedMinute = index;
                      });
                    },
                    children: List.generate(60, (index) {
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Current Selection Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFC5414B).withOpacity(0.1),
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFFC5414B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC5414B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function para mostrar el picker
Future<TimeOfDay?> showIOSTimePicker({
  required BuildContext context,
  TimeOfDay? initialTime,
  String title = 'Seleccionar Hora',
}) async {
  TimeOfDay? selectedTime;

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => IOSTimePicker(
      initialTime: initialTime,
      title: title,
      onTimeSelected: (time) {
        selectedTime = time;
      },
    ),
  );

  return selectedTime;
}