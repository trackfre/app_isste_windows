import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:isste/constants/colors.dart';
import 'package:isste/buttons/preregistro/asignacion_tramite_boton.dart';
import 'package:isste/buttons/preregistro/buscar_seguimiento.dart';
import 'package:isste/buttons/preregistro/boton_logout_preregistro.dart';
import 'package:isste/services/api_service.dart';

class Fpreregistro extends StatefulWidget {
  final int usuarioId;

  const Fpreregistro({super.key, required this.usuarioId});

  @override
  _FpreregistroState createState() => _FpreregistroState();
}

class _FpreregistroState extends State<Fpreregistro> {
  // ======= Estado general =======
  bool isLoading = true;
  bool _modoSeguimiento = false; // false = Nuevo trámite, true = Seguimiento

  // ======= Form "Nuevo trámite" =======
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int? tramiteSeleccionado; // ✅ int (id del trámite)
  String nombreCiudadano = '';
  List<dynamic> tramites = [];
  bool _asignando = false;

  // ======= Form "Seguimiento" =======
  final TextEditingController _searchCtrl = TextEditingController();
  String? _errorBusqueda;

  @override
  void initState() {
    super.initState();
    cargarTramitesDesdeBD();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ===========================
  // Cargar trámites  (FIX: parsea { success, tramites })
  // ===========================
  Future<void> cargarTramitesDesdeBD() async {
    try {
      final respuesta = await ApiService.getJson(ApiService.tramitesVigentes);

      // Log de depuración
      // ignore: avoid_print
      print('GET ${ApiService.tramitesVigentes} -> ${respuesta.statusCode}\n${respuesta.body}');

      if (respuesta.statusCode == 200) {
        final contentType = respuesta.headers['content-type'] ?? '';
        if (!contentType.contains('application/json')) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El servidor no devolvió JSON.')),
          );
          setState(() => isLoading = false);
          return;
        }

        final Map<String, dynamic> data = json.decode(respuesta.body);
        final List<dynamic> lista = (data['tramites'] ?? []) as List<dynamic>;

        if (!mounted) return;
        setState(() {
          tramites = lista
              .map((e) => {'id': e['id'] as int, 'nombre': e['nombre'] as String})
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('HTTP ${respuesta.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los trámites. ($e)')),
      );
      setState(() => isLoading = false);
    }
  }

  // ===========================
  // Asignar (usa tu botón modular)
  // ===========================
  Future<void> _asignarTramiteDesdeBoton() async {
    if (!_formKey.currentState!.validate()) return;
    if (tramiteSeleccionado == null) return;

    setState(() => _asignando = true);

    final boton = AsignacionTramiteBoton(
      tramiteId: tramiteSeleccionado!,
      ciudadano: nombreCiudadano.trim(),
      usuarioId: widget.usuarioId,
      onAsignacionExitosa: () {
        setState(() {
          tramiteSeleccionado = null;
          nombreCiudadano = '';
          _formKey.currentState?.reset();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trámite asignado correctamente')),
        );
      },
    );

    await boton.asignarTramite(context);

    if (mounted) setState(() => _asignando = false);
  }

  // ===========================
  // Buscar/Reactivar seguimiento (modular)
  // ===========================
void _abrirBuscarSeguimiento() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => BuscarSeguimientoDialog(
      onSuccess: (result) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Seguimiento reactivado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dato('Turno', result['turno']?.toString() ?? '-'),
                _dato('Ventanilla', result['ventanilla']?.toString() ?? '-'),
                _dato('Trámite', result['tramite']?.toString() ?? '-'),
                _dato('Ciudadano', result['ciudadano']?.toString() ?? '-'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      },
    ),
  );
}

  // ===========================
  // UI helpers
  // ===========================
  void _cambiarModo(bool seguimiento) {
    setState(() {
      _modoSeguimiento = seguimiento;
      // limpiar estados al cambiar modo
      nombreCiudadano = '';
      tramiteSeleccionado = null;
      _formKey.currentState?.reset();
      _searchCtrl.clear();
      _errorBusqueda = null;
    });
  }

  Widget _dato(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(v)),
        ],
      )
    );
  }

  // ===========================
  // Build
  // ===========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.guinda7421,
      automaticallyImplyLeading: false,
      title: Image.asset('assets/logos/logo_gobiernomx.png', height: 60),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: BotonLogoutPreregistro(usuarioId: widget.usuarioId),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Container(
      color: AppColors.blanco,
      padding: const EdgeInsets.all(20),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModeSwitcher(),
                const SizedBox(height: 16),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _modoSeguimiento ? _buildSeguimiento() : _buildFormularioTramites(),
                  ),
                ),
              ],
            ),
    );
  }

  // ===========================
  // Switcher: Nuevo / Seguimiento
  // ===========================
  Widget _buildModeSwitcher() {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('Nuevo trámite'),
          selected: !_modoSeguimiento,
          onSelected: (_) => _cambiarModo(false),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Seguimiento'),
          selected: _modoSeguimiento,
          onSelected: (_) => _cambiarModo(true),
        ),
      ],
    );
  }

  // ===========================
  // Formulario: Nuevo Trámite
  // ===========================
  Widget _buildFormularioTramites() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const Text('Nombre del ciudadano:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextFormField(
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFEEEEEE),
              border: OutlineInputBorder(),
              hintText: 'Ingrese nombre completo',
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingrese un nombre' : null,
            onChanged: (value) => nombreCiudadano = value,
          ),
          const SizedBox(height: 20),
          const Text('Seleccione el tipo de trámite:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFEEEEEE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            value: tramiteSeleccionado,
            hint: const Text('Elige un trámite'),
            items: tramites.map<DropdownMenuItem<int>>((t) {
              return DropdownMenuItem<int>(
                value: t['id'],
                child: Text(t['nombre']),
              );
            }).toList(),
            onChanged: (nuevo) {
              setState(() {
                tramiteSeleccionado = nuevo;
              });
            },
            validator: (value) =>
                value == null ? 'Por favor selecciona un trámite' : null,
          ),
          const SizedBox(height: 30),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: _asignando
                    ? const Text('Asignando...')
                    : const Text("Asignar Trámite"),
                style: ElevatedButton.styleFrom(
                  // ✅ Verde para contraste
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: (_asignando || tramiteSeleccionado == null)
                    ? null
                    : _asignarTramiteDesdeBoton,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================
  // UI: Seguimiento (buscador + dialog modular)
  // ===========================
  Widget _buildSeguimiento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Buscar seguimiento (turno, nombre o CURP):',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() => _errorBusqueda = null),
                onSubmitted: (_) => (_searchCtrl.text.trim().isEmpty)
                    ? setState(() => _errorBusqueda = 'Ingresa turno, nombre o CURP.')
                    : _abrirBuscarSeguimiento(),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFEEEEEE),
                  border: OutlineInputBorder(),
                  hintText: 'Ej. A-023, Juan Pérez, CURP…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('Buscar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (_searchCtrl.text.trim().isEmpty) {
                    setState(() => _errorBusqueda = 'Ingresa turno, nombre o CURP.');
                    return;
                  }
                  _abrirBuscarSeguimiento();
                },
              ),
            ),
          ],
        ),
        if (_errorBusqueda != null) ...[
          const SizedBox(height: 8),
          Text(_errorBusqueda!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 16),
        const Expanded(
          child: Center(
            child: Text(
              'Usa el buscador para localizar y reactivar el seguimiento.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}