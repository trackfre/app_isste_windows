import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:isste/services/api_service.dart';

class AsignarTramitesWidget extends StatefulWidget {
  const AsignarTramitesWidget({super.key});

  @override
  State<AsignarTramitesWidget> createState() => _AsignarTramitesWidgetState();
}

class _AsignarTramitesWidgetState extends State<AsignarTramitesWidget> {
  List ventanillas = [];
  List tramitesDisponibles = [];
  Map<int, Set<int>> tramitesSeleccionados = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => isLoading = true);

    try {
      final ventanillaRes = await ApiService.getJson(ApiService.ventanillas);
      final tramiteRes = await ApiService.getJson(ApiService.tramitesAdmin);

      if (ventanillaRes.statusCode == 200 && tramiteRes.statusCode == 200) {
        final vData = json.decode(ventanillaRes.body);
        final tData = json.decode(tramiteRes.body);

        setState(() {
          ventanillas = vData;
          tramitesDisponibles = tData;
          for (var v in vData) {
            tramitesSeleccionados[v['ventanilla_id']] = Set.from(
              v['tramites'].map<int>((t) => t['id']),
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar los datos')),
        );
      }
    } catch (e) {
      print('Error al cargar datos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar con el servidor')),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> guardarCambios(int ventanillaId) async {
    try {
      final response = await ApiService.postJson(
        ApiService.asignarTramites,
        {
          'ventanilla_id': ventanillaId,
          'tramites': tramitesSeleccionados[ventanillaId]?.toList() ?? [],
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar cambios')),
        );
      }
    } catch (e) {
      print('Error al guardar cambios: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la asignación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: ventanillas.map((v) {
        final ventanillaId = v['ventanilla_id'];
        final tramiteIds = tramitesSeleccionados[ventanillaId] ?? {};

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          elevation: 2,
          child: ExpansionTile(
            title: Text('${v['numero_ventanilla']} - ${v['usuario_nombre']}'),
            children: [
              ...tramitesDisponibles.map<Widget>((tramite) {
                final id = tramite['id'];
                final nombre = tramite['nombre'];
                return CheckboxListTile(
                  title: Text(nombre),
                  value: tramiteIds.contains(id),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        tramiteIds.add(id);
                      } else {
                        tramiteIds.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: ElevatedButton.icon(
                    onPressed: () => guardarCambios(ventanillaId),
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}