import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:isste/constants/colors.dart';
import 'package:isste/services/api_service.dart';

/// =============================================================
///  PANEL: Tickets en Seguimiento (Administración)
/// =============================================================
class TramiteSeguimientoBoton extends StatefulWidget {
  const TramiteSeguimientoBoton({super.key});

  @override
  State<TramiteSeguimientoBoton> createState() =>
      _TramiteSeguimientoBotonState();
}

class _TramiteSeguimientoBotonState extends State<TramiteSeguimientoBoton> {
  final TextEditingController _buscarCtrl = TextEditingController();

  bool _loading = true;
  List<dynamic> _items = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPendientes();
  }

  // =============================================================
  // 🔥 Cargar seguimientos pendientes
  // =============================================================
  Future<void> _cargarPendientes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final query = _buscarCtrl.text.trim();

      // URL del backend
      String url = "${ApiService.baseUrl}/api/seguimientos/pendientes";

      // Si hay búsqueda
      if (query.isNotEmpty) url += "?q=$query";

      final respuesta = await ApiService.getJson(url);

      if (respuesta.statusCode == 200) {
        final data = jsonDecode(respuesta.body);

        // 🔥 FIX IMPORTANTE:
        // El backend puede devolver "pendientes" o "seguimientos".
        // Aseguramos compatibilidad flexible.
        setState(() {
          _items = data["pendientes"] ??
                   data["seguimientos"] ??
                   [];
        });

      } else {
        setState(() {
          _items = [];
          _error = "No se pudo obtener la lista (${respuesta.statusCode}).";
        });
      }
    } catch (e) {
      setState(() {
        _items = [];
        _error = "Error de conexión: $e";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  // =============================================================
  // UI
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeaderBar(),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarPendientes,
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // Encabezado con búsqueda
  // =============================================================
  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.guinda7421.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 2),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: AppColors.guinda7421),
          const SizedBox(width: 8),

          const Expanded(
            child: Text(
              "Tickets en Seguimiento",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),

          // 🔍 Campo de búsqueda
          SizedBox(
            width: 260,
            child: TextField(
              controller: _buscarCtrl,
              onSubmitted: (_) => _cargarPendientes(),
              decoration: InputDecoration(
                isDense: true,
                hintText: "Buscar por turno o ciudadano…",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          FilledButton.icon(
            onPressed: _cargarPendientes,
            icon: const Icon(Icons.refresh),
            label: const Text("Actualizar"),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // Cuerpo principal
  // =============================================================
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(child: Text("Sin tickets en seguimiento."));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final s = _items[i];

        final turno = s["turno"] ?? "-";
        final tramite = s["tramite"] ?? "-";
        final ciudadano = s["ciudadano"] ?? "-";
        final fecha = _formateaFecha(s["fecha"]);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.guinda7421.withOpacity(0.35),
              width: 1.1,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                offset: Offset(0, 2),
                color: Color(0x11000000),
              ),
            ],
          ),
          child: ListTile(
            title: Text(
              "$turno — $tramite",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text("Ciudadano: $ciudadano\nDesde: $fecha"),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _mostrarDetalle(s),
          ),
        );
      },
    );
  }

  // =============================================================
  // Detalle del seguimiento
  // =============================================================
  void _mostrarDetalle(Map<String, dynamic> s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.guinda7421),
                  const SizedBox(width: 8),
                  const Text(
                    "Detalle de seguimiento",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _dato("Turno", s["turno"] ?? "-"),
              _dato("Trámite", s["tramite"] ?? "-"),
              _dato("Ciudadano", s["ciudadano"] ?? "-"),
              _dato("Fecha creación", _formateaFecha(s["fecha"])),

              const SizedBox(height: 14),
              const Text(
                "Próximamente: Reactivar / Archivar",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dato(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              etiqueta,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }

  // =============================================================
  // Formateo de fecha seguro
  // =============================================================
  String _formateaFecha(dynamic iso) {
    try {
      if (iso == null) return "-";

      final dt = DateTime.tryParse(iso.toString());
      if (dt == null) return iso.toString();

      return "${_dos(dt.day)}/${_dos(dt.month)}/${dt.year} "
          "${_dos(dt.hour)}:${_dos(dt.minute)}";
    } catch (_) {
      return iso.toString();
    }
  }

  String _dos(int n) => n.toString().padLeft(2, "0");
}
