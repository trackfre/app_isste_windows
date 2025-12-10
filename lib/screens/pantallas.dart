import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:isste/app_routes.dart';

class Pantallas extends StatefulWidget {
  const Pantallas({super.key});

  @override
  _PantallasState createState() => _PantallasState();
}

class _PantallasState extends State<Pantallas> {
  // ==============================
  // CONFIGURACIÓN DEL BACKEND
  // ==============================
  static const String baseUrl = 'http://192.168.0.20:5000';
  static const String api = '$baseUrl/api';

  // Datos dinámicos (solo lectura)
  String siguienteTurno = "---";   // Se llenará con el primer turno en atención
  int numeroVentanilla = 0;        // Por ahora se queda dummy; luego hacemos endpoint específico

  List<String> turnosEnEspera = [];
  List<String> turnosEnAtencion = [];

  // Colores institucionales
  static const Color guinda = Color(0xFF581D2D);
  static const Color guindaClaro = Color(0xFFA4343A);
  static const Color verdeInstitucional = Color(0xFF1B2D26);
  static const Color textoOro = Color(0xFFD6C4A8);

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Cargar datos al iniciar
    _cargarTurnos();

    // Actualización automática cada 5 segundos
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _cargarTurnos();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ==============================
  // API: TURNOS EN ESPERA + ATENCIÓN
  // ==============================
  Future<void> _cargarTurnos() async {
    try {
      final urlEspera   = Uri.parse("$api/tickets/turnos-en-espera");
      final urlAtencion = Uri.parse("$api/tickets/turnos-en-atencion");

      // 1) Turnos en espera
      final respEspera = await http.get(urlEspera);
      if (respEspera.statusCode == 200) {
        final data = jsonDecode(respEspera.body);
        final listaEspera =
            List<String>.from(data["turnos_en_espera"] ?? []);

        // 2) Turnos en atención
        final respAtencion = await http.get(urlAtencion);
        if (respAtencion.statusCode == 200) {
          final data2 = jsonDecode(respAtencion.body);
          final listaAtencion =
              List<String>.from(data2["turnos_en_atencion"] ?? []);

          setState(() {
            turnosEnEspera   = listaEspera;
            turnosEnAtencion = listaAtencion;

            // El "Siguiente Turno" del panel central será:
            // el primer turno en atención (si hay), si no, "---"
            if (turnosEnAtencion.isNotEmpty) {
              siguienteTurno = turnosEnAtencion.first;
            } else {
              siguienteTurno = "---";
            }
          });
        } else {
          print("❌ Error al obtener turnos en atención: ${respAtencion.body}");
        }
      } else {
        print("❌ Error al obtener turnos en espera: ${respEspera.body}");
      }
    } catch (e) {
      print("⚠ Error en API _cargarTurnos: $e");
    }
  }

  // ======================================================
  // UI PRINCIPAL
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: guinda,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.home,
              (route) => false,
            );
          },
        ),
        title: Image.asset('assets/logos/logo_gobiernomx.png', height: 55),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // =======================
            // Columna izquierda: ESPERA
            // =======================
            Expanded(
              child: _buildCard(
                titulo: "Turnos en espera",
                colorHeader: guindaClaro,
                child: _buildLista(turnosEnEspera),
              ),
            ),

            const SizedBox(width: 14),

            // =======================
            // Columna central
            // =======================
            Expanded(
              child: Column(
                children: [
                  // Panel superior: Siguiente Turno
                  Expanded(
                    flex: 3,
                    child: _buildCard(
                      titulo: "Siguiente Turno",
                      colorHeader: guinda,
                      child: Center(
                        child: Text(
                          siguienteTurno,
                          style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Panel inferior: Ventanilla (por ahora dummy)
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: guinda,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          numeroVentanilla == 0
                              ? "Ventanilla"
                              : "Ventanilla $numeroVentanilla",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: textoOro,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // =======================
            // Columna derecha: ATENCIÓN
            // =======================
            Expanded(
              child: _buildCard(
                titulo: "Turnos en atención",
                colorHeader: verdeInstitucional,
                child: _buildLista(turnosEnAtencion),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // WIDGETS AUXILIARES
  // ======================================================
  Widget _buildCard({
    required String titulo,
    required Color colorHeader,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorHeader,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textoOro,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(List<String> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          "Sin turnos",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey[400]),
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          items[index],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
