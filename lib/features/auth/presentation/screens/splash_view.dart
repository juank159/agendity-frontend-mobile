import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_layout.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';

/// Arranque: restaura la sesión guardada (auto-login) mientras anima el logo
/// y va a la home o al login.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  static const _minimumDuration = Duration(seconds: 2);

  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  late final Animation<double> _position = Tween<double>(begin: -1, end: 2)
      .animate(CurvedAnimation(parent: _shine, curve: Curves.linear));

  @override
  void initState() {
    super.initState();
    _routeAfterSplash();
  }

  Future<void> _routeAfterSplash() async {
    Session? session;
    await Future.wait([
      Future<void>.delayed(_minimumDuration),
      Get.find<SessionController>().restore().then((value) => session = value,
          onError: (Object _) => session = null),
    ]);
    if (!mounted) return;
    Get.offAllNamed(session != null ? GetRoutes.home : GetRoutes.login);
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = scheme.onPrimary;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _position,
          builder: (context, child) {
            final x = _position.value;
            return ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  light.withValues(alpha: 0.1),
                  light,
                  light.withValues(alpha: 0.1),
                ],
                stops: [
                  (x - 0.2).clamp(0.0, 1.0),
                  x.clamp(0.0, 1.0),
                  (x + 0.2).clamp(0.0, 1.0),
                ],
              ).createShader(bounds),
              child: child,
            );
          },
          child: AuthLogo(height: 100, color: light),
        ),
      ),
    );
  }
}
