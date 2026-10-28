import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Marco común de las pantallas de auth (login, registro, recuperar y
/// restablecer contraseña): fondo con el color primario del tema, logo,
/// título y contenido desplazable. Solo colores del `ColorScheme`.
class AuthLayout extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// Widget bajo el subtítulo (p. ej. el email al que se envió un código).
  final Widget? subtitleTrailing;
  final List<Widget> children;

  /// Si no es `null`, muestra la flecha de volver.
  final VoidCallback? onBack;
  final double logoHeight;

  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleTrailing,
    required this.children,
    this.onBack,
    this.logoHeight = 75,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.5),
              scheme.surface,
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onBack != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: scheme.primary,
                      tooltip: 'Volver',
                      onPressed: onBack,
                    ),
                  ),
                const SizedBox(height: 16),
                AuthLogo(height: logoHeight),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
                if (subtitleTrailing != null) ...[
                  const SizedBox(height: 4),
                  subtitleTrailing!,
                ],
                const SizedBox(height: 32),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo de Agendity con el color indicado (por defecto, el primario).
class AuthLogo extends StatelessWidget {
  final double height;
  final Color? color;

  const AuthLogo({super.key, this.height = 75, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SvgPicture.asset(
        'assets/images/logo.svg',
        height: height,
        semanticsLabel: 'Agendity',
        colorFilter: ColorFilter.mode(
          color ?? Theme.of(context).colorScheme.primary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

/// "¿No tienes cuenta? Regístrate" y similares.
class AuthFooterLink extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback? onTap;

  const AuthFooterLink({
    super.key,
    required this.question,
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question, style: TextStyle(color: scheme.onSurfaceVariant)),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }
}
