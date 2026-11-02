import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/shared/widgets/app_card.dart';

/// Marco común de las pantallas de auth (login, registro, verificación,
/// recuperar y restablecer contraseña), guía §5 de la Fase 12:
/// - encabezado con la marca sobre el degradado de la paleta (antes de
///   iniciar sesión, la del dispositivo o lavanda) y el monograma [AuthLogo];
/// - una tarjeta con profundidad que monta sobre el encabezado con el
///   título, el subtítulo y el formulario.
///
/// Solo colores del tema y de los tokens.
class AuthLayout extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// Widget bajo el subtítulo (p. ej. el email al que se envió un código).
  final Widget? subtitleTrailing;
  final List<Widget> children;

  /// Si no es `null`, muestra la flecha de volver.
  final VoidCallback? onBack;

  /// Lado del monograma del encabezado.
  final double logoHeight;

  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleTrailing,
    required this.children,
    this.onBack,
    this.logoHeight = 72,
  });

  /// Cuánto monta la tarjeta sobre el encabezado.
  static const double overlap = 36;

  /// Ancho máximo del formulario (tabletas y escritorio).
  static const double maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trailing = subtitleTrailing;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthBrandHeader(onBack: onBack, logoSize: logoHeight),
            Transform.translate(
              offset: const Offset(0, -overlap),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxWidth),
                  child: AppFadeIn(
                    child: AppCard(
                      depth: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                          if (trailing != null) ...[
                            const SizedBox(height: 10),
                            trailing,
                          ],
                          const SizedBox(height: 24),
                          ...children,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de marca de auth: degradado de la paleta con el borde inferior
/// redondeado, brillo superior, el monograma y el nombre "Agendity".
class AuthBrandHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final double logoSize;

  const AuthBrandHeader({super.key, this.onBack, this.logoSize = 72});

  static const BorderRadius _shape =
      BorderRadius.vertical(bottom: Radius.circular(36));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final back = onBack;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: tokens.primaryGradient,
        borderRadius: _shape,
        boxShadow: tokens.elevation2(),
      ),
      child: DecoratedBox(
        decoration:
            BoxDecoration(gradient: tokens.sheenGradient, borderRadius: _shape),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, AuthLayout.overlap + 28),
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: back == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            color: tokens.onGradient,
                            tooltip: 'Volver',
                            onPressed: back,
                          ),
                  ),
                ),
                AuthLogo(height: logoSize, onGradient: true),
                const SizedBox(height: 14),
                ExcludeSemantics(
                  child: Text(
                    'Agendity',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: tokens.onGradient,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                ExcludeSemantics(
                  child: Text(
                    'Tu agenda, en orden',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.onGradient.withValues(alpha: 0.85)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Monograma "A" de Agendity: un cuadrado redondeado con relieve (brillo
/// superior, borde interior y sombra).
/// - Sobre el degradado ([onGradient]): vidrio translúcido y letra clara.
/// - Sobre una superficie: el degradado de la paleta y letra clara.
class AuthLogo extends StatelessWidget {
  final double height;
  final bool onGradient;

  const AuthLogo({super.key, this.height = 72, this.onGradient = false});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(height * 0.3);
    return Semantics(
      label: 'Agendity',
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: height,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: onGradient ? null : tokens.primaryGradient,
            color: onGradient ? tokens.onGradient.withValues(alpha: 0.16) : null,
            border: Border.all(
                color: onGradient
                    ? tokens.onGradient.withValues(alpha: 0.35)
                    : tokens.innerBorder),
            boxShadow: onGradient ? tokens.elevation1() : tokens.elevation3(),
          ),
          foregroundDecoration:
              BoxDecoration(borderRadius: radius, gradient: tokens.sheenGradient),
          child: Text(
            'A',
            style: TextStyle(
              color: tokens.onGradient,
              fontSize: height * 0.56,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1,
            ),
          ),
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
        TextButton(
          onPressed: onTap,
          child: Text(action,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

/// Píldora con el correo al que se envió un código (verificación y nueva
/// contraseña).
class AuthEmailBadge extends StatelessWidget {
  final String email;

  const AuthEmailBadge({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: AppRadii.chipRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_read_rounded,
                size: 18, color: scheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                email,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
