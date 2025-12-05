// lib/app_routes.dart

/// Centraliza todas las rutas usadas en la aplicación.
/// Evita errores por rutas "quemadas" y permite mantener consistencia.
class AppRoutes {
  /// Ruta principal
  static const String home = '/';
  

  // Pantallas de inicio de sesión por rol (no requieren argumentos)
  static const String ventanillas = '/ventanillas';
  static const String administrador = '/administrador';
  static const String pantallas = '/pantallas';
  static const String preregistro = '/preregistro';

  // Rutas posteriores al login por módulo (requieren argumentos)
  static const String administracion = '/administracion';     // requiere usuarioId
  static const String ventanillaturnos = '/ventanillaturnos'; // requiere usuarioId
  static const String fpreregistro = '/fpreregistro';         // requiere usuarioId
}
