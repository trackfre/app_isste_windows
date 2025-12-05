import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:isste/constants/colors.dart';
import 'package:isste/forms/preregistro_form.dart';
import 'package:isste/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isste/services/api_service.dart';

class Preregistro extends StatefulWidget {
  const Preregistro({super.key});

  @override
  _PreregistroState createState() => _PreregistroState();
}

class _PreregistroState extends State<Preregistro> {
  final TextEditingController _usuarioCtrl = TextEditingController();
  final TextEditingController _contrasenaCtrl = TextEditingController();
  bool _ocultarContrasena = true;

  static const Color _colorFondo = AppColors.guinda7421;
  static const Color _colorTexto = AppColors.blanco;
  static const Color _colorBotonTexto = AppColors.dorado465;

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
          'Preregistro',
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
      onPressed: _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blanco,
      ),
      child: const Text(
        'Iniciar Sesión',
        style: TextStyle(color: _colorBotonTexto),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() => _ocultarContrasena = !_ocultarContrasena);
  }

  Future<void> _handleLogin() async {
    final usuario = _usuarioCtrl.text.trim();
    final contrasena = _contrasenaCtrl.text.trim();

    if (usuario.isEmpty || contrasena.isEmpty) {
      _mostrarAlerta('Por favor, completa ambos campos.');
      return;
    }

    try {
      final respuesta = await ApiService.postJson(
        ApiService.login,
        {
          'usuario': usuario,
          'contrasena': contrasena,
        },
      );

      if (respuesta.statusCode == 200) {
        final data = jsonDecode(respuesta.body);

        if (data.containsKey('rol_id') && data['rol_id'] == 3) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('usuario', usuario);
          await prefs.setInt('rol_id', data['rol_id']);

          final int usuarioId = data['usuario_id'];

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => Fpreregistro(usuarioId: usuarioId),
            ),
          );
        } else {
          _mostrarAlerta('No tienes permisos para acceder como preregistro.');
        }
      } else {
        final data = jsonDecode(respuesta.body);
        _mostrarAlerta(data['message'] ?? 'Credenciales incorrectas.');
      }
    } catch (e) {
      _mostrarAlerta('Error de conexión con el servidor.');
    }
  }

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
}