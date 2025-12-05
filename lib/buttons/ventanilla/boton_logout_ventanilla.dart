import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isste/app_routes.dart';
import 'dart:convert';
import 'package:isste/services/api_service.dart';

class BotonLogoutVentanilla extends StatelessWidget {
  final int usuarioId;

  const BotonLogoutVentanilla({super.key, required this.usuarioId});

  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      final response = await ApiService.postJson(
        ApiService.logout,
        {'usuario_id': usuarioId},
      );

      print('📦 Código: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      try {
        final data = jsonDecode(response.body);
        print('📦 Decodificado: $data');

        if (response.statusCode == 200 && data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          // ✅ Redirige al login de ventanilla
          Navigator.pushReplacementNamed(context, AppRoutes.ventanillas);
        } else {
          _mostrarAlerta(context, data['message'] ?? 'Error al cerrar sesión.');
        }
      } catch (e) {
        print('❌ Error al parsear respuesta: $e');
        _mostrarAlerta(context, 'Respuesta inválida del servidor.');
      }
    } catch (e) {
      print('🔥 Error de conexión al cerrar sesión: $e');
      _mostrarAlerta(context, 'No se pudo conectar con el servidor.');
    }
  }

  void _mostrarAlerta(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aviso'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Cerrar sesión',
      icon: const Icon(Icons.logout, color: Colors.white),
      onPressed: () => _cerrarSesion(context),
    );
  }
}