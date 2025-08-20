// lib/utils/icon_helper.dart
import 'package:flutter/material.dart';

class IconHelper {
  static const Map<String, IconData> _iconMap = {
    'cleaning_services': Icons.cleaning_services,
    'grass': Icons.grass,
    'child_care': Icons.child_care,
    'elderly': Icons.elderly,
    'delivery_dining': Icons.delivery_dining,
    'construction': Icons.construction,
    'electrical_services': Icons.electrical_services,
    'plumbing': Icons.plumbing,
    'format_paint': Icons.format_paint,
    'local_shipping': Icons.local_shipping,
    'event': Icons.event,
    'restaurant': Icons.restaurant,
    'pets': Icons.pets,
    'computer': Icons.computer,
    'school': Icons.school,
    'work': Icons.work,
  };

  static IconData getIcon(String iconName) {
    return _iconMap[iconName] ?? Icons.work;
  }

  static List<String> getAllIconNames() {
    return _iconMap.keys.toList();
  }
}
