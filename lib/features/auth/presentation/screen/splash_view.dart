import 'package:login_signup/core/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/shared/controller/session_controller.dart';
import 'package:login_signup/utils/global_colors.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Configurar el controlador de animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Duración de la animación completa
    )..repeat(reverse: false); // Repetir la animación

    // Definir la animación como un Tween de 0.0 a 1.0
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );

    _routeAfterSplash();
  }

  /// Auto-login: con una sesión guardada válida va a la home; si no, al login.
  /// Espera a la vez la animación mínima y la lectura de la sesión.
  Future<void> _routeAfterSplash() async {
    Session? session;
    await Future.wait([
      Future<void>.delayed(const Duration(seconds: 2)),
      Get.find<SessionController>().restore().then((value) => session = value,
          onError: (Object _) => session = null),
    ]);
    if (!mounted) return;
    Get.offAllNamed(session != null ? GetRoutes.home : GetRoutes.login);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.mainColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white,
                    Colors.white.withOpacity(0.1),
                  ],
                  stops: [
                    (_animation.value - 0.2).clamp(0.0, 1.0),
                    _animation.value.clamp(0.0, 1.0),
                    (_animation.value + 0.2).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds);
              },
              child: SvgPicture.asset(
                'assets/images/logo.svg',
                height: 100,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            );
          },
        ),
      ),
    );
  }
}
