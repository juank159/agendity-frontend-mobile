import 'package:flutter/material.dart';
import 'package:login_signup/common/enums/appointment_status_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';

/// Tono semántico de un mensaje o estado (snackbars, diálogos, chips).
enum AppTone { info, success, warning, error }

/// Par de colores para pintar un tono: [color] para iconos y texto destacado,
/// [container] para fondos suaves y [onContainer] para el texto sobre ese fondo.
@immutable
class ToneColors {
  final Color color;
  final Color container;
  final Color onContainer;

  const ToneColors({
    required this.color,
    required this.container,
    required this.onContainer,
  });

  static ToneColors lerp(ToneColors a, ToneColors b, double t) => ToneColors(
        color: Color.lerp(a.color, b.color, t)!,
        container: Color.lerp(a.container, b.container, t)!,
        onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
      );

  @override
  bool operator ==(Object other) =>
      other is ToneColors &&
      other.color == color &&
      other.container == container &&
      other.onContainer == onContainer;

  @override
  int get hashCode => Object.hash(color, container, onContainer);
}

/// Tonos de estado (feedback y estados de cita). **No cambian con la paleta**
/// (guía §1): solo con el modo.
@immutable
class StatusTones {
  final ToneColors info;
  final ToneColors success;
  final ToneColors warning;
  final ToneColors error;

  /// Estados de cita. `CONFIRMED` usa verde azulado (teal) y no azul: un chip
  /// azul se confundía con un control y el azul ya es "reembolsado".
  final ToneColors pending;
  final ToneColors confirmed;
  final ToneColors completed;
  final ToneColors cancelled;

  const StatusTones({
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
    required this.pending,
    required this.confirmed,
    required this.completed,
    required this.cancelled,
  });

  static const light = StatusTones(
    info: ToneColors(
      color: Color(0xFF1565C0),
      container: Color(0xFFE3F2FD),
      onContainer: Color(0xFF0D47A1),
    ),
    success: ToneColors(
      color: Color(0xFF2E7D32),
      container: Color(0xFFE8F5E9),
      onContainer: Color(0xFF1B5E20),
    ),
    warning: ToneColors(
      color: Color(0xFFB84300),
      container: Color(0xFFFFF3E0),
      onContainer: Color(0xFF8A3A00),
    ),
    error: ToneColors(
      color: Color(0xFFC62828),
      container: Color(0xFFFFEBEE),
      onContainer: Color(0xFF8E0000),
    ),
    pending: ToneColors(
      color: Color(0xFFB84300),
      container: Color(0xFFFFF3E0),
      onContainer: Color(0xFF8A3A00),
    ),
    confirmed: ToneColors(
      color: Color(0xFF00838F),
      container: Color(0xFFE0F7FA),
      onContainer: Color(0xFF004D55),
    ),
    completed: ToneColors(
      color: Color(0xFF2E7D32),
      container: Color(0xFFE8F5E9),
      onContainer: Color(0xFF1B5E20),
    ),
    cancelled: ToneColors(
      color: Color(0xFFC62828),
      container: Color(0xFFFFEBEE),
      onContainer: Color(0xFF8E0000),
    ),
  );

  static const dark = StatusTones(
    info: ToneColors(
      color: Color(0xFF90CAF9),
      container: Color(0xFF0D3A66),
      onContainer: Color(0xFFD6EAFF),
    ),
    success: ToneColors(
      color: Color(0xFFA5D6A7),
      container: Color(0xFF1B4D20),
      onContainer: Color(0xFFDDF3DE),
    ),
    warning: ToneColors(
      color: Color(0xFFFFB74D),
      container: Color(0xFF5C3300),
      onContainer: Color(0xFFFFE6C7),
    ),
    error: ToneColors(
      color: Color(0xFFEF9A9A),
      container: Color(0xFF5F1414),
      onContainer: Color(0xFFFFDADA),
    ),
    pending: ToneColors(
      color: Color(0xFFFFB74D),
      container: Color(0xFF5C3300),
      onContainer: Color(0xFFFFE6C7),
    ),
    confirmed: ToneColors(
      color: Color(0xFF80DEEA),
      container: Color(0xFF00424A),
      onContainer: Color(0xFFD2F6FA),
    ),
    completed: ToneColors(
      color: Color(0xFFA5D6A7),
      container: Color(0xFF1B4D20),
      onContainer: Color(0xFFDDF3DE),
    ),
    cancelled: ToneColors(
      color: Color(0xFFEF9A9A),
      container: Color(0xFF5F1414),
      onContainer: Color(0xFFFFDADA),
    ),
  );

  /// Alto contraste: fondos negros y colores saturados.
  static const highContrast = StatusTones(
    info: ToneColors(
      color: Color(0xFF82B1FF),
      container: Color(0xFF000000),
      onContainer: Color(0xFFFFFFFF),
    ),
    success: ToneColors(
      color: Color(0xFF69F0AE),
      container: Color(0xFF000000),
      onContainer: Color(0xFFFFFFFF),
    ),
    warning: ToneColors(
      color: Color(0xFFFFD740),
      container: Color(0xFF000000),
      onContainer: Color(0xFFFFFFFF),
    ),
    error: ToneColors(
      color: Color(0xFFFF8A80),
      container: Color(0xFF000000),
      onContainer: Color(0xFFFFFFFF),
    ),
    pending: ToneColors(
      color: Color(0xFFFFD740),
      container: Color(0xFF000000),
      onContainer: Color(0xFFFFFFFF),
    ),
    confirmed: ToneColors(
      color: Color(0xFF84FFFF),
      container: Color(0xFF000000),
      onContainer: Color(0xFFFFFFFF),
    ),
    completed: ToneColors(
      color: Color(0xFF69F0AE),
      container: Color(0xFF000000),
      onContainer: Color(0xFFFFFFFF),
    ),
    cancelled: ToneColors(
      color: Color(0xFFFF8A80),
      container: Color(0xFF000000),
      onContainer: Color(0xFFFFFFFF),
    ),
  );
}

/// Radios de la guía (§2).
abstract final class AppRadii {
  /// Tarjetas.
  static const double card = 20;

  /// Campos y botones.
  static const double field = 14;

  /// Chips.
  static const double chip = 12;

  /// Hojas inferiores y diálogos.
  static const double sheet = 28;

  static const BorderRadius cardRadius =
      BorderRadius.all(Radius.circular(card));
  static const BorderRadius fieldRadius =
      BorderRadius.all(Radius.circular(field));
  static const BorderRadius chipRadius =
      BorderRadius.all(Radius.circular(chip));
  static const BorderRadius sheetRadius =
      BorderRadius.all(Radius.circular(sheet));
}

/// Movimiento de la guía (§2): 150–250 ms con `easeOutCubic`; al pulsar, se
/// encoge al 0,97. Sin animaciones si el sistema las desactiva.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 250);
  static const Curve curve = Curves.easeOutCubic;

  /// Escala de un botón o una tarjeta mientras se pulsa.
  static const double pressedScale = 0.97;

  /// `false` si el usuario pidió quitar las animaciones.
  static bool enabled(BuildContext context) =>
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  /// [duration], o cero sin animaciones.
  static Duration of(BuildContext context, [Duration duration = medium]) =>
      enabled(context) ? duration : Duration.zero;
}

/// Cifras tabulares (montos y horas que no "bailan" al cambiar).
extension TabularFigures on TextStyle {
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

/// Tokens de Agendity que no están en [ColorScheme]: tonos de estado,
/// profundidad "3D", degradados de la paleta y esqueletos. Se leen con
/// `context.tokens`. Los construye `ThemeConfig` por paleta y modo.
///
/// Regla (ARQUITECTURA §2.2): las pantallas no usan `Colors.*` fijos; usan
/// `Theme.of(context).colorScheme` o estos tokens, que cambian con el tema.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final ToneColors info;
  final ToneColors success;
  final ToneColors warning;
  final ToneColors error;
  final ToneColors statusPending;
  final ToneColors statusConfirmed;
  final ToneColors statusCompleted;
  final ToneColors statusCancelled;

  /// Degradado principal de la paleta (botón principal, FAB, cabeceras y
  /// avatares): de [gradientStart] arriba a la izquierda a [gradientEnd].
  final Color gradientStart;
  final Color gradientEnd;

  /// Texto e iconos sobre el degradado (contraste AA con los dos extremos).
  final Color onGradient;

  /// Acento de la paleta (grafito: dorado; las demás, el terciario).
  final Color accent;

  /// Sombra ambiental (suave y amplia) y su intensidad por modo.
  final Color ambientShadow;

  /// Opacidad de la capa de luz teñida (más corta, del color del elemento).
  final double tintedShadowOpacity;

  /// Borde interior de 1 px de las superficies elevadas (blanco al 20–25 %
  /// en claro; en oscuro, más visible y con menos sombra).
  final Color innerBorder;

  /// Brillo superior: blanco translúcido arriba que se desvanece abajo.
  final Color sheen;

  /// Esqueletos de carga: base y brillo.
  final Color skeletonBase;
  final Color skeletonHighlight;

  const AppTokens({
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
    required this.statusPending,
    required this.statusConfirmed,
    required this.statusCompleted,
    required this.statusCancelled,
    required this.gradientStart,
    required this.gradientEnd,
    required this.onGradient,
    required this.accent,
    required this.ambientShadow,
    required this.tintedShadowOpacity,
    required this.innerBorder,
    required this.sheen,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  /// Tokens de lavanda (la paleta por defecto) en cada variante.
  static AppTokens get light =>
      ThemeConfig.tokensFor(AppPalette.fallback, AppThemeVariant.light);
  static AppTokens get dark =>
      ThemeConfig.tokensFor(AppPalette.fallback, AppThemeVariant.dark);
  static AppTokens get highContrast =>
      ThemeConfig.tokensFor(AppPalette.fallback, AppThemeVariant.highContrast);

  ToneColors tone(AppTone tone) => switch (tone) {
        AppTone.info => info,
        AppTone.success => success,
        AppTone.warning => warning,
        AppTone.error => error,
      };

  ToneColors appointmentStatus(AppointmentStatus status) => switch (status) {
        AppointmentStatus.PENDING => statusPending,
        AppointmentStatus.CONFIRMED => statusConfirmed,
        AppointmentStatus.COMPLETED => statusCompleted,
        AppointmentStatus.CANCELLED => statusCancelled,
      };

  /// Degradado principal (arriba a la izquierda → abajo a la derecha).
  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientStart, gradientEnd],
      );

  /// Degradado de un color de datos (p. ej. el de un servicio): más claro
  /// arriba a la izquierda y el color base abajo.
  LinearGradient gradientOf(Color base) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(base, const Color(0xFFFFFFFF), 0.18)!, base],
      );

  /// Brillo superior para pintar encima de una superficie elevada.
  LinearGradient get sheenGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [sheen, sheen.withValues(alpha: 0)],
        stops: const [0, 0.55],
      );

  /// Profundidad baja (chips, campos destacados).
  List<BoxShadow> elevation1({Color? tint}) => _shadows(1, tint);

  /// Profundidad media (tarjetas).
  List<BoxShadow> elevation2({Color? tint}) => _shadows(2, tint);

  /// Profundidad alta (botón principal, FAB, tarjeta de cita "3D").
  List<BoxShadow> elevation3({Color? tint}) => _shadows(3, tint);

  /// Dos capas (guía §2): ambiental amplia + luz corta teñida con [tint]
  /// (por defecto, el final del degradado de la paleta).
  List<BoxShadow> _shadows(int level, Color? tint) {
    final light = tint ?? gradientEnd;
    final ambientAlpha = ambientShadow.a;
    return [
      BoxShadow(
        color:
            ambientShadow.withValues(alpha: ambientAlpha * (0.6 + 0.2 * level)),
        blurRadius: 10.0 + 12 * level,
        spreadRadius: -2.0 * level,
        offset: Offset(0, 3.0 + 5 * level),
      ),
      BoxShadow(
        color: light.withValues(
            alpha: (tintedShadowOpacity * (0.5 + 0.25 * level)).clamp(0, 1)),
        blurRadius: 3.0 + 4 * level,
        spreadRadius: -1,
        offset: Offset(0, 1.0 + 2 * level),
      ),
    ];
  }

  @override
  AppTokens copyWith({
    ToneColors? info,
    ToneColors? success,
    ToneColors? warning,
    ToneColors? error,
    ToneColors? statusPending,
    ToneColors? statusConfirmed,
    ToneColors? statusCompleted,
    ToneColors? statusCancelled,
    Color? gradientStart,
    Color? gradientEnd,
    Color? onGradient,
    Color? accent,
    Color? ambientShadow,
    double? tintedShadowOpacity,
    Color? innerBorder,
    Color? sheen,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) {
    return AppTokens(
      info: info ?? this.info,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      statusPending: statusPending ?? this.statusPending,
      statusConfirmed: statusConfirmed ?? this.statusConfirmed,
      statusCompleted: statusCompleted ?? this.statusCompleted,
      statusCancelled: statusCancelled ?? this.statusCancelled,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      onGradient: onGradient ?? this.onGradient,
      accent: accent ?? this.accent,
      ambientShadow: ambientShadow ?? this.ambientShadow,
      tintedShadowOpacity: tintedShadowOpacity ?? this.tintedShadowOpacity,
      innerBorder: innerBorder ?? this.innerBorder,
      sheen: sheen ?? this.sheen,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      info: ToneColors.lerp(info, other.info, t),
      success: ToneColors.lerp(success, other.success, t),
      warning: ToneColors.lerp(warning, other.warning, t),
      error: ToneColors.lerp(error, other.error, t),
      statusPending: ToneColors.lerp(statusPending, other.statusPending, t),
      statusConfirmed:
          ToneColors.lerp(statusConfirmed, other.statusConfirmed, t),
      statusCompleted:
          ToneColors.lerp(statusCompleted, other.statusCompleted, t),
      statusCancelled:
          ToneColors.lerp(statusCancelled, other.statusCancelled, t),
      gradientStart: c(gradientStart, other.gradientStart),
      gradientEnd: c(gradientEnd, other.gradientEnd),
      onGradient: c(onGradient, other.onGradient),
      accent: c(accent, other.accent),
      ambientShadow: c(ambientShadow, other.ambientShadow),
      tintedShadowOpacity: tintedShadowOpacity +
          (other.tintedShadowOpacity - tintedShadowOpacity) * t,
      innerBorder: c(innerBorder, other.innerBorder),
      sheen: c(sheen, other.sheen),
      skeletonBase: c(skeletonBase, other.skeletonBase),
      skeletonHighlight: c(skeletonHighlight, other.skeletonHighlight),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppTokens &&
          other.info == info &&
          other.success == success &&
          other.warning == warning &&
          other.error == error &&
          other.statusPending == statusPending &&
          other.statusConfirmed == statusConfirmed &&
          other.statusCompleted == statusCompleted &&
          other.statusCancelled == statusCancelled &&
          other.gradientStart == gradientStart &&
          other.gradientEnd == gradientEnd &&
          other.onGradient == onGradient &&
          other.accent == accent &&
          other.ambientShadow == ambientShadow &&
          other.tintedShadowOpacity == tintedShadowOpacity &&
          other.innerBorder == innerBorder &&
          other.sheen == sheen &&
          other.skeletonBase == skeletonBase &&
          other.skeletonHighlight == skeletonHighlight;

  @override
  int get hashCode => Object.hashAll([
        info,
        success,
        warning,
        error,
        statusPending,
        statusConfirmed,
        statusCompleted,
        statusCancelled,
        gradientStart,
        gradientEnd,
        onGradient,
        accent,
        ambientShadow,
        tintedShadowOpacity,
        innerBorder,
        sheen,
        skeletonBase,
        skeletonHighlight,
      ]);
}
