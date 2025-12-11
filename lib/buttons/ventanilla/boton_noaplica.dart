import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BotonNoAplica extends StatelessWidget {
  final int ticketId;
  final int usuarioId;
  final Function(Map<String, dynamic>? nuevoTicket) onNextTicket;

  const BotonNoAplica({
    super.key,
    required this.ticketId,
    required this.usuarioId,
    required this.onNextTicket,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          final TextEditingController motivoController =
              TextEditingController();

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF941E32),
                title: const Text(
                  '¿Cancelar turno?',
                  style: TextStyle(color: Colors.white),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Escriba el motivo de la cancelación:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: motivoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Ej. Documentación incompleta',
                        hintStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB9975B),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();

                      final motivo = motivoController.text.trim().isEmpty
                          ? "Cancelado sin motivo"
                          : motivoController.text.trim();

                      await _cancelar(context, motivo);
                    },
                    child: const Text('Confirmar'),
                  ),
                ],
              );
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF941E32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'No Aplica',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // =====================================================
  //   🔥 CANCELAR TICKET en backend
  // =====================================================
  Future<void> _cancelar(BuildContext context, String motivo) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.20:5000/api/tickets/cancelar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "ticket_id": ticketId,
          "usuario_id": usuarioId,
          "motivo": motivo,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        onNextTicket(data["siguiente"]);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Turno cancelado correctamente"),
              backgroundColor: Colors.green,
            ),
          );
        }

      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${response.body}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error de conexión: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}