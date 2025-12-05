import 'package:flutter/material.dart';
import 'package:isste/constants/colors.dart';
import 'package:isste/app_routes.dart';

// 📂 Pantallas de login
import 'package:isste/screens/administrador.dart';
import 'package:isste/screens/preregistro.dart';
import 'package:isste/screens/ventanillas.dart';

// 📂 Pantallas principales después del login
import 'package:isste/forms/admin_form.dart';
import 'package:isste/forms/preregistro_form.dart';
import 'package:isste/forms/ventanilla_form.dart';

// 📂 Pantalla general
import 'package:isste/screens/pantallas.dart';

class AppConstants {
  static const double headerHeight = 80.0;
  static const double buttonSpacing = 10.0;
  static const double containerPadding = 20.0;
  static const double borderRadius = 20.0;
  static const int animationDuration = 200;
  static const double responsiveBreakpoint = 600.0;
}

class MenuButtonData {
  final String label;
  final IconData icon;
  final String route;

  const MenuButtonData({
    required this.label,
    required this.icon,
    required this.route,
  });
}

void main() {
  runApp(TicketApp());
}

class TicketApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.home,
      theme: _buildAppTheme(),

      // 📍 Rutas centralizadas con separación comentada
      onGenerateRoute: (settings) {
        switch (settings.name) {
          // 🏠 Ruta inicial
          case AppRoutes.home:
            return MaterialPageRoute(builder: (_) => PantallaInicio());

          // 🔐 Rutas de LOGIN por rol
          case AppRoutes.ventanillas:
            return MaterialPageRoute(builder: (_) => Ventanillas());
          case AppRoutes.administrador:
            return MaterialPageRoute(builder: (_) => const Administrador());
          case AppRoutes.preregistro:
            return MaterialPageRoute(builder: (_) => Preregistro());

          // ✅ Rutas de PANELES después del login
          case AppRoutes.administracion:
            final usuarioId = settings.arguments as int;
            return MaterialPageRoute(
                builder: (_) => Administracion(usuarioId: usuarioId));
          case AppRoutes.fpreregistro:
            final usuarioId = settings.arguments as int;
            return MaterialPageRoute(
                builder: (_) => Fpreregistro(usuarioId: usuarioId));
          case AppRoutes.ventanillaturnos:
            final usuarioId = settings.arguments as int;
            return MaterialPageRoute(
                builder: (_) => Ventanillaturnos(usuarioId: usuarioId));

          // 🖥️ Pantalla general
          case AppRoutes.pantallas:
            return MaterialPageRoute(builder: (_) => Pantallas());

          // 🛑 Ruta no encontrada
          default:
            return null;
        }
      },
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      primaryColor: AppColors.guinda7421,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.guinda7421),
    );
  }
}

class PantallaInicio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildResponsiveBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.guinda7421,
      height: AppConstants.headerHeight,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/logos/logo_gobiernomx.png',
        height: 60,
      ),
    );
  }

  Widget _buildResponsiveBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = ScreenSize(constraints);
        final isWideScreen = constraints.maxWidth >= AppConstants.responsiveBreakpoint;

        return Container(
          color: AppColors.blanco,
          child: isWideScreen
              ? _buildWideLayout(screenSize)
              : _buildNarrowLayout(screenSize),
        );
      },
    );
  }

  Widget _buildWideLayout(ScreenSize screenSize) {
    return Row(
      children: [
        Expanded(flex: 1, child: WelcomeSection(screenSize: screenSize)),
        Expanded(flex: 1, child: ButtonsSection(screenSize: screenSize)),
      ],
    );
  }

  Widget _buildNarrowLayout(ScreenSize screenSize) {
    return SingleChildScrollView(
      child: Column(
        children: [
          WelcomeSection(screenSize: screenSize),
          ButtonsSection(screenSize: screenSize),
        ],
      ),
    );
  }
}

class ScreenSize {
  final double width;
  final double height;
  final double maxWidth;
  final double maxHeight;

  ScreenSize(BoxConstraints constraints)
      : width = constraints.maxWidth,
        height = constraints.maxHeight,
        maxWidth = constraints.maxWidth,
        maxHeight = constraints.maxHeight;
}

class WelcomeSection extends StatelessWidget {
  final ScreenSize screenSize;

  const WelcomeSection({required this.screenSize, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontSize = (screenSize.maxHeight * 0.08).clamp(95.0, 105.0);
    final imageWidth = (screenSize.maxWidth * 0.7).clamp(100.0, 350.0);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.containerPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '¡Bienvenido!',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.dorado465,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          Image.asset(
            'assets/logos/bienvenida.jpg',
            width: imageWidth,
          ),
        ],
      ),
    );
  }
}

class ButtonsSection extends StatelessWidget {
  final ScreenSize screenSize;

  const ButtonsSection({required this.screenSize, Key? key}) : super(key: key);

  static const List<MenuButtonData> _menuButtons = [
    MenuButtonData(label: 'Ventanillas', icon: Icons.assignment, route: AppRoutes.ventanillas),
    MenuButtonData(label: 'Administrador', icon: Icons.admin_panel_settings, route: AppRoutes.administrador),
    MenuButtonData(label: 'Pantallas', icon: Icons.tv, route: AppRoutes.pantallas),
    MenuButtonData(label: 'Preregistro', icon: Icons.assignment, route: AppRoutes.preregistro),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _menuButtons.map((buttonData) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.buttonSpacing),
            child: AnimatedServiceButton(
              data: buttonData,
              screenSize: screenSize,
              onPressed: () => _navigateToRoute(context, buttonData.route),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _navigateToRoute(BuildContext context, String route) {
    if (route == AppRoutes.administrador ||
        route == AppRoutes.administracion ||
        route == AppRoutes.fpreregistro ||
        route == AppRoutes.ventanillaturnos) {
      Navigator.of(context).pushNamed(route, arguments: 1); // valor de prueba
    } else {
      Navigator.of(context).pushNamed(route);
    }
  }
}

class AnimatedServiceButton extends StatefulWidget {
  final MenuButtonData data;
  final ScreenSize screenSize;
  final VoidCallback onPressed;

  const AnimatedServiceButton({
    required this.data,
    required this.screenSize,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  _AnimatedServiceButtonState createState() => _AnimatedServiceButtonState();
}

class _AnimatedServiceButtonState extends State<AnimatedServiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: AppConstants.animationDuration),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidth = widget.screenSize.width * 0.20;
    final buttonHeight = widget.screenSize.height * 0.2;
    final iconSize = widget.screenSize.width * 0.04;
    final fontSize = widget.screenSize.width * 0.018;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: buttonWidth,
              height: buttonHeight,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.guinda7421,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.data.icon, color: AppColors.blanco, size: iconSize),
                    const SizedBox(height: 10),
                    Text(
                      widget.data.label,
                      style: TextStyle(
                        color: AppColors.blanco,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
