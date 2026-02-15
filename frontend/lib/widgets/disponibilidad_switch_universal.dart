// lib/widgets/disponibilidad_switch_universal.dart
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class DisponibilidadSwitchUniversal extends StatefulWidget {
  final User usuario;
  final Function(bool)? onDisponibilidadCambiada;

  const DisponibilidadSwitchUniversal({
    Key? key,
    required this.usuario,
    this.onDisponibilidadCambiada,
  }) : super(key: key);

  @override
  State<DisponibilidadSwitchUniversal> createState() => _DisponibilidadSwitchUniversalState();
}

class _DisponibilidadSwitchUniversalState extends State<DisponibilidadSwitchUniversal> {
  final UserService _userService = UserService();
  bool _isLoading = false;
  late bool _estaDisponible;

  @override
  void initState() {
    super.initState();
    _estaDisponible = _getDisponibilidadActual();
  }

  bool _getDisponibilidadActual() {
    if (widget.usuario.isPersona && widget.usuario.persona != null) {
      return widget.usuario.persona!.disponibilidad == 'ACTIVO';
    } else if (widget.usuario.isEmpresa && widget.usuario.empresa != null) {
      return widget.usuario.empresa!.disponibilidad == 'ACTIVO';
    }
    return false;
  }

  Future<void> _toggleDisponibilidad(bool nuevoValor) async {
    // Prevenir múltiples clics
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      
      if (widget.usuario.isPersona && widget.usuario.persona != null) {
        // Actualizar persona usando función RPC existente
        success = await _userService.actualizarDisponibilidad(
          disponible: nuevoValor,
        );
      } else if (widget.usuario.isEmpresa && widget.usuario.empresa != null) {
        // Actualizar empresa directamente
        success = await _userService.actualizarDisponibilidadEmpresa(
          widget.usuario.empresa!.idEmpresa,
          nuevoValor ? 'ACTIVO' : 'INACTIVO',
        );
      } else {
        success = false;
      }

      if (success) {
        setState(() {
          _estaDisponible = nuevoValor;
          _isLoading = false;
        });

        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Disponibilidad actualizada correctamente',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Callback para notificar el cambio
        widget.onDisponibilidadCambiada?.call(nuevoValor);
      }
    } catch (e) {
      // En caso de error, revertir el estado
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error al actualizar disponibilidad. Intenta de nuevo.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work_outline,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Disponibilidad Laboral',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _estaDisponible 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _estaDisponible 
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _estaDisponible 
                                    ? Colors.green 
                                    : Colors.grey,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              _estaDisponible ? 'Disponible' : 'No Disponible',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _estaDisponible 
                                    ? Colors.green.shade700 
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          _estaDisponible
                              ? 'Recibirás notificaciones de ofertas laborales'
                              : 'No recibirás notificaciones de ofertas laborales',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Switch(
                          value: _estaDisponible,
                          onChanged: _toggleDisponibilidad,
                          activeColor: Colors.green,
                        ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los empleadores podrán ver tu disponibilidad desde tu perfil',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}