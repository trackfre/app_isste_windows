import 'package:flutter/material.dart';
import 'package:isste/constants/colors.dart';
import 'package:isste/buttons/admin/actualizacion_tramites_boton.dart';
import 'package:isste/buttons/admin/actualizacion_usuarios_boton.dart';
import 'package:isste/buttons/admin/tramite_vigente_boton.dart';
import 'package:isste/buttons/admin/tramite_finalizado_boton.dart';
import 'package:isste/buttons/admin/boton_logout_admin.dart';
import 'package:isste/buttons/admin/tramite_seguimiento_boton.dart';

class Administracion extends StatelessWidget {
  final int usuarioId;

  const Administracion({super.key, required this.usuarioId});

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
          child: BotonLogoutAdmin(usuarioId: usuarioId),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Container(
      color: AppColors.blanco,
      child: AdministracionUI(usuarioId: usuarioId),
    );
  }
}

class AdministracionUI extends StatefulWidget {
  final int usuarioId;

  const AdministracionUI({super.key, required this.usuarioId});

  @override
  _AdministracionUIState createState() => _AdministracionUIState();
}

class _AdministracionUIState extends State<AdministracionUI> {
  bool showTramitesSub = false;
  bool showActualizacionSub = false;
  String selectedContent = '';
  String selectedMain = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainButton("TRÁMITES", () {
                setState(() {
                  selectedMain = "TRÁMITES";
                  showTramitesSub = !showTramitesSub;
                  showActualizacionSub = false;
                });
              }),
              if (showTramitesSub) ...[
                _buildSubButton("Vigentes"),
                _buildSubButton("Finalizados"),
                _buildSubButton("Seguimiento"), // 👈 Nuevo
              ],
              const SizedBox(height: 10),
              _buildMainButton("ACTUALIZACIÓN", () {
                setState(() {
                  selectedMain = "ACTUALIZACIÓN";
                  showActualizacionSub = !showActualizacionSub;
                  showTramitesSub = false;
                });
              }),
              if (showActualizacionSub) ...[
                _buildSubButton("Usuarios"),
                _buildSubButton("Trámites"),
              ],
              const SizedBox(height: 10),
              _buildMainButton("INFORMES", () {
                setState(() {
                  selectedMain = "INFORMES";
                  selectedContent = "Mostrando informes...";
                  showActualizacionSub = false;
                  showTramitesSub = false;
                });
              }),
            ],
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Container(
              height: 500,
              decoration: BoxDecoration(
                // 🔧 ANTES: AppColors.blanco.withOpacity(0.95)
                color: AppColors.blanco.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  // 🔧 ANTES: AppColors.guinda7421.withOpacity(0.4)
                  color: AppColors.guinda7421.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    // 🔧 ANTES: Colors.black.withOpacity(0.08)
                    color: Colors.black.withValues(alpha: 0.08),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(25),
              child: _buildDynamicContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(String label, VoidCallback onPressed) {
    final isSelected = selectedMain == label;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? AppColors.guinda7420 : AppColors.guinda7421,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.blanco)),
    );
  }

  Widget _buildSubButton(String label) {
    final selectedKey = switch (label) {
      "Trámites" => "widget:actualizacion_tramites",
      "Usuarios" => "widget:actualizacion_usuarios",
      "Vigentes" => "widget:tramites_vigentes",
      "Finalizados" => "widget:tramites_finalizados",
      "Seguimiento" => "widget:tramites_seguimiento", // 👈 Nuevo
      _ => ""
    };

    final isSelected = selectedContent == selectedKey;

    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 5),
      child: TextButton(
        style: TextButton.styleFrom(
          // 🔧 ANTES: AppColors.arena468.withOpacity(0.3)
          backgroundColor:
              isSelected ? AppColors.arena468.withValues(alpha: 0.3) : null,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          setState(() => selectedContent = selectedKey);
        },
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.guinda7420 : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicContent() {
    if (selectedContent == "widget:actualizacion_tramites") {
      return const ActualizacionTramitesBoton();
    } else if (selectedContent == "widget:actualizacion_usuarios") {
      return const ActualizacionUsuariosBoton();
    } else if (selectedContent == "widget:tramites_vigentes") {
      return const TramiteVigenteBoton();
    } else if (selectedContent == "widget:tramites_finalizados") {
      return const TramiteFinalizadoBoton();
    } else if (selectedContent == "widget:tramites_seguimiento") {
      // 👇 Carga el nuevo listado de tickets en seguimiento
      return const TramiteSeguimientoBoton();
    }

    return Center(
      child: Text(
        selectedContent.isEmpty
            ? "Selecciona una opción..."
            : selectedContent,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
