import 'package:flutter/material.dart';
import 'package:isste/app_routes.dart';
import 'package:isste/services/api_service.dart';

class BotonCerrarSesion extends StatelessWidget {
  final int usuarioId;

  const BotonCerrarSesion({super.key, required this.usuarioId});

  Future<void> cerrarSesion(BuildContext context) async {
    try {
      final response = await ApiService.postJson(
        ApiService.logout,
        {'usuario_id': usuarioId},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión cerrada correctamente')),
        );

        // Navegar a la pantalla de login (ventanilla)
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.ventanillas,
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cerrar sesión')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar al servidor')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text("Cerrar sesión"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => cerrarSesion(context),
    );
  }
}