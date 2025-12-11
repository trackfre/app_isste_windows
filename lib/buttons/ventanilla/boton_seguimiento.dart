import 'package:flutter/material.dart';
import 'package:isste/services/api_service.dart';

class BotonSeguimiento extends StatelessWidget {
  final String turno;
  final String tramite;
  final String ciudadano;

  /// ID del ticket actual (recomendado, así no dependemos solo del turno)
  final int? ticketId;

  /// ID del usuario ventanilla que genera el seguimiento
  final int usuarioId;

  /// Se ejecuta cuando el seguimiento se crea con éxito (para recargar / tomar siguiente)
  final VoidCallback? onSuccess;

  const BotonSeguimiento({
    super.key,
    required this.turno,
    required this.tramite,
    required this.ciudadano,
    required this.usuarioId,
    this.ticketId,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => _SeguimientoFormDialog(
              turno: turno,
              tramite: tramite,
              ciudadano: ciudadano,
              usuarioId: usuarioId,
              ticketId: ticketId,
              onSuccess: onSuccess,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD6C4A8),
          foregroundColor: const Color(0xFF1B3A34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'Seguimiento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// ===============================
///  DIALOG + LÓGICA DEL SEGUIMIENTO
/// ===============================
class _SeguimientoFormDialog extends StatefulWidget {
  final String turno;
  final String tramite;
  final String ciudadano;
  final int? ticketId;
  final int usuarioId;
  final VoidCallback? onSuccess;

  const _SeguimientoFormDialog({
    required this.turno,
    required this.tramite,
    required this.ciudadano,
    required this.usuarioId,
    this.ticketId,
    this.onSuccess,
  });

  @override
  State<_SeguimientoFormDialog> createState() =>
      _SeguimientoFormDialogState();
}

class _SeguimientoFormDialogState extends State<_SeguimientoFormDialog> {
  final TextEditingController _motivoCtrl = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final motivo = _motivoCtrl.text.trim();
    if (motivo.isEmpty) {
      setState(() => _error = 'Por favor, ingresa un motivo.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      // Payload hacia el backend
      final payload = <String, dynamic>{
        'motivo': motivo,
        'usuario_id': widget.usuarioId,
        if (widget.ticketId != null) 'ticket_id': widget.ticketId,
        if (widget.ticketId == null) 'turno': widget.turno,
      };

      // 🔥 Ruta propuesta para seguimiento:
      // POST /api/seguimiento/crear
      final url = '${ApiService.baseUrl}/api/seguimientos/crear';

      final respuesta = await ApiService.postJson(url, payload);

      if (respuesta.statusCode == 200) {
        // Mensaje visual
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Seguimiento generado exitosamente'),
          ),
        );

        // Callback para que ventanilla pueda tomar siguiente ticket si así lo quieres
        widget.onSuccess?.call();

        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() => _error =
            'No se pudo generar el seguimiento (${respuesta.statusCode}).');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Generar seguimiento'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dato('Turno', widget.turno),
            _dato('Trámite', widget.tramite),
            _dato('Ciudadano', widget.ciudadano),
            const SizedBox(height: 10),
            TextField(
              controller: _motivoCtrl,
              maxLines: 3,
              enabled: !_sending,
              decoration: const InputDecoration(
                labelText: 'Motivo del seguimiento',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _sending ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF627254),
          ),
          child: _sending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _dato(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(v),
        ],
      ),
    );
  }
}