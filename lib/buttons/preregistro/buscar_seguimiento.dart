import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:isste/services/api_service.dart';

/// =============================================================
/// DIÁLOGO: Buscar y reactivar seguimientos (PREREGISTRO)
/// =============================================================
/// - GET  /api/seguimientos/buscar?q=...
/// - POST /api/preregistro/reactivar-seguimiento   { ticket_id }
///
/// onSuccess(result) → recibe la respuesta del backend:
///   { turno_visible, ventanilla, tramite, ciudadano, ... }
class BuscarSeguimientoDialog extends StatefulWidget {
  final void Function(Map<String, dynamic> result)? onSuccess;
  final String initialQuery;

  const BuscarSeguimientoDialog({
    super.key,
    this.onSuccess,
    this.initialQuery = '',
  });

  @override
  State<BuscarSeguimientoDialog> createState() =>
      _BuscarSeguimientoDialogState();
}

class _BuscarSeguimientoDialogState extends State<BuscarSeguimientoDialog> {
  final TextEditingController _qCtrl = TextEditingController();

  bool _loading = false;
  bool _reactivando = false;

  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _qCtrl.text = widget.initialQuery;
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  // =============================================================
  // 🔥 BUSCAR seguimiento en el backend
  // GET /api/seguimientos/buscar?q=...
  // =============================================================
  Future<void> _buscar() async {
    final q = _qCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _error = 'Ingresa turno, nombre o CURP.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _items = [];
    });

    try {
      final url =
          "${ApiService.baseUrl}/api/seguimientos/buscar?q=$q";

      final respuesta = await ApiService.getJson(url);

      if (respuesta.statusCode == 200) {
        final data = jsonDecode(respuesta.body);
        final list = (data['seguimientos'] ?? []) as List<dynamic>;

        setState(() {
          _items = list;
          if (_items.isEmpty) _error = 'Sin resultados para “$q”.';
        });
      } else {
        setState(() => _error =
            "No se pudo buscar (${respuesta.statusCode}).");
      }
    } catch (e) {
      setState(() => _error = "Error de conexión: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =============================================================
  // 🔥 REACTIVAR seguimiento desde preregistro
  // POST /api/preregistro/reactivar-seguimiento
  // Body: { ticket_id }
  // =============================================================
  Future<void> _reactivar(Map<String, dynamic> seg) async {
    setState(() {
      _reactivando = true;
      _error = null;
    });

    try {
      final ticketId = seg['ticket_id'] ?? seg['id'];

      if (ticketId == null) {
        setState(() => _error = 'Error: seguimiento sin ticket_id.');
        return;
      }

      final url =
          "${ApiService.baseUrl}/api/preregistro/reactivar-seguimiento";

      final respuesta = await ApiService.postJson(url, {
        'ticket_id': ticketId,
      });

      if (respuesta.statusCode == 200) {
        final result = jsonDecode(respuesta.body);
        widget.onSuccess?.call(result);

        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() => _error =
            "No se pudo reactivar (${respuesta.statusCode}).");
      }
    } catch (e) {
      setState(() => _error = "Error de conexión: $e");
    } finally {
      if (mounted) setState(() => _reactivando = false);
    }
  }

  // =============================================================
  // UI
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Buscar seguimiento"),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 10),

            if (_error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 6),

            _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _buildResults(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _reactivando ? null : () => Navigator.pop(context, false),
          child: const Text("Cerrar"),
        ),
        FilledButton(
          onPressed: _loading ? null : _buscar,
          child: const Text("Buscar"),
        ),
      ],
    );
  }

  // =============================================================
  // Barra de búsqueda
  // =============================================================
  Widget _buildSearchBar() {
    return TextField(
      controller: _qCtrl,
      onChanged: (_) => setState(() => _error = null),
      onSubmitted: (_) => _buscar(),
      decoration: const InputDecoration(
        hintText: "Turno, nombre o CURP…",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
      ),
    );
  }

  // =============================================================
  // Lista de resultados
  // =============================================================
  Widget _buildResults() {
    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text("Sin resultados"),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 340),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final s = _items[i] as Map<String, dynamic>;

          final turno = (s["turno"] ?? "-").toString();
          final tramite = (s["tramite"] ?? "-").toString();
          final ciudadano = (s["ciudadano"] ?? "-").toString();
          final fecha = (s["fecha"] ?? "").toString();

          return ListTile(
            leading: const Icon(Icons.history),
            title: Text("$turno — $tramite"),
            subtitle: Text("Ciudadano: $ciudadano • Desde: $fecha"),
            trailing: ElevatedButton(
              onPressed: _reactivando ? null : () => _reactivar(s),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _reactivando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Reactivar"),
            ),
          );
        },
      ),
    );
  }
}
