import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:isste/buttons/ventanilla/boton_finalizado.dart';
import 'package:isste/buttons/ventanilla/boton_cambiodeventanilla.dart';
import 'package:isste/buttons/ventanilla/boton_seguimiento.dart';
import 'package:isste/buttons/ventanilla/boton_noaplica.dart';
import 'package:isste/buttons/ventanilla/boton_receso.dart';
import 'package:isste/buttons/ventanilla/boton_logout_ventanilla.dart';
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

  Future<void> cargarTurnoActivo() async {
    try {
      final res = await http.get(Uri.parse(
        'http://192.168.0.20:5000/api/ventanilla/ticket-activo/${widget.usuarioId}',
      ));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          turnoData = TurnoData.fromJson(data);
          isLoading = false;
        });
      } else {
        setState(() {
          turnoData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        turnoData = null;
        isLoading = false;
      });
    }
  }

  Future<void> _finalizarTurno() async {
    final response = await http.post(
      Uri.parse('http://192.168.0.20:5000/api/ventanilla/finalizar-ticket'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'usuario_id': widget.usuarioId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == true && data['nuevo_ticket'] != null) {
        setState(() {
          turnoData = TurnoData.fromJson(data['nuevo_ticket']);
        });
      } else {
        setState(() {
          turnoData = null;
        });

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sin más turnos'),
            content: Text(data['message'] ?? 'No hay más turnos en espera'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              )
            ],
          ),
        );
      }
    } else {
      // log opcional
    }
  }

  Future<void> _cancelarTurnoConMotivo(String motivo) async {
    final response = await http.post(
      Uri.parse('http://192.168.0.20:5000/api/ventanilla/cancelar-ticket'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuario_id': widget.usuarioId,
        'motivo': motivo,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == true && data['nuevo_ticket'] != null) {
        setState(() {
          turnoData = TurnoData.fromJson(data['nuevo_ticket']);
        });
      } else {
        setState(() {
          turnoData = null;
        });

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Turno cancelado'),
            content: Text(data['message'] ?? 'No hay más turnos en espera'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              )
            ],
          ),
        );
      }
    } else {
      // log opcional
    }
  }

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
          // PANEL IZQUIERDO con el mismo marco que en Admin
          Expanded(
            flex: 2,
            child: Container(
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
                    isLoading ? 'Cargando...' : turnoData?.turno ?? 'Sin asignar',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.guinda7421,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _CampoDato(
                    label: 'Tipo de Trámite',
                    valor: isLoading ? 'Cargando...' : turnoData?.tramite ?? 'Sin asignar',
                  ),
                  _CampoDato(
                    label: 'Nombre del solicitante',
                    valor: isLoading ? 'Cargando...' : turnoData?.ciudadano ?? 'Sin asignar',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Columna de botones (sin marco)
          Expanded(
            flex: 1,
            child: Column(
              children: [
                BotonNoAplica(onPressed: _cancelarTurnoConMotivo),
                const SizedBox(height: 20),
                BotonFinalizado(onPressed: _finalizarTurno),
                const SizedBox(height: 20),
                if (turnoData != null)
                  BotonCambioVentanilla(
                    ticketId: turnoData!.ticketId,
                    tramiteId: turnoData!.tramiteId,
                  ),
                const SizedBox(height: 20),
                BotonSeguimiento(
                  turno: turnoData?.turno ?? '',
                  tramite: turnoData?.tramite ?? '',
                  ciudadano: turnoData?.ciudadano ?? '',
                ),
              ],
            ),
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
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.black12),
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
              color: Colors.black87,
            ),
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
