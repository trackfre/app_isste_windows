import 'package:flutter/material.dart';

class BotonFinalizado extends StatelessWidget {
  final VoidCallback onPressed;

  const BotonFinalizado({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1B3A34), // Verde oscuro
                title: const Text(
                  '¿Está seguro de finalizar?',
                  style: TextStyle(color: Colors.white),
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
                      backgroundColor: const Color(0xFFB9975B), // Dorado
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Cierra el diálogo
                      onPressed(); // Ejecuta la acción recibida
                    },
                    child: const Text('Aceptar'),
                  ),
                ],
              );
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B3A34),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'Finalizado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}