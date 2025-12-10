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

  // Datos dinámicos
  String siguienteTurno = "---";
  int numeroVentanilla = 0;
  List<String> turnosEnEspera = [];
  List<String> turnosEnAtencion = [];

  // Colores institucionales
  static const Color guinda = Color(0xFF581D2D);
  static const Color guindaClaro = Color(0xFFA4343A);
  static const Color verdeInstitucional = Color(0xFF1B2D26);
  static const Color textoOro = Color(0xFFD6C4A8);

  // CONTROL DE ANIMACIÓN DE 15 SEGUNDOS
  bool animacionActiva = false;
  Timer? animacionTimer;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _cargarTurnos();
    _cargarTurnoActual();

    // Actualización automática
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _cargarTurnos();
      _cargarTurnoActual();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    animacionTimer?.cancel();
    super.dispose();
  }

  // ==============================
  // API — ÚLTIMO TURNO LLAMADO
  // ==============================
  Future<void> _cargarTurnoActual() async {
    final url = Uri.parse("$api/tickets/ultimo-turno");

    try {
      final resp = await http.get(url);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        final nuevoTurno = data["turno"] ?? "---";

        // Detectar si cambió el turno
        if (nuevoTurno != siguienteTurno) {
          activarAnimacionCambio();
        }

        setState(() {
          siguienteTurno = nuevoTurno;
          numeroVentanilla = data["ventanilla_id"] ?? 0;
        });
      } else if (resp.statusCode == 204) {
        setState(() {
          siguienteTurno = "---";
          numeroVentanilla = 0;
        });
      }
    } catch (e) {
      print("⚠ Error en _cargarTurnoActual(): $e");
    }
  }

  // ACTIVAR ANIMACIÓN POR 15 SEGUNDOS
  void activarAnimacionCambio() {
    setState(() => animacionActiva = true);

    animacionTimer?.cancel();
    animacionTimer = Timer(const Duration(seconds: 15), () {
      setState(() => animacionActiva = false);
    });
  }

  // ==============================
  // API — TURNOS EN ESPERA + ATENCIÓN
  // ==============================
  Future<void> _cargarTurnos() async {
    try {
      final urlEspera = Uri.parse("$api/tickets/turnos-en-espera");
      final urlAtencion = Uri.parse("$api/tickets/turnos-en-atencion");

      final respEspera = await http.get(urlEspera);

      if (respEspera.statusCode == 200) {
        final data = jsonDecode(respEspera.body);
        final listaEspera = List<String>.from(data["turnos_en_espera"] ?? []);

        final respAtencion = await http.get(urlAtencion);

        if (respAtencion.statusCode == 200) {
          final data2 = jsonDecode(respAtencion.body);
          final listaAtencion =
              List<String>.from(data2["turnos_en_atencion"] ?? []);

          setState(() {
            turnosEnEspera = listaEspera;
            turnosEnAtencion = listaAtencion;
          });
        }
      }
    } catch (e) {
      print("⚠ Error en _cargarTurnos: $e");
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
            // ----------------------------------------
            // COLUMNA IZQUIERDA: TURNOS EN ESPERA
            // ----------------------------------------
            Expanded(
              child: _buildCard(
                titulo: "Turnos en espera",
                colorHeader: guindaClaro,
                child: CarreteAnimado(items: turnosEnEspera),
              ),
            ),

            const SizedBox(width: 14),

            // ----------------------------------------
            // COLUMNA CENTRAL
            // ----------------------------------------
            Expanded(
              child: Column(
                children: [
                  // Panel superior — siguiente turno
                  Expanded(
                    flex: 3,
                    child: _buildCard(
                      titulo: "Siguiente Turno",
                      colorHeader: guinda,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 700),
                          transitionBuilder: (widget, anim) {
                            if (animacionActiva) {
                              return ScaleTransition(scale: anim, child: widget);
                            }
                            return FadeTransition(opacity: anim, child: widget);
                          },
                          child: Container(
                            key: ValueKey(siguienteTurno),
                            padding: animacionActiva
                                ? const EdgeInsets.all(20)
                                : EdgeInsets.zero,
                            decoration: animacionActiva
                                ? BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.8),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  )
                                : null,
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
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Panel inferior — ventanilla asignada
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

            // ----------------------------------------
            // COLUMNA DERECHA: TURNOS EN ATENCIÓN
            // ----------------------------------------
            Expanded(
              child: _buildCard(
                titulo: "Turnos en atención",
                colorHeader: verdeInstitucional,
                child: CarreteAnimado(items: turnosEnAtencion),
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
}

// =========================================================
// CARRUSEL ANIMADO PROFESIONAL PARA TURNOS
// =========================================================
class CarreteAnimado extends StatefulWidget {
  final List<String> items;
  final Duration velocidad;

  const CarreteAnimado({
    super.key,
    required this.items,
    this.velocidad = const Duration(seconds: 3),
  });

  @override
  _CarreteAnimadoState createState() => _CarreteAnimadoState();
}

class _CarreteAnimadoState extends State<CarreteAnimado> {
  final ScrollController _controller = ScrollController();
  late Timer _timer;
  double _posicion = 0;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(widget.velocidad, (timer) {
      if (_controller.hasClients && widget.items.isNotEmpty) {
        _posicion += 50;
        _controller.animateTo(
          _posicion,
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
        );

        if (_controller.position.pixels >=
            _controller.position.maxScrollExtent - 50) {
          _posicion = 0;
          _controller.jumpTo(0);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(child: Text("Sin turnos"));
    }

    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              widget.items[index],
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
