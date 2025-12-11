import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:isste/services/api_service.dart';

class BotonCambioVentanilla extends StatelessWidget {
  final int ticketId;
  final int tramiteId;
  final void Function(Map<String, dynamic>)? onTicketActualizado;

  const BotonCambioVentanilla({
    super.key,
    required this.ticketId,
    required this.tramiteId,
    this.onTicketActualizado,
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
          foregroundColor: Colors.white,
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

    // 🔥 FIX: evitar valores inválidos como 0
    int? tramiteSeleccionado = (tramiteId == 0) ? null : tramiteId;

    List<dynamic> tramitesDisponibles = [];
    bool cargado = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            // =============================================================
            // 🔥 CARGAR TRÁMITES DEL BACKEND
            // =============================================================
            Future<void> cargarTramites() async {
              try {
                final respuesta =
                    await ApiService.getJson(ApiService.tramitesVigentes);

                if (respuesta.statusCode == 200) {
                  final body = jsonDecode(respuesta.body);

                  if (body is List) {
                    tramitesDisponibles = body;
                  } else if (body is Map && body.containsKey("tramites")) {
                    tramitesDisponibles = body["tramites"];
                  } else {
                    throw Exception("Formato inesperado de respuesta");
                  }

                  setState(() => cargado = true);
                }
              } catch (e) {
                print("❌ Error cargando trámites: $e");
              }
            }

            if (!cargado) cargarTramites();

            return AlertDialog(
              backgroundColor: const Color(0xFF1B3A34),
              title: const Text(
                'Reasignar a nuevo trámite',
                style: TextStyle(color: Colors.white),
              ),

              // =============================================================
              // 🔥 CONTENIDO DEL DIÁLOGO
              // =============================================================
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // =========================================================
                  // 🔥 DROPDOWN DE TRÁMITES
                  // =========================================================
                  DropdownButtonFormField<int>(
                    value: tramitesDisponibles.any((t) => t["id"] == tramiteSeleccionado)
                        ? tramiteSeleccionado
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Seleccione el trámite correcto',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      filled: true,
                      fillColor: Color(0xFF254C47),
                    ),
                    dropdownColor: const Color(0xFF254C47),
                    items: tramitesDisponibles
                        .map<DropdownMenuItem<int>>((t) {
                      return DropdownMenuItem(
                        value: t["id"],
                        child: Text(
                          t["nombre"],
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        tramiteSeleccionado = value;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  // =========================================================
                  // 🔥 CAMPO MOTIVO
                  // =========================================================
                  TextField(
                    controller: motivoController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Motivo del cambio",
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      filled: true,
                      fillColor: Color(0xFF254C47),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),

              // =============================================================
              // 🔥 BOTONES
              // =============================================================
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB9975B),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {

                    if (tramiteSeleccionado == null ||
                        motivoController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecciona el trámite y escribe el motivo.'),
                        ),
                      );
                      return;
                    }

                    final respuesta = await ApiService.putJson(
                      "${ApiService.baseUrl}/api/tickets/reasignar-por-tramite",
                      {
                        "ticket_id": ticketId,
                        "tramite_id": tramiteSeleccionado,
                        "motivo": motivoController.text,
                      },
                    );

                    if (respuesta.statusCode == 200) {
                      final data = jsonDecode(respuesta.body);

                      // si existe ticket actualizado, enviarlo al callback del padre
                      if (onTicketActualizado != null &&
                          data.containsKey("ticket")) {
                        onTicketActualizado!(data["ticket"]);
                      }

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✔ Ticket reasignado."),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("❌ No se pudo reasignar el ticket."),
                        ),
                      );
                    }
                  },
                  child: const Text("Aceptar"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
