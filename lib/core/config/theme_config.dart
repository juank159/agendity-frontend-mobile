import 'package:flutter/material.dart';
import 'package:login_signup/core/config/app_palette_colors.dart';
import 'package:login_signup/core/config/app_tokens.dart';
import 'package:login_signup/core/config/color_contrast.dart';

export 'package:login_signup/core/config/app_palette_colors.dart';
export 'package:login_signup/core/config/app_tokens.dart';

/// Variante del tema: el modo del dispositivo ya resuelto (el "sistema" lo
/// resuelve `MaterialApp` con `theme`/`darkTheme`). El alto contraste es
/// oscuro, con negro puro y colores al 7:1.
enum AppThemeVariant { light, dark, highContrast }

/// Acceso corto a los tokens: `context.tokens.success.color`.
/// Si el tema no los registra (p. ej. un test con `MaterialApp` pelado), se
/// usan los de lavanda en el brillo actual.
extension AppTokensContext on BuildContext {
  AppTokens get tokens {
    final theme = Theme.of(this);
    return theme.extension<AppTokens>() ??
        ThemeConfig.tokensFor(
            AppPalette.fallback,
            theme.brightness == Brightness.dark
                ? AppThemeVariant.dark
                : AppThemeVariant.light);
  }
}

/// Temas de Agendity (D-22, guía de diseño 2026-11-02): uno por paleta y
/// variante, con la fuente Plus Jakarta Sans empaquetada, los tokens de
/// `AppTokens` y el tema de todos los componentes. Se construyen una vez y
/// se guardan en caché.
///
/// Contraste: el texto principal y el de los botones cumplen AA (4,5:1; 7:1
/// en alto contraste). Si una semilla no llega, se oscurece o aclara sin
/// cambiar su tono (`ensureContrast`). Lo verifica
/// `test/core/config/theme_contrast_test.dart` en las 18 combinaciones.
abstract final class ThemeConfig {
  /// Familia declarada en `pubspec.yaml` (assets/fonts, licencia OFL).
  static const String fontFamily = 'PlusJakartaSans';

  static final Map<(AppPalette, AppThemeVariant), ThemeData> _themes = {};
  static final Map<(AppPalette, AppThemeVariant), AppTokens> _tokens = {};

  /// Tema de [palette] en [variant] (en caché).
  static ThemeData of(AppPalette palette, AppThemeVariant variant) =>
      _themes.putIfAbsent((palette, variant), () {
        final scheme = schemeFor(palette, variant);
        return _build(scheme, tokensFor(palette, variant), variant);
      });

  /// Lavanda (la paleta por defecto) en claro, oscuro y alto contraste.
  static ThemeData get lightTheme =>
      of(AppPalette.fallback, AppThemeVariant.light);
  static ThemeData get darkTheme =>
      of(AppPalette.fallback, AppThemeVariant.dark);
  static ThemeData get highContrastTheme =>
      of(AppPalette.fallback, AppThemeVariant.highContrast);

  // --- Colores ----------------------------------------------------------------

  /// Esquema de [palette] en [variant], con el contraste AA asegurado.
  static ColorScheme schemeFor(AppPalette palette, AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.light:
        return _lightScheme(palette);
      case AppThemeVariant.dark:
        return _darkScheme(palette);
      case AppThemeVariant.highContrast:
        return _highContrastScheme(palette);
    }
  }

  static ColorScheme _lightScheme(AppPalette palette) {
    final base = ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    const white = Color(0xFFFFFFFF);
    // Primario: la semilla, oscurecida si el texto blanco no llega a AA.
    // También sobre el fondo teñido (texto de los TextButton y enlaces).
    final primary =
        ensureContrast(ensureContrast(palette.seed, white), base.surface);
    final accent = palette.accent;
    final tertiary =
        accent == null ? base.tertiary : ensureContrast(accent, white);
    final scheme = base.copyWith(
      primary: primary,
      onPrimary: white,
      surfaceTint: primary,
      tertiary: tertiary,
      onTertiary: readableOn(tertiary),
      tertiaryContainer: accent == null
          ? base.tertiaryContainer
          : Color.alphaBlend(accent.withValues(alpha: 0.22), white),
    );
    return _withReadableText(scheme);
  }

  static ColorScheme _darkScheme(AppPalette palette) {
    final base = ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final accent = palette.accent;
    final tertiary =
        accent == null ? base.tertiary : ensureContrast(accent, base.surface);
    final scheme = base.copyWith(
      // Primario claro sobre el fondo oscuro (texto de los TextButton).
      primary: ensureContrast(base.primary, base.surface),
      tertiary: tertiary,
      onTertiary: readableOn(tertiary),
    );
    return _withReadableText(scheme.copyWith(
        onPrimary: readableOn(scheme.primary), surfaceTint: scheme.primary));
  }

  static ColorScheme _highContrastScheme(AppPalette palette) {
    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);
    // Un tinte muy claro de la paleta, al 7:1 sobre negro.
    final primary = ensureContrast(
        Color.lerp(palette.seed, white, 0.55)!, black,
        ratio: contrastAAA);
    final accent = palette.accent ?? primary;
    return ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: black,
      primaryContainer: black,
      onPrimaryContainer: primary,
      secondary: primary,
      onSecondary: black,
      secondaryContainer: black,
      onSecondaryContainer: white,
      tertiary: ensureContrast(accent, black, ratio: contrastAAA),
      onTertiary: black,
      tertiaryContainer: black,
      onTertiaryContainer: white,
      error: const Color(0xFFFF8A80),
      onError: black,
      errorContainer: black,
      onErrorContainer: const Color(0xFFFF8A80),
      surface: black,
      onSurface: white,
      onSurfaceVariant: white,
      surfaceContainerLowest: black,
      surfaceContainerLow: const Color(0xFF0A0A0A),
      surfaceContainer: const Color(0xFF111111),
      surfaceContainerHigh: const Color(0xFF161616),
      surfaceContainerHighest: const Color(0xFF1C1C1C),
      outline: primary,
      outlineVariant: white.withValues(alpha: 0.6),
      shadow: black,
      scrim: black,
      inverseSurface: white,
      onInverseSurface: black,
      inversePrimary: black,
      surfaceTint: primary,
    );
  }

  /// Ajusta los textos sobre cada fondo para cumplir AA (los tonos de
  /// `fromSeed` casi siempre llegan; esto cubre los que no).
  static ColorScheme _withReadableText(ColorScheme s) {
    Color on(Color text, Color background) => ensureContrast(text, background);
    return s.copyWith(
      onPrimary: on(s.onPrimary, s.primary),
      onPrimaryContainer: on(s.onPrimaryContainer, s.primaryContainer),
      onSecondary: on(s.onSecondary, s.secondary),
      onSecondaryContainer: on(s.onSecondaryContainer, s.secondaryContainer),
      onTertiaryContainer: on(s.onTertiaryContainer, s.tertiaryContainer),
      onSurface: on(s.onSurface, s.surfaceContainerHighest),
      onSurfaceVariant: on(s.onSurfaceVariant, s.surfaceContainerHighest),
      onError: on(s.onError, s.error),
      onErrorContainer: on(s.onErrorContainer, s.errorContainer),
    );
  }

  /// Tokens de [palette] en [variant] (en caché).
  static AppTokens tokensFor(AppPalette palette, AppThemeVariant variant) =>
      _tokens.putIfAbsent((palette, variant), () {
        final scheme = schemeFor(palette, variant);
        const white = Color(0xFFFFFFFF);
        const black = Color(0xFF000000);
        final highContrast = variant == AppThemeVariant.highContrast;
        final light = variant == AppThemeVariant.light;
        final tones = switch (variant) {
          AppThemeVariant.light => StatusTones.light,
          AppThemeVariant.dark => StatusTones.dark,
          AppThemeVariant.highContrast => StatusTones.highContrast,
        };
        // Degradado vivo con texto blanco (AA en los dos extremos), igual en
        // claro y oscuro; en alto contraste, el primario plano y texto negro.
        final start = highContrast
            ? scheme.primary
            : ensureContrast(palette.gradientPartner, white);
        final end =
            highContrast ? scheme.primary : ensureContrast(palette.seed, white);
        return AppTokens(
          info: tones.info,
          success: tones.success,
          warning: tones.warning,
          error: tones.error,
          statusPending: tones.pending,
          statusConfirmed: tones.confirmed,
          statusCompleted: tones.completed,
          statusCancelled: tones.cancelled,
          gradientStart: start,
          gradientEnd: end,
          onGradient: highContrast ? black : white,
          accent: scheme.tertiary,
          ambientShadow: switch (variant) {
            AppThemeVariant.light =>
              const Color(0xFF1B1530).withValues(alpha: 0.10),
            AppThemeVariant.dark => black.withValues(alpha: 0.32),
            AppThemeVariant.highContrast => black.withValues(alpha: 0),
          },
          tintedShadowOpacity: switch (variant) {
            AppThemeVariant.light => 0.30,
            AppThemeVariant.dark => 0.16,
            AppThemeVariant.highContrast => 0,
          },
          innerBorder: switch (variant) {
            AppThemeVariant.light => white.withValues(alpha: 0.22),
            AppThemeVariant.dark => white.withValues(alpha: 0.10),
            AppThemeVariant.highContrast => white.withValues(alpha: 0.7),
          },
          sheen: switch (variant) {
            AppThemeVariant.light => white.withValues(alpha: 0.22),
            AppThemeVariant.dark => white.withValues(alpha: 0.06),
            AppThemeVariant.highContrast => white.withValues(alpha: 0),
          },
          skeletonBase: scheme.surfaceContainerHighest,
          skeletonHighlight: Color.alphaBlend(
              white.withValues(alpha: light ? 0.7 : 0.08),
              scheme.surfaceContainerHighest),
        );
      });

  // --- Tema -------------------------------------------------------------------

  static ThemeData _build(
      ColorScheme scheme, AppTokens tokens, AppThemeVariant variant) {
    final light = variant == AppThemeVariant.light;
    final highContrast = variant == AppThemeVariant.highContrast;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
    );
    final text = _textTheme(base.textTheme, scheme);
    final fieldFill =
        light ? scheme.surfaceContainerLowest : scheme.surfaceContainerHigh;
    final cardColor =
        light ? scheme.surfaceContainerLowest : scheme.surfaceContainer;
    const buttonShape =
        RoundedRectangleBorder(borderRadius: AppRadii.fieldRadius);
    const buttonSize = Size(64, 52);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    final buttonText =
        text.labelLarge!.copyWith(fontSize: 15, fontWeight: FontWeight.w600);
    const sheetShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    );
    final hcBorder = highContrast
        ? BorderSide(color: scheme.outline, width: 1.5)
        : BorderSide.none;

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        // Limpia y translúcida: el contenido se adivina al desplazarse.
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
          foregroundColor: scheme.primary,
          side: BorderSide(
              color: highContrast ? scheme.outline : scheme.outlineVariant,
              width: highContrast ? 1.5 : 1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: buttonShape,
          textStyle: buttonText,
          foregroundColor: scheme.primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: buttonShape,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: light ? 6 : 2,
        highlightElevation: light ? 8 : 3,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.card))),
        extendedTextStyle: text.labelLarge
            ?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
        extendedSizeConstraints: const BoxConstraints.tightFor(height: 56),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppRadii.fieldRadius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.fieldRadius,
          borderSide: highContrast
              ? BorderSide(color: scheme.outline)
              : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.fieldRadius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.fieldRadius,
          borderSide:
              BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        prefixIconColor: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.focused)
                ? scheme.primary
                : scheme.onSurfaceVariant),
        suffixIconColor: scheme.onSurfaceVariant,
        floatingLabelStyle:
            WidgetStateTextStyle.resolveWith((states) => TextStyle(
                  color: states.contains(WidgetState.error)
                      ? scheme.error
                      : states.contains(WidgetState.focused)
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                )),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        helperStyle: TextStyle(color: scheme.onSurfaceVariant),
        errorStyle: TextStyle(color: scheme.error, fontWeight: FontWeight.w500),
        errorMaxLines: 3,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: tokens.ambientShadow,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardRadius,
          side: highContrast
              ? BorderSide(color: scheme.outline)
              : BorderSide(
                  color: scheme.outlineVariant
                      .withValues(alpha: light ? 0.45 : 0.35)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.chipRadius,
          side: highContrast
              ? BorderSide(color: scheme.outline)
              : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        backgroundColor: fieldFill,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.sheetRadius,
          side: hcBorder,
        ),
        titleTextStyle: text.titleLarge
            ?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w700),
        contentTextStyle:
            text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      // Calendarios (cita, agenda, cumpleaños, rango de Informes; 12.07):
      // radio 28, días con radio de chip, hoy con borde primario y el
      // rango en el contenedor primario.
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheetRadius),
        headerHeadlineStyle:
            text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        headerHelpStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        weekdayStyle: text.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700),
        dayStyle: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        dayShape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadii.chipRadius)),
        todayBorder: BorderSide(color: scheme.primary, width: 1.5),
        yearShape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadii.chipRadius)),
        rangePickerBackgroundColor: scheme.surfaceContainerLow,
        rangePickerSurfaceTintColor: Colors.transparent,
        rangeSelectionBackgroundColor: scheme.primaryContainer,
        dividerColor: scheme.outlineVariant.withValues(alpha: 0.6),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        dragHandleSize: const Size(40, 5),
        shape: sheetShape,
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.fieldRadius),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: light ? 4 : 2,
        contentTextStyle: text.bodyMedium,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.horizontal(right: Radius.circular(AppRadii.sheet)),
        ),
        endShape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.horizontal(left: Radius.circular(AppRadii.sheet)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.fieldRadius),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle: text.bodyLarge
            ?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
        subtitleTextStyle:
            text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.outline),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.surfaceContainerHighest),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.transparent
                : scheme.outline),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6))),
        side: BorderSide(color: scheme.outline, width: 1.6),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.outline),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primaryContainer.withValues(alpha: 0.7),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: scheme.primary,
        valueIndicatorTextStyle:
            text.labelLarge?.copyWith(color: scheme.onPrimary),
      ),
      dividerTheme: DividerThemeData(
        color: highContrast
            ? scheme.outlineVariant
            : scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer.withValues(alpha: 0.6),
        circularTrackColor: Colors.transparent,
        linearMinHeight: 4,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: buttonShape,
          textStyle: buttonText,
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: text.titleSmall,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: AppRadii.chipRadius,
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }

  /// Escala de la guía (§2): títulos w700, subtítulos w600, cuerpo w500/w400
  /// e interlineado generoso.
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle? w(TextStyle? style, FontWeight weight, {double? height}) =>
        style?.copyWith(
          fontFamily: fontFamily,
          fontWeight: weight,
          height: height,
        );
    return base.copyWith(
      displayLarge: w(base.displayLarge, FontWeight.w800),
      displayMedium: w(base.displayMedium, FontWeight.w800),
      displaySmall: w(base.displaySmall, FontWeight.w700),
      headlineLarge: w(base.headlineLarge, FontWeight.w700),
      headlineMedium: w(base.headlineMedium, FontWeight.w700),
      headlineSmall: w(base.headlineSmall, FontWeight.w700),
      titleLarge: w(base.titleLarge, FontWeight.w700, height: 1.3),
      titleMedium: w(base.titleMedium, FontWeight.w600, height: 1.35),
      titleSmall: w(base.titleSmall, FontWeight.w600, height: 1.35),
      bodyLarge: w(base.bodyLarge, FontWeight.w500, height: 1.5),
      bodyMedium: w(base.bodyMedium, FontWeight.w400, height: 1.5),
      bodySmall: w(base.bodySmall, FontWeight.w400, height: 1.45),
      labelLarge: w(base.labelLarge, FontWeight.w600),
      labelMedium: w(base.labelMedium, FontWeight.w600),
      labelSmall: w(base.labelSmall, FontWeight.w600),
    );
  }
}
