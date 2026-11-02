import 'package:login_signup/common/enums/app_palette_enum.dart';
import 'package:login_signup/features/settings/domain/entities/opening_hours.dart';

export 'package:login_signup/common/enums/app_palette_enum.dart';
export 'package:login_signup/features/settings/domain/entities/opening_hours.dart';

/// Configuración del negocio (`GET /settings`): zona horaria IANA (6.01,
/// D-15), nombre y slug del link público (8.00), horario de apertura (8.01) y
/// paleta del negocio (12.02, D-22).
class BusinessSettings {
  final String timeZone;

  /// `null` si el negocio aún no tiene nombre.
  final String? name;

  /// Identificador del link público (`/public/businesses/:slug`). Solo
  /// lectura: lo genera el backend la primera vez que se pone el nombre y no
  /// cambia al renombrar. `null` sin nombre.
  final String? slug;

  /// `null` = sin horario configurado (no limita las citas). Un día sin
  /// franjas = cerrado.
  final OpeningHours? openingHours;

  /// Paleta que fija el Owner (`theme_palette`). `null` = sin elegir: la app
  /// usa la del dispositivo o lavanda (`resolvePalette`, feature `theme`).
  final AppPalette? themePalette;

  const BusinessSettings({
    required this.timeZone,
    this.name,
    this.slug,
    this.openingHours,
    this.themePalette,
  });

  bool get hasOpeningHours => openingHours != null;

  /// [clearOpeningHours] deja el negocio sin horario y [clearThemePalette]
  /// sin paleta (no se puede con `null`).
  BusinessSettings copyWith({
    String? timeZone,
    String? name,
    String? slug,
    OpeningHours? openingHours,
    bool clearOpeningHours = false,
    AppPalette? themePalette,
    bool clearThemePalette = false,
  }) =>
      BusinessSettings(
        timeZone: timeZone ?? this.timeZone,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        openingHours:
            clearOpeningHours ? null : openingHours ?? this.openingHours,
        themePalette:
            clearThemePalette ? null : themePalette ?? this.themePalette,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessSettings &&
          other.timeZone == timeZone &&
          other.name == name &&
          other.slug == slug &&
          other.openingHours == openingHours &&
          other.themePalette == themePalette;

  @override
  int get hashCode =>
      Object.hash(timeZone, name, slug, openingHours, themePalette);

  @override
  String toString() =>
      'BusinessSettings(timeZone: $timeZone, name: $name, slug: $slug, '
      'openingHours: $openingHours, themePalette: ${themePalette?.id})';
}
