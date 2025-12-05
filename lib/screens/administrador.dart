import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:isste/constants/colors.dart';
import 'package:isste/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isste/forms/admin_form.dart';
import 'package:isste/services/api_service.dart';

class Administrador extends StatefulWidget {
  const Administrador({super.key});

  @override
  _AdministradorState createState() => _AdministradorState();
}

class _AdministradorState extends State<Administrador> {
  final TextEditingController _usuarioCtrl = TextEditingController();
  final TextEditingController _contrasenaCtrl = TextEditingController();
  bool _ocultarContrasena = true;
  bool _cargando = false;

  static const Color _colorFondo = AppColors.guinda7421;
  static const Color _colorTexto = AppColors.blanco;
  static const Color _colorBotonTexto = AppColors.dorado465;

  Future<void> _handleLogin() async {
    final usuario = _usuarioCtrl.text.trim();
    final contrasena = _contrasenaCtrl.text.trim();

    if (usuario.isEmpty || contrasena.isEmpty) {
      _mostrarAlerta('Por favor, completa ambos campos.');
      return;
    }

    setState(() => _cargando = true);

    try {
      // ✅ VERSIÓN ACTUALIZADA CON ApiService
      final respuesta = await ApiService.postJson(
        ApiService.login,
        {
          'usuario': usuario,
          'contrasena': contrasena,
        },
      );

      final data = jsonDecode(respuesta.body);
      print('🔁 Respuesta backend: $data');

      if (respuesta.statusCode == 200 && data['rol_id'] == 1) {
        // Guardar sesión local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario', usuario);
        await prefs.setInt('rol_id', data['rol_id']);

        // ✅ Redirección con el ID correcto
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Administracion(usuarioId: data['usuario_id']),
          ),
        );
      } else {
        _mostrarAlerta(data['message'] ?? 'Credenciales incorrectas o rol no permitido.');
      }
    } catch (e) {
      print('❌ Error de conexión: $e');
      _mostrarAlerta('Error de conexión con el servidor.');
    } finally {
      setState(() => _cargando = false);
    }
  }

  // ... (el resto del código se mantiene igual)
  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error de inicio de sesión'),
        content: Text(mensaje),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() => _ocultarContrasena = !_ocultarContrasena);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _colorFondo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.home,
              (route) => false,
            );
          },
        ),
        title: Image.asset(
          'assets/logos/logo_gobiernomx.png',
          height: 60,
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (_, constraints) {
          return Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    image: DecorationImage(
                      image: AssetImage('assets/logos/bienvenida.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: _buildFormulario()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormulario() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Administrador',
          style: TextStyle(
            fontSize: 75,
            fontWeight: FontWeight.bold,
            color: AppColors.dorado465,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: _colorFondo,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUsuarioField(),
              _buildContrasenaField(),
              const SizedBox(height: 20),
              _buildLoginButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsuarioField() {
    return TextField(
      controller: _usuarioCtrl,
      style: const TextStyle(color: _colorTexto),
      decoration: const InputDecoration(
        labelText: 'Usuario',
        labelStyle: TextStyle(color: _colorTexto),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _colorTexto),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _colorTexto),
        ),
      ),
    );
  }

  Widget _buildContrasenaField() {
    return TextField(
      controller: _contrasenaCtrl,
      obscureText: _ocultarContrasena,
      style: const TextStyle(color: _colorTexto),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        labelStyle: const TextStyle(color: _colorTexto),
        suffixIcon: IconButton(
          icon: Icon(
            _ocultarContrasena ? Icons.visibility : Icons.visibility_off,
            color: _colorTexto,
          ),
          onPressed: _togglePasswordVisibility,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _colorTexto),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _colorTexto),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _cargando ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blanco,
      ),
      child: _cargando
          ? const CircularProgressIndicator(color: AppColors.dorado465)
          : const Text(
              'Iniciar Sesión',
              style: TextStyle(color: _colorBotonTexto),
            ),
    );
  }
}