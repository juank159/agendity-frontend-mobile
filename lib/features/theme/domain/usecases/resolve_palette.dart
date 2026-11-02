import 'package:login_signup/common/enums/app_palette_enum.dart';

/// Paleta que se pinta (regla de D-22): la elegida en el dispositivo; si no
/// hay, la del negocio; si tampoco, lavanda ([AppPalette.fallback]).
///
/// [business] es `BusinessSettings.themePalette` (feature `settings`); sin
/// sesión o antes de cargar la configuración, `null`.
AppPalette resolvePalette(AppPalette? device, AppPalette? business) =>
    device ?? business ?? AppPalette.fallback;
