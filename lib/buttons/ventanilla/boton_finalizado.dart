import 'package:flutter/material.dart';

class BotonFinalizado extends StatefulWidget {
  final Future<void> Function() onPressed;

  const BotonFinalizado({super.key, required this.onPressed});

  @override
  State<BotonFinalizado> createState() => _BotonFinalizadoState();
}

class _BotonFinalizadoState extends State<BotonFinalizado> {
  bool _cargando = false;

  void _confirmarFinalizado() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B3A34),
          title: const Text(
            '¿Está seguro de finalizar?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Esta acción marcará el ticket como finalizado.',
            style: TextStyle(color: Colors.white70),
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
                Navigator.of(context).pop();

                if (_cargando) return;

                setState(() => _cargando = true);

                try {
                  await widget.onPressed();
                } finally {
                  if (mounted) {
                    setState(() => _cargando = false);
                  }
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: _cargando ? null : _confirmarFinalizado,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B3A34),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF294A43),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _cargando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Finalizado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
