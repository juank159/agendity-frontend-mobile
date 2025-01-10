// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:get/route_manager.dart';
// import 'package:login_signup/features/auth/presentation/screen/login_view.dart';
// import 'package:login_signup/utils/global_colors.dart';

// class Splash extends StatelessWidget {
//   const Splash({super.key});

//   @override
//   Widget build(BuildContext context) {
//     Timer(const Duration(seconds: 2), () {
//       Get.to(() => LoginView());
//     });
//     return Scaffold(
//       backgroundColor: GlobalColors.mainColor,
//       body: Center(
//         child: SvgPicture.asset('assets/images/logo.svg', height: 100),
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/route_manager.dart';
import 'package:login_signup/features/auth/presentation/screen/screen.dart';
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

    // Redirigir a LoginView después de 3 segundos
    Timer(const Duration(seconds: 2), () {
      Get.to(() => LoginView());
    });
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
                    _animation.value - 0.2,
                    _animation.value,
                    _animation.value + 0.2,
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
