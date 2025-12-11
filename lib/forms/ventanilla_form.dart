import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Botones
import 'package:isste/buttons/ventanilla/boton_finalizado.dart';
import 'package:isste/buttons/ventanilla/boton_cambiodeventanilla.dart';
import 'package:isste/buttons/ventanilla/boton_seguimiento.dart';
import 'package:isste/buttons/ventanilla/boton_noaplica.dart';
import 'package:isste/buttons/ventanilla/boton_receso.dart';
import 'package:isste/buttons/ventanilla/boton_logout_ventanilla.dart';

// Estilos
import 'package:isste/constants/colors.dart';

class Ventanillaturnos extends StatefulWidget {
  final int usuarioId;

  const Ventanillaturnos({super.key, required this.usuarioId});

  @override
  State<Ventanillaturnos> createState() => _VentanillaturnosState();
}

class _VentanillaturnosState extends State<Ventanillaturnos> {
  TurnoData? turnoData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarTurnoActivo();
  }

  // ============================================================
  // 🔥 Tomar siguiente ticket
  // ============================================================
  Future<void> tomarSiguienteTicket() async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.20:5000/api/tickets/tomar-siguiente"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"usuario_id": widget.usuarioId}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          turnoData = TurnoData.fromJson(jsonDecode(response.body));
        });
      } else {
        setState(() => turnoData = null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => turnoData = null);
    }
  }

  // ============================================================
  // 🔥 Cargar ticket activo al iniciar
  // ============================================================
  Future<void> cargarTurnoActivo() async {
    try {
      final res = await http.get(Uri.parse(
        "http://192.168.0.20:5000/api/ventanilla/ticket-activo/${widget.usuarioId}",
      ));

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          turnoData = TurnoData.fromJson(jsonDecode(res.body));
          isLoading = false;
        });
      } else if (res.statusCode == 404) {
        await tomarSiguienteTicket();
        if (mounted) setState(() => isLoading = false);
      } else {
        setState(() {
          turnoData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        turnoData = null;
        isLoading = false;
      });
    }
  }

  // ============================================================
  // 🔥 Finalizar turno
  // ============================================================
  Future<void> _finalizarTurno() async {
    if (turnoData == null) return;

    final response = await http.post(
      Uri.parse("http://192.168.0.20:5000/api/tickets/finalizar-ticket"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "ticket_id": turnoData!.ticketId,
        "usuario_id": widget.usuarioId,
      }),
    );

    if (response.statusCode == 200) {
      await tomarSiguienteTicket();
    }
  }

  // ============================================================
  // UI PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.guinda7421,
      automaticallyImplyLeading: false,
      title: Image.asset("assets/logos/logo_gobiernomx.png", height: 60),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: RecesoButton(onFinalizar: () {}),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: BotonLogoutVentanilla(usuarioId: widget.usuarioId),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _panelTurno()),
          const SizedBox(width: 20),

          // PANEL DERECHO
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // NO APLICA
                BotonNoAplica(
                  ticketId: turnoData?.ticketId ?? 0,
                  usuarioId: widget.usuarioId,
                  onNextTicket: (nuevo) async {
                    if (!mounted) return;

                    setState(() {
                      if (nuevo != null) {
                        turnoData = TurnoData.fromJson(nuevo);
                      } else {
                        turnoData = null;
                      }
                    });

                    await tomarSiguienteTicket();
                  },
                ),

                const SizedBox(height: 20),

                BotonFinalizado(onPressed: _finalizarTurno),
                const SizedBox(height: 20),

                if (turnoData != null)
                  BotonCambioVentanilla(
                    ticketId: turnoData!.ticketId,
                    tramiteId: turnoData!.tramiteId,
                    onTicketActualizado: (nuevoTicket) {
                      if (!mounted) return;
                      setState(() {
                        turnoData = TurnoData.fromJson(nuevoTicket);
                      });
                    },
                  ),

                const SizedBox(height: 20),

                BotonSeguimiento(
                  turno: turnoData?.turno ?? "",
                  tramite: turnoData?.tramite ?? "",
                  ciudadano: turnoData?.ciudadano ?? "",
                  ticketId: turnoData?.ticketId,
                  usuarioId: widget.usuarioId,
                  onSuccess: () async {
                    await tomarSiguienteTicket();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelTurno() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.blanco.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.guinda7421.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            isLoading ? "Cargando..." : turnoData?.turno ?? "Sin asignar",
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.guinda7421,
            ),
          ),
          const SizedBox(height: 40),
          _CampoDato(
            label: "Tipo de Trámite",
            valor: isLoading
                ? "Cargando..."
                : turnoData?.tramite ?? "Sin asignar",
          ),
          _CampoDato(
            label: "Nombre del solicitante",
            valor: isLoading
                ? "Cargando..."
                : turnoData?.ciudadano ?? "Sin asignar",
          ),
        ],
      ),
    );
  }
}

class _CampoDato extends StatelessWidget {
  final String label;
  final String valor;

  const _CampoDato({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class TurnoData {
  final String turno;
  final String tramite;
  final String ciudadano;
  final int ticketId;
  final int tramiteId;

  TurnoData({
    required this.turno,
    required this.tramite,
    required this.ciudadano,
    required this.ticketId,
    required this.tramiteId,
  });

  factory TurnoData.fromJson(Map<String, dynamic> json) {
    return TurnoData(
      turno: json['turno'],
      tramite: json['tramite'],
      ciudadano: json['ciudadano'],
      ticketId: json['ticket_id'] ?? 0,
      tramiteId: json['tramite_id'] ?? 0,
    );
  }
}
