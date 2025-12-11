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
  List filteredTickets = [];

  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarTicketsFinalizados();

    searchController.addListener(() {
      filtrarTickets(searchController.text.trim());
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =====================================================
  // 🔥 Cargar tickets finalizados desde Backend
  // =====================================================
  Future<void> cargarTicketsFinalizados() async {
    setState(() => isLoading = true);

    try {
      final respuesta = await ApiService.getJson(ApiService.ticketsFinalizados);

      if (respuesta.statusCode == 200) {
        tickets = json.decode(respuesta.body);
        filteredTickets = tickets;

        setState(() => isLoading = false);
      } else {
        mostrarError("Error al cargar tickets finalizados");
      }
    } catch (e) {
      mostrarError("No se pudo conectar con el servidor");
    }
  }

  void mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
    setState(() => isLoading = false);
  }

  // =====================================================
  // 🔍 Filtro dinámico
  // =====================================================
  void filtrarTickets(String query) {
    if (query.isEmpty) {
      setState(() => filteredTickets = tickets);
      return;
    }

    final q = query.toLowerCase();

    setState(() {
      filteredTickets = tickets.where((ticket) {
        final turno = (ticket["codigo"] ?? "").toString().toLowerCase();
        final tramite = (ticket["tramite_nombre"] ?? "").toLowerCase();
        final ciudadano = (ticket["ciudadano"] ?? "").toLowerCase();

        return turno.contains(q) ||
            tramite.contains(q) ||
            ciudadano.contains(q);
      }).toList();
    });
  }

  // =====================================================
  // 🧱 Tarjeta de ticket finalizado
  // =====================================================
  Widget buildTicketItem(Map<String, dynamic> ticket) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: const Icon(Icons.check_circle_outline, color: Colors.green, size: 32),
          title: Text(
            'Turno: ${ticket["codigo"]}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trámite: ${ticket["tramite_nombre"]}'),
              Text('Ciudadano: ${ticket["ciudadano"]}'),
              const SizedBox(height: 4),
              Text(
                'Finalizado: ${(ticket["fecha_finalizacion"] ?? "").toString().replaceFirst("T", " ").substring(0, 19)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if ((ticket["motivo_cancel"] ?? "").toString().isNotEmpty)
                Text(
                  'Motivo: ${ticket["motivo_cancel"]}',
                  style: TextStyle(color: Colors.red[400], fontSize: 13),
                ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }

  // =====================================================
  // UI PRINCIPAL
  // =====================================================
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 🔍 BUSCADOR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Buscar por turno, trámite o ciudadano...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black26),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // LISTA FILTRADA
        Expanded(
          child: filteredTickets.isEmpty
              ? const Center(
                  child: Text(
                    "No se encontraron resultados",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredTickets.length,
                  itemBuilder: (context, index) {
                    return buildTicketItem(filteredTickets[index]);
                  },
                ),
        ),
      ],
    );
  }
}
