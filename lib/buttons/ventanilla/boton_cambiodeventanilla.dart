import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:isste/services/api_service.dart';

class BotonCambioVentanilla extends StatelessWidget {
  final int ticketId;
  final int tramiteId; // ✅ nuevo parámetro

  const BotonCambioVentanilla({
    super.key,
    required this.ticketId,
    required this.tramiteId, // ✅ en el constructor
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _mostrarDialogoCambio(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB9975B),
          foregroundColor: const Color.fromARGB(255, 238, 235, 235),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'Cambio de ventanilla',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _mostrarDialogoCambio(BuildContext context) {
    final TextEditingController motivoController = TextEditingController();
    int? tramiteSeleccionado = tramiteId; // ✅ precarga con el trámite actual
    List<dynamic> tramitesDisponibles = [];
    bool cargado = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> cargarTramites() async {
              try {
                final respuesta = await ApiService.getJson(ApiService.tramitesVigentes);
                if (respuesta.statusCode == 200) {
                  setState(() {
                    tramitesDisponibles = jsonDecode(respuesta.body);
                    cargado = true;
                  });
                } else {
                  throw Exception('No se pudieron cargar los trámites');
                }
              } catch (e) {
                print('❌ Error cargando trámites: $e');
              }
            }

            if (!cargado) cargarTramites();

            return AlertDialog(
              backgroundColor: const Color(0xFF1B3A34),
              title: const Text(
                'Reasignar a nuevo trámite',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: tramiteSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Seleccione el trámite correcto',
                      border: const OutlineInputBorder(),
                      labelStyle: const TextStyle(color: Colors.white),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF254C47),
                    ),
                    style: const TextStyle(color: Color(0xFFB9975B)),
                    items: tramitesDisponibles.map<DropdownMenuItem<int>>((t) {
                      return DropdownMenuItem(
                        value: t['id'],
                        child: Text(t['nombre']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        tramiteSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: motivoController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Motivo del cambio',
                      border: const OutlineInputBorder(),
                      labelStyle: const TextStyle(color: Colors.white),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFB9975B)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF254C47),
                    ),
                    style: const TextStyle(color: Color(0xFFB9975B)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB9975B),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (tramiteSeleccionado != null &&
                        motivoController.text.isNotEmpty) {
                      final respuesta = await ApiService.putJson(
                        '${ApiService.baseUrl}/api/tickets/reasignar-por-tramite',
                        {
                          'ticket_id': ticketId,
                          'tramite_id': tramiteSeleccionado,
                        },
                      );

                      if (respuesta.statusCode == 200) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Ticket reasignado exitosamente.'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ No se pudo reasignar el ticket.'),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecciona el trámite y escribe el motivo.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}