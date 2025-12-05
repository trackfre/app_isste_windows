import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:isste/constants/colors.dart';
import 'package:isste/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isste/services/api_service.dart';

class Ventanillas extends StatefulWidget {
  const Ventanillas({super.key});

  @override
  _VentanillasState createState() => _VentanillasState();
}

class _VentanillasState extends State<Ventanillas> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _cargando = false;

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  Future<void> _handleLogin() async {
    final usuario = _usernameController.text.trim();
    final contrasena = _passwordController.text.trim();

    if (usuario.isEmpty || contrasena.isEmpty) {
      _mostrarAlerta('Por favor, completa ambos campos.');
      return;
    }

    setState(() => _cargando = true);

    try {
      final respuesta = await ApiService.postJson(
        ApiService.login,
        {
          'usuario': usuario,
          'contrasena': contrasena,
        },
      );

      final data = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 200 && data['rol_id'] == 2) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario', usuario);
        await prefs.setInt('rol_id', data['rol_id']);

        final int usuarioId = data['usuario_id'];

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.ventanillaturnos,
          (route) => false,
          arguments: usuarioId,
        );
      } else {
        _mostrarAlerta('Credenciales inválidas o rol incorrecto.');
      }
    } catch (e) {
      _mostrarAlerta('Error de conexión con el servidor.');
    } finally {
      setState(() => _cargando = false);
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

  void _navigateBackToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.guinda7421,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
          onPressed: _navigateBackToHome,
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        'Ventanilla',
                        style: TextStyle(
                          fontSize: 75,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dorado465,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildLoginForm(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.guinda7421,
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
        children: [
          _buildUsernameField(),
          _buildPasswordField(),
          const SizedBox(height: 20),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextField(
      controller: _usernameController,
      style: const TextStyle(color: AppColors.blanco),
      decoration: const InputDecoration(
        labelText: 'Usuario',
        labelStyle: TextStyle(color: AppColors.blanco),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.blanco),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.blanco),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: AppColors.blanco),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        labelStyle: const TextStyle(color: AppColors.blanco),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: AppColors.blanco,
          ),
          onPressed: _togglePasswordVisibility,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.blanco),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.blanco),
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
              style: TextStyle(color: AppColors.dorado465),
            ),
    );
  }
}