import 'dart:async';
import 'package:flutter/material.dart';

class RecesoButton extends StatelessWidget {
  final VoidCallback onFinalizar;

  const RecesoButton({required this.onFinalizar, super.key});

  void _mostrarVentanaEmergente(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _RecesoDialog(onFinalizar: onFinalizar);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _mostrarVentanaEmergente(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B3A34),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        shape: const StadiumBorder(),
      ),
      child: const Text("Receso"),
    );
  }
}

class _RecesoDialog extends StatefulWidget {
  final VoidCallback onFinalizar;

  const _RecesoDialog({required this.onFinalizar, super.key});

  @override
  State<_RecesoDialog> createState() => _RecesoDialogState();
}

class _RecesoDialogState extends State<_RecesoDialog> {
  int _segundosTranscurridos = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _segundosTranscurridos++;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final segundosRestantes = segundos % 60;
    final segundosStr = segundosRestantes.toString().padLeft(2, '0');
    return '$minutos:$segundosStr';
  }

  @override
  @override
Widget build(BuildContext context) {
  return AlertDialog(
    backgroundColor: const Color(0xFF1B3A34), // color de fondo (azul oscuro)
    title: const Text(
      "Receso en progreso",
      style: TextStyle(color: Color(0xFFB9975B)),
    ),
    content: Text(
      "Tiempo transcurrido: ${_formatearTiempo(_segundosTranscurridos)}",
        style: const TextStyle(color: Color(0xFFB9975B)),
    ),
    actions: [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B3A34), // boton verde oscuro
          foregroundColor: const Color(0xFFB9975B),        ),
        onPressed: () {
          widget.onFinalizar();
          Navigator.of(context).pop();
        },
        child: const Text("Finalizar"),
      ),
    ],
  );
}

}
