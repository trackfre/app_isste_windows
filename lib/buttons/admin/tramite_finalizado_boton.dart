import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:isste/services/api_service.dart';

class TramiteFinalizadoBoton extends StatefulWidget {
  const TramiteFinalizadoBoton({super.key});

  @override
  State<TramiteFinalizadoBoton> createState() => _TramiteFinalizadoBotonState();
}

class _TramiteFinalizadoBotonState extends State<TramiteFinalizadoBoton> {
  List tickets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarTicketsFinalizados();
  }

  Future<void> cargarTicketsFinalizados() async {
    setState(() => isLoading = true);

    try {
      final respuesta = await ApiService.getJson(ApiService.ticketsFinalizados);

      if (respuesta.statusCode == 200) {
        setState(() {
          tickets = json.decode(respuesta.body);
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar tickets finalizados')),
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar con el servidor')),
      );
      setState(() => isLoading = false);
    }
  }

  Widget buildTicketItem(Map<String, dynamic> ticket) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: const Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text(
            'Turno: ${ticket["codigo"]}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trámite: ${ticket["tramite_nombre"]}'),
              Text('Ciudadano: ${ticket["ciudadano"]}'),
              Text(
                'Finalizado: ${(ticket["fecha_finalizacion"] ?? "").toString().replaceFirst("T", " ").substring(0, 19)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (ticket["motivo_cancel"] != null && ticket["motivo_cancel"].toString().trim().isNotEmpty)
                Text('Motivo: ${ticket["motivo_cancel"]}', style: TextStyle(color: Colors.red[400], fontSize: 13)),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tickets.isEmpty) {
      return const Center(child: Text("No hay tickets finalizados."));
    }

    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return buildTicketItem(ticket);
      },
    );
  }
}