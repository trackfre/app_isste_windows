import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:isste/services/api_service.dart';

class TramiteVigenteBoton extends StatefulWidget {
  const TramiteVigenteBoton({super.key});

  @override
  State<TramiteVigenteBoton> createState() => _TramiteVigenteBotonState();
}

class _TramiteVigenteBotonState extends State<TramiteVigenteBoton> {
  List tickets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarTickets();
  }

  Future<void> cargarTickets() async {
    setState(() => isLoading = true);
    try {
      final respuesta = await ApiService.getJson(ApiService.ticketsActivos);

      if (respuesta.statusCode == 200) {
        setState(() {
          tickets = json.decode(respuesta.body);
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar tickets')),
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
          leading: const Icon(Icons.confirmation_number_outlined, color: Colors.redAccent),
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
                'Fecha: ${(ticket["fecha_creacion"] ?? "").toString().replaceFirst("T", " ").substring(0, 19)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
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
      return const Center(child: Text("No hay tickets activos."));
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