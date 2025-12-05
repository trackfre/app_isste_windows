import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ==========================
  // CONFIGURACIÓN BASE
  // ==========================
  static const String baseUrl = 'http://192.168.0.20:5000'; // IP del backend Flask
  static const String apiPrefix = '$baseUrl/api';

  // ==========================
  // 🔐 AUTH
  // ==========================
  static String get login => '$baseUrl/login';   // sin prefijo /api
  static String get logout => '$baseUrl/logout'; // sin prefijo /api

  // ==========================
  // 🧑‍💼 ADMIN
  // ==========================
  static String get usuarios => '$apiPrefix/admin/usuarios';
  static String get ventanillas => '$apiPrefix/admin/ventanillas';
  static String get asignarVentanilla => '$apiPrefix/admin/asignar_ventanilla';
  static String get asignarTramites => '$apiPrefix/admin/asignar_tramites';
  static String get tramitesAdmin => '$apiPrefix/admin/tramites';
  static String get ticketsActivos => '$apiPrefix/admin/tickets/activos';
  static String get ticketsFinalizados => '$apiPrefix/admin/tickets/finalizados';
  static String get reasignarTicket => '$apiPrefix/tickets/reasignar-por-tramite';

  // ==========================
  // 🔍 SEGUIMIENTO
  // ==========================
  static String get buscarSeguimiento => '$baseUrl/seguimientos';
  static String get reactivarSeguimiento => '$baseUrl/preregistro/reactivar-seguimiento';

  // Helpers con parámetros dinámicos
  static String ventanillaTramitesUrl(int ventanillaId) =>
      '$apiPrefix/admin/ventanillas/$ventanillaId/tramites';

  static String usuarioDetailUrl(int usuarioId) =>
      '$apiPrefix/admin/usuarios/$usuarioId';

  static String tramiteDetailUrl(int tramiteId) =>
      '$apiPrefix/admin/tramites/$tramiteId';

  // ==========================
  // 🧾 TRÁMITES
  // ==========================
  static String get tramitesVigentes => '$apiPrefix/tramites/vigentes';

  // ==========================
  // 🎫 TICKETS
  // ==========================
  static String get tomarSiguiente => '$apiPrefix/tickets/tomar-siguiente';

  // ==========================
  // 🟢 PREREGISTRO
  // ==========================
  static String get asignarTicket => '$apiPrefix/preregistro/asignar-ticket';

  // ==========================
  // 🧠 MÉTODOS AUXILIARES
  // ==========================

  /// Headers comunes para requests JSON
  static Map<String, String> get jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Verifica si el backend responde correctamente
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse(tramitesVigentes),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Método helper para POST JSON
  static Future<http.Response> postJson(String url, Map<String, dynamic> body) async {
    try {
      return await http.post(
        Uri.parse(url),
        headers: jsonHeaders,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      // Retorna una respuesta de error en caso de timeout o excepción
      return http.Response('{"error": "Connection failed: $e"}', 500);
    }
  }

  /// Método helper para PUT JSON
  static Future<http.Response> putJson(String url, Map<String, dynamic> body) async {
    try {
      return await http.put(
        Uri.parse(url),
        headers: jsonHeaders,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      return http.Response('{"error": "Connection failed: $e"}', 500);
    }
  }

  /// Método helper para GET
  static Future<http.Response> getJson(String url) async {
    try {
      return await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      return http.Response('{"error": "Connection failed: $e"}', 500);
    }
  }

  /// Método helper para DELETE
  static Future<http.Response> deleteJson(String url) async {
    try {
      return await http.delete(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      return http.Response('{"error": "Connection failed: $e"}', 500);
    }
  }

  /// Procesa respuesta HTTP y devuelve el JSON decodificado
  static dynamic processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw HttpException(
        'Error ${response.statusCode}: ${response.reasonPhrase}',
        statusCode: response.statusCode,
      );
    }
  }
}

/// Excepción personalizada para errores HTTP
class HttpException implements Exception {
  final String message;
  final int? statusCode;

  HttpException(this.message, {this.statusCode});

  @override
  String toString() => 'HttpException: $message${statusCode != null ? ' ($statusCode)' : ''}';
}