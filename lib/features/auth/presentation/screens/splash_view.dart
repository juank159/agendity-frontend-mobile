import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_layout.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';

/// Arranque: restaura la sesión guardada (auto-login) mientras un brillo
/// recorre la marca sobre el degradado de la paleta (sin animación si el
/// sistema las desactiva) y va a la home o al login.
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
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final light = tokens.onGradient;
    final animate = AppMotion.enabled(context);
    final logo = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AuthLogo(height: 104, onGradient: true),
        const SizedBox(height: 20),
        Text(
          'Agendity',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: light,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: tokens.primaryGradient),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: tokens.sheenGradient),
          child: Center(
            child: !animate
                ? logo
                : AnimatedBuilder(
                    animation: _position,
                    builder: (context, child) {
                      final x = _position.value;
                      return ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            light.withValues(alpha: 0.55),
                            light,
                            light.withValues(alpha: 0.55),
                          ],
                          stops: [
                            (x - 0.2).clamp(0.0, 1.0),
                            x.clamp(0.0, 1.0),
                            (x + 0.2).clamp(0.0, 1.0),
                          ],
                        ).createShader(bounds),
                        blendMode: BlendMode.modulate,
                        child: child,
                      );
                    },
                    child: logo,
                  ),
          ),
        ),
      ),
    );
  }
}
