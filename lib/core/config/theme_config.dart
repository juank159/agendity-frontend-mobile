import 'package:flutter/material.dart';
import 'package:login_signup/common/enums/appointment_status_enum.dart';

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
}

/// Tokens de color de Agendity que no están en [ColorScheme]: tonos de
/// feedback y colores de estado de cita. Se leen con `context.tokens`.
///
/// Regla (ARQUITECTURA §2.2): las pantallas no usan `Colors.*` fijos; usan
/// `Theme.of(context).colorScheme` o estos tokens, que cambian con el tema.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final ToneColors info;
  final ToneColors success;
  final ToneColors warning;
  final ToneColors error;

  /// Estados de cita. `CONFIRMED` usa verde azulado (teal) y no azul: el azul
  /// es el color primario (botones y acciones) y un chip azul se confundía con
  /// un control; además el azul ya es "reembolsado" en los pagos.
  final ToneColors statusPending;
  final ToneColors statusConfirmed;
  final ToneColors statusCompleted;
  final ToneColors statusCancelled;

  const AppTokens({
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
    required this.statusPending,
    required this.statusConfirmed,
    required this.statusCompleted,
    required this.statusCancelled,
  });

  ToneColors tone(AppTone tone) {
    switch (tone) {
      case AppTone.info:
        return info;
      case AppTone.success:
        return success;
      case AppTone.warning:
        return warning;
      case AppTone.error:
        return error;
    }
  }

  ToneColors appointmentStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.PENDING:
        return statusPending;
      case AppointmentStatus.CONFIRMED:
        return statusConfirmed;
      case AppointmentStatus.COMPLETED:
        return statusCompleted;
      case AppointmentStatus.CANCELLED:
        return statusCancelled;
    }
  }

  static const light = AppTokens(
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
      color: Color(0xFFE65100),
      container: Color(0xFFFFF3E0),
      onContainer: Color(0xFF8A3A00),
    ),
    error: ToneColors(
      color: Color(0xFFC62828),
      container: Color(0xFFFFEBEE),
      onContainer: Color(0xFF8E0000),
    ),
    statusPending: ToneColors(
      color: Color(0xFFEF6C00),
      container: Color(0xFFFFF3E0),
      onContainer: Color(0xFF8A3A00),
    ),
    statusConfirmed: ToneColors(
      color: Color(0xFF00838F),
      container: Color(0xFFE0F7FA),
      onContainer: Color(0xFF004D55),
    ),
    statusCompleted: ToneColors(
      color: Color(0xFF2E7D32),
      container: Color(0xFFE8F5E9),
      onContainer: Color(0xFF1B5E20),
    ),
    statusCancelled: ToneColors(
      color: Color(0xFFC62828),
      container: Color(0xFFFFEBEE),
      onContainer: Color(0xFF8E0000),
    ),
  );

  static const dark = AppTokens(
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
    statusPending: ToneColors(
      color: Color(0xFFFFB74D),
      container: Color(0xFF5C3300),
      onContainer: Color(0xFFFFE6C7),
    ),
    statusConfirmed: ToneColors(
      color: Color(0xFF80DEEA),
      container: Color(0xFF00424A),
      onContainer: Color(0xFFD2F6FA),
    ),
    statusCompleted: ToneColors(
      color: Color(0xFFA5D6A7),
      container: Color(0xFF1B4D20),
      onContainer: Color(0xFFDDF3DE),
    ),
    statusCancelled: ToneColors(
      color: Color(0xFFEF9A9A),
      container: Color(0xFF5F1414),
      onContainer: Color(0xFFFFDADA),
    ),
  );

  /// Alto contraste: fondos negros y colores saturados.
  static const highContrast = AppTokens(
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
    statusPending: ToneColors(
      color: Color(0xFFFFD740),
      container: Color(0xFF000000),
      onContainer: Color(0xFFFFFFFF),
    ),
    statusConfirmed: ToneColors(
      color: Color(0xFF84FFFF),
      container: Color(0xFF000000),
      onContainer: Color(0xFFFFFFFF),
    ),
    statusCompleted: ToneColors(
      color: Color(0xFF69F0AE),
      container: Color(0xFF000000),
      onContainer: Color(0xFFFFFFFF),
    ),
    statusCancelled: ToneColors(
      color: Color(0xFFFF8A80),
      container: Color(0xFF000000),
      onContainer: Color(0xFFFFFFFF),
    ),
  );

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
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
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
    );
  }
}

/// Acceso corto a los tokens: `context.tokens.success.color`.
/// Si el tema no los registra (p. ej. un test con `MaterialApp` pelado), se
/// usan los del brillo actual.
extension AppTokensContext on BuildContext {
  AppTokens get tokens {
    final theme = Theme.of(this);
    return theme.extension<AppTokens>() ??
        (theme.brightness == Brightness.dark ? AppTokens.dark : AppTokens.light);
  }
}

class ThemeConfig {
  /// Color semilla de la marca (el azul que la app ya usaba).
  static const Color seedColor = Color(0xFF2196F3);

  static final ThemeData lightTheme = _build(
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        AppTokens.light,
      );

  static final ThemeData darkTheme = _build(
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        AppTokens.dark,
      );

  /// Alto contraste (oscuro). Se aplica como `darkTheme` con `ThemeMode.dark`
  /// desde `ThemeController`.
  static final ThemeData highContrastTheme = _build(
        const ColorScheme.dark(
          primary: Color(0xFFFFEB3B),
          onPrimary: Color(0xFF000000),
          secondary: Color(0xFFFFFF00),
          onSecondary: Color(0xFF000000),
          surface: Color(0xFF000000),
          onSurface: Color(0xFFFFFFFF),
          onSurfaceVariant: Color(0xFFFFFFFF),
          error: Color(0xFFFF8A80),
          onError: Color(0xFF000000),
          outline: Color(0xFFFFEB3B),
        ),
        AppTokens.highContrast,
      );

  static ThemeData _build(ColorScheme scheme, AppTokens tokens) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        shadowColor: scheme.shadow.withValues(alpha: 0.2),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        dayPeriodBorderSide: BorderSide(color: scheme.outlineVariant),
        dayPeriodTextStyle: const TextStyle(fontSize: 16),
        hourMinuteTextStyle: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
        helpTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }
}
