import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:isste/services/api_service.dart';

class ActualizacionTramitesBoton extends StatefulWidget {
  const ActualizacionTramitesBoton({super.key});

  @override
  State<ActualizacionTramitesBoton> createState() =>
      _ActualizacionTramitesBotonState();
}

class _ActualizacionTramitesBotonState
    extends State<ActualizacionTramitesBoton> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<dynamic> _tramites = [];
  List<dynamic> _filtrados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarTramites();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // -----------------------------
  // Utils
  // -----------------------------
  bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == 't' || s == '1' || s == 'si' || s == 'sí' || s == 'y' || s == 'yes';
    }
    return false;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // -----------------------------
  // Search
  // -----------------------------
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isEmpty) {
        setState(() => _filtrados = List.of(_tramites));
        return;
      }
      setState(() {
        _filtrados = _tramites.where((t) {
          final m = t as Map<String, dynamic>;
          final nombre = (m['nombre'] ?? '').toString().toLowerCase();
          final letra = (m['letra'] ?? '').toString().toLowerCase();
          final id = (m['id'] ?? '').toString().toLowerCase();
          return nombre.contains(q) || letra.contains(q) || id.contains(q);
        }).toList();
      });
    });
  }

  // -----------------------------
  // API
  // -----------------------------
  Future<void> cargarTramites() async {
    setState(() => _isLoading = true);
    try {
      final respuesta = await ApiService.getJson(ApiService.tramitesAdmin);
      if (respuesta.statusCode == 200) {
        final data = json.decode(respuesta.body);
        _tramites = List<dynamic>.from(data);
        _filtrados = List<dynamic>.from(_tramites);
      } else {
        _toast('Error al cargar trámites (${respuesta.statusCode})');
      }
    } catch (_) {
      _toast('No se pudo conectar con el servidor');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> cambiarEstado(int id, bool activo) async {
    try {
      final respuesta = await ApiService.putJson(
        ApiService.tramiteDetailUrl(id),
        {'activo': activo},
      );
      if (respuesta.statusCode == 200) {
        _toast('Estado actualizado');
        await cargarTramites();
      } else {
        _toast('No se pudo actualizar (${respuesta.statusCode})');
      }
    } catch (_) {
      _toast('Error de red al actualizar');
    }
  }

  Future<bool> crearTramite(Map<String, dynamic> payload) async {
    try {
      final respuesta = await ApiService.postJson(
        ApiService.tramitesAdmin,
        payload,
      );
      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        _toast('Trámite creado');
        await cargarTramites();
        return true;
      }
      _toast('Error al crear (${respuesta.statusCode})');
    } catch (_) {
      _toast('Error de red al crear');
    }
    return false;
  }

  Future<bool> actualizarTramite(int id, Map<String, dynamic> payload) async {
    try {
      final respuesta = await ApiService.putJson(
        ApiService.tramiteDetailUrl(id),
        payload,
      );
      if (respuesta.statusCode == 200) {
        _toast('Trámite actualizado');
        await cargarTramites();
        return true;
      }
      _toast('Error al actualizar (${respuesta.statusCode})');
    } catch (_) {
      _toast('Error de red al actualizar');
    }
    return false;
  }

  // -----------------------------
  // Dialogs
  // -----------------------------
  void _mostrarDescripcion(String titulo, String descripcion) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Descripción — $titulo'),
        content: SingleChildScrollView(
          child: Text(descripcion.isEmpty ? 'Sin descripción.' : descripcion),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _abrirDialogoCrear() {
    _abrirDialogoFormulario(
      title: 'Añadir trámite',
      onSubmit: (values) => crearTramite(values),
    );
  }

  void _abrirDialogoEditar(Map<String, dynamic> t) {
    _abrirDialogoFormulario(
      title: 'Editar trámite',
      initial: {
        'nombre': (t['nombre'] ?? '').toString(),
        // 'letra' -> ya no se edita en el diálogo
        'descripcion': (t['descripcion'] ?? '').toString(),
        'requiere_seguimiento': _toBool(t['requiere_seguimiento']),
        'activo': _toBool(t['activo']),
      },
      onSubmit: (values) => actualizarTramite(t['id'] as int, values),
    );
  }

  void _abrirDialogoFormulario({
    required String title,
    required Future<bool> Function(Map<String, dynamic>) onSubmit,
    Map<String, dynamic>? initial,
  }) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: initial?['nombre'] ?? '');
    final descCtrl = TextEditingController(text: initial?['descripcion'] ?? '');
    bool requiere = initial?['requiere_seguimiento'] ?? false;
    bool activo = initial?['activo'] ?? true;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setStateDialog(() => saving = true);
              final payload = {
                'nombre': nombreCtrl.text.trim(),
                // 'letra':  <-- ya no se envía; backend la asigna automático
                'descripcion': descCtrl.text.trim(),
                'requiere_seguimiento': requiere,
                'activo': activo,
              };
              final ok = await onSubmit(payload);
              if (mounted) {
                setStateDialog(() => saving = false);
                if (ok) Navigator.pop(ctx);
              }
            }

            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del trámite',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Requiere seguimiento'),
                        value: requiere,
                        onChanged: (v) => setStateDialog(() => requiere = v),
                      ),
                      SwitchListTile(
                        title: const Text('Activo'),
                        value: activo,
                        onChanged: (v) => setStateDialog(() => activo = v),
                      ),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : submit,
                  icon: saving
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(saving ? 'Guardando...' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra superior: buscador + botón añadir
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, letra o ID...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            FocusScope.of(context).unfocus();
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _abrirDialogoCrear,
              icon: const Icon(Icons.add),
              label: const Text('Añadir trámite'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: cargarTramites,
                  child: _filtrados.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No se encontraron trámites')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemCount: _filtrados.length,
                          itemBuilder: (_, i) {
                            final t = _filtrados[i] as Map<String, dynamic>;
                            final id = t['id'] as int;
                            final nombre = (t['nombre'] ?? '') as String;
                            final letra = (t['letra'] ?? '') as String;
                            final descripcion = (t['descripcion'] ?? '') as String;
                            final requiereSeg = _toBool(t['requiere_seguimiento']);
                            final activo = _toBool(t['activo']);

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _LetraChip(letra: letra.isEmpty ? '?' : letra),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nombre,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Tooltip(
                                                    message: 'ID del trámite',
                                                    child: Text(
                                                      'ID: $id',
                                                      style: TextStyle(color: Colors.grey[700]),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  _SeguimientoBadge(activo: requiereSeg),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            const Text('Activo',
                                                style: TextStyle(fontWeight: FontWeight.w600)),
                                            Switch(
                                              value: activo,
                                              onChanged: (v) => cambiarEstado(id, v),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _abrirDialogoEditar(t),
                                          icon: const Icon(Icons.edit_outlined),
                                          label: const Text('Editar'),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => _mostrarDescripcion(nombre, descripcion),
                                          icon: const Icon(Icons.info_outline),
                                          label: const Text('Descripción'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

// -----------------------------
// Widgets auxiliares
// -----------------------------
class _LetraChip extends StatelessWidget {
  final String letra;
  const _LetraChip({required this.letra});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      child: Text(letra, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _SeguimientoBadge extends StatelessWidget {
  final bool activo;
  const _SeguimientoBadge({required this.activo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: activo ? Colors.green.withOpacity(0.12) : Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activo ? Colors.green : Colors.grey),
      ),
      child: Row(
        children: [
          Icon(activo ? Icons.check_circle : Icons.remove_circle_outline, size: 16),
          const SizedBox(width: 6),
          Text(activo ? 'Requiere seguimiento' : 'Sin seguimiento'),
        ],
      ),
    );
  }
}