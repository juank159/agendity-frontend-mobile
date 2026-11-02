import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';

/// DTO de `GET`/`PATCH /settings` (y del documento `business_settings` del
/// feed de sync): `{timezone, name, slug, opening_hours, theme_palette}`
/// (`opening_hours`: `[{day_of_week, start_time, end_time}]` o `null`;
/// `theme_palette`: `lavanda|rosa|azul|turquesa|coral|grafito` o `null`).
class BusinessSettingsModel {
  final String timeZone;
  final String? name;
  final String? slug;
  final OpeningHours? openingHours;
  final AppPalette? themePalette;

  const BusinessSettingsModel({
    required this.timeZone,
    this.name,
    this.slug,
    this.openingHours,
    this.themePalette,
  });

  /// Sin `timezone` no es una respuesta válida (`FormatException` →
  /// `ServerFailure`). Franjas ilegibles (sin día de 1 a 7) se descartan.
  /// Una paleta que falta (backend anterior a 12.01, documento local viejo) o
  /// desconocida cuenta como `null`, igual que en el backend.
  factory BusinessSettingsModel.fromJson(Map<String, dynamic>? json) {
    final timeZone = JsonRead.asOptionalString(json?['timezone']);
    if (timeZone == null) {
      throw const FormatException('Configuración del negocio sin zona');
    }
    final rawHours = json?['opening_hours'];
    return BusinessSettingsModel(
      timeZone: timeZone,
      name: JsonRead.asOptionalString(json?['name']),
      slug: JsonRead.asOptionalString(json?['slug']),
      openingHours: rawHours is List ? _readHours(rawHours) : null,
      themePalette: AppPalette.fromId(json?['theme_palette']),
    );
  }

  static OpeningHours _readHours(List<dynamic> raw) => OpeningHours([
        for (final row in JsonRead.asMapList(raw))
          if (JsonRead.asInt(row['day_of_week']) case final day
              when day >= OpeningHoursRange.monday &&
                  day <= OpeningHoursRange.sunday)
            OpeningHoursRange(
              dayOfWeek: day,
              hours: WorkHours(
                start:
                    WorkHours.normalize(JsonRead.asString(row['start_time'])),
                end: WorkHours.normalize(JsonRead.asString(row['end_time'])),
              ),
            ),
      ]);

  /// Cuerpos de `PATCH /settings` (`UpdateSettingsDto`): un campo por cambio.
  static Map<String, dynamic> timeZoneUpdate(String timeZone) =>
      {'timezone': timeZone};

  static Map<String, dynamic> nameUpdate(String name) => {'name': name};

  /// `null` = quitar el horario; `[]` = cerrado todos los días.
  static Map<String, dynamic> openingHoursUpdate(OpeningHours? hours) => {
        'opening_hours': hours == null
            ? null
            : [
                for (final range in hours.ranges)
                  {
                    'day_of_week': range.dayOfWeek,
                    'start_time': range.start,
                    'end_time': range.end,
                  },
              ],
      };

  /// `null` = sin paleta (la app usa la del dispositivo o lavanda).
  static Map<String, dynamic> themePaletteUpdate(AppPalette? palette) =>
      {'theme_palette': palette?.id};

  BusinessSettings toEntity() => BusinessSettings(
        timeZone: timeZone,
        name: name,
        slug: slug,
        openingHours: openingHours,
        themePalette: themePalette,
      );

  /// Forma de la API (para guardar en local la respuesta de un PATCH).
  Map<String, dynamic> toJson() => {
        'timezone': timeZone,
        'name': name,
        'slug': slug,
        ...openingHoursUpdate(openingHours),
        ...themePaletteUpdate(themePalette),
      };
}
