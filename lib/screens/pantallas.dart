import 'package:flutter/material.dart';
import 'package:isste/app_routes.dart'; // 🧭 Rutas centralizadas


class Pantallas extends StatefulWidget {
  const Pantallas({super.key});

  @override
  _PantallasState createState() => _PantallasState();
}

class _PantallasState extends State<Pantallas> {
  // Títulos
  final String tituloTurnosEspera = 'Turnos en espera';
  final String tituloSiguienteTurno = 'Siguiente Turno';
  final String tituloVentanilla = 'Ventanilla';
  final String tituloTurnosAtencion = 'Turnos en atención';

  // Colores
  static const Color colorFondoAppBar = Color(0xFF912F46);
  static const Color colorTurnosEspera = Color(0xFFA4343A);
  static const Color colorSiguienteTurno = Color(0xFF581D2D);
  static const Color colorTurnosAtencion = Color(0xFF1B2D26);
  static const Color colorTexto = Color(0xFFD6C4A8);
  static const Color colorTextoEspera = Color(0xFFDDCBA4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorFondoAppBar,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.home,
          (Route<dynamic> route) => false,
        );
          },
        ),
        title: Image.asset(
          'assets/logos/logo_gobiernomx.png',
          height: 60,
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPanel(
                    titulo: tituloTurnosEspera,
                    color: colorTurnosEspera,
                    colorTexto: colorTextoEspera,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        _buildEncabezado(
                          titulo: tituloSiguienteTurno,
                          color: colorSiguienteTurno,
                          colorTexto: colorTexto,
                        ),
                        const SizedBox(height: 8),
                        _buildEncabezado(
                          titulo: tituloVentanilla,
                          color: colorSiguienteTurno,
                          colorTexto: colorTexto,
                        ),
                        _buildCuerpo(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPanel(
                    titulo: tituloTurnosAtencion,
                    color: colorTurnosAtencion,
                    colorTexto: colorTexto,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Encabezado reutilizable
  Widget _buildEncabezado({
    required String titulo,
    required Color color,
    required Color colorTexto,
  }) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.all(25),
      child: Text(
        titulo,
        style: TextStyle(
          color: colorTexto,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Panel completo (título + contenedor)
  Widget _buildPanel({
    required String titulo,
    required Color color,
    required Color colorTexto,
  }) {
    return Expanded(
      child: Column(
        children: [
          _buildEncabezado(
            titulo: titulo,
            color: color,
            colorTexto: colorTexto,
          ),
          _buildCuerpo(),
        ],
      ),
    );
  }

  // Cuerpo reutilizable (contenedor en blanco con borde)
  Widget _buildCuerpo() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
      ),
    );
  }
}
