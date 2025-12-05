import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:isste/constants/colors.dart';
import 'package:isste/services/api_service.dart';

class AsignacionTramiteBoton extends StatelessWidget {
  final int tramiteId;
  final String ciudadano;
  final int usuarioId;
  final VoidCallback onAsignacionExitosa;

  const AsignacionTramiteBoton({
    super.key,
    required this.tramiteId,
    required this.ciudadano,
    required this.usuarioId,
    required this.onAsignacionExitosa,
  });

  Future<void> asignarTramite(BuildContext context) async {
    if (ciudadano.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Captura el nombre del ciudadano")),
      );
      return;
    }

    final body = {
      "tramite_id": tramiteId,
      "ciudadano": ciudadano.trim(),
      "usuario_id": usuarioId,
    };

    try {
      final response = await ApiService.postJson(ApiService.asignarTicket, body);

      // Log útil para depurar
      // ignore: avoid_print
      print("POST ${ApiService.asignarTicket} -> ${response.statusCode}\n${response.body}");

      final contentType = response.headers['content-type'] ?? '';

      // Si el servidor no responde JSON, evita jsonDecode y muestra el HTML de error.
      if (!contentType.contains('application/json')) {
        _mostrarError(
          context,
          'Respuesta no-JSON del servidor (status ${response.statusCode}). '
          'Revisa la URL, el método y el backend.\n'
          'Contenido:\n${response.body}',
        );
        return;
      }

      // A partir de aquí es seguro decodificar
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Toleramos distintas llaves que puedas usar en el backend
       final turno = data['turno']?.toString() ?? '-';
       final tramite = data['tramite']?.toString() ?? '-';
       final nombre = data['ciudadano']?.toString() ?? ciudadano;

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.verde626,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Turno Asignado",
              style: TextStyle(
                color: AppColors.dorado465,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Text(
              "Turno: $turno\nTrámite: $tramite\nCiudadano: $nombre",
              style: const TextStyle(
                color: AppColors.dorado465,
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onAsignacionExitosa();
                },
                child: const Text(
                  "Aceptar",
                  style: TextStyle(
                    color: AppColors.dorado465,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        final mensaje = (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'Error al asignar el trámite (status ${response.statusCode}).';
        _mostrarError(context, mensaje);
      }
    } catch (e) {
      _mostrarError(context, 'Error inesperado: $e');
    }
  }

  void _mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Puedes no usar este botón visual si llamas asignarTramite() desde fuera
    return ElevatedButton(
      onPressed: () => asignarTramite(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB9975B),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      ),
      child: const Text(
        'Asignar trámite',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}