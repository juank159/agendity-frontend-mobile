import 'package:login_signup/core/utils/business_time_zone.dart';

/// Fechas en el contrato HTTP (ARQUITECTURA.md §3; zona por negocio, D-15).
///
/// En la app un `DateTime` no UTC es una **hora de pared del negocio**
/// (`BusinessTimeZone`), nunca la del dispositivo:
/// - **Enviar** un instante: [encode] interpreta la hora de pared en la zona
///   del negocio y la envía en UTC (`…Z`). Un `DateTime` UTC ya es un
///   instante y va tal cual. Nunca se envía un ISO sin offset.
/// - **Enviar** un día (estadísticas, huecos libres): [encodeDay] →
///   `yyyy-MM-dd`, que el backend entiende como el día completo del negocio.
/// - **Recibir**: [decode]/[tryDecode] → hora de pared en la zona del negocio
///   o, si el registro trae la suya (`timezone` de citas y pagos, 6.03), en
///   esa. Así un negocio de Caracas ve sus horas de Caracas aunque el
///   teléfono esté en Bogotá.
abstract final class DateCodec {
  static String encode(DateTime value) =>
      BusinessTimeZone.toInstant(value).toIso8601String();

  static String? encodeOrNull(DateTime? value) =>
      value == null ? null : encode(value);

  /// Día de calendario tal como lo ve el usuario (sin convertir de zona).
  static String encodeDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// Lanza `FormatException` si [value] no es una fecha ISO 8601. [timeZone]:
  /// zona propia del registro (si falta o no se conoce, la del negocio).
  static DateTime decode(String value, {String? timeZone}) =>
      _toWall(DateTime.parse(value.trim()), value, timeZone);

  /// `null` si el valor falta, está vacío o no es una fecha. Acepta también un
  /// `DateTime`: si es UTC (un instante) lo pasa a hora de pared; si no, ya lo
  /// es y se devuelve tal cual.
  static DateTime? tryDecode(Object? value, {String? timeZone}) {
    if (value is DateTime) {
      return value.isUtc
          ? BusinessTimeZone.toWallClock(value, _zone(timeZone))
          : value;
    }
    if (value is! String || value.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(value.trim());
    return parsed == null ? null : _toWall(parsed, value, timeZone);
  }

  /// Zona propia del registro si se conoce; si no, `null` (= la del negocio).
  static String? _zone(String? timeZone) =>
      BusinessTimeZone.canonicalName(timeZone);

  /// Una zona de registro que la base de datos de la app no conoce (más nueva
  /// que la del paquete) no cae en la del negocio: se usa la hora escrita, que
  /// el backend ya envía con el offset de esa zona.
  static DateTime _toWall(DateTime parsed, String raw, String? timeZone) {
    // Sin offset (fuera del contrato) ya es una hora de pared del negocio.
    if (!parsed.isUtc) return parsed;
    final hasOwnZone = timeZone != null && timeZone.trim().isNotEmpty;
    if (hasOwnZone && _zone(timeZone) == null) {
      final written = _writtenWallClock(raw);
      if (written != null) return written;
    }
    return BusinessTimeZone.toWallClock(parsed, _zone(timeZone));
  }

  static final _offsetSuffix = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

  /// La fecha y hora escritas en [raw], sin su offset.
  static DateTime? _writtenWallClock(String raw) {
    final text = raw.trim();
    final match = _offsetSuffix.firstMatch(text);
    if (match == null) return null;
    final local = DateTime.tryParse(text.substring(0, match.start));
    return local == null || local.isUtc ? null : local;
  }

  static final _dayPrefix = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');

  /// Inverso de [encodeDay]: un día del negocio → `DateTime(y, m, d)` a
  /// medianoche, **sin convertir de zona**. Acepta `"2026-10-21"` (desglose
  /// diario) y también un instante con el offset del negocio
  /// (`"2026-10-21T23:59:59.999-05:00"`, límites de un período): se queda con
  /// la fecha escrita, que es el día del negocio (aunque el negocio haya
  /// cambiado de zona después).
  /// `null` si falta o no empieza por `yyyy-MM-dd`.
  static DateTime? tryDecodeDay(Object? value) {
    if (value is DateTime) return DateTime(value.year, value.month, value.day);
    if (value is! String) return null;
    final match = _dayPrefix.firstMatch(value.trim());
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    // Rechaza días imposibles ("2026-02-30" normalizaría a marzo).
    return date.month == month && date.day == day ? date : null;
  }
}
