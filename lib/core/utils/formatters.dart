import 'package:flutter/material.dart' show TimeOfDay;
import 'package:intl/intl.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';

/// Formatos de presentación de Agendity (moneda COP, fechas y horas en
/// español). **Único** sitio con `NumberFormat`/`DateFormat` para la UI.
///
/// Las fechas del contrato HTTP no van aquí: son de `DateCodec`.
/// Los formatos de fecha usan el locale `es`, que `main.dart` inicializa con
/// `initializeDateFormatting('es')`.

final NumberFormat _copGrouping = NumberFormat('#,##0', 'es_CO');

/// `45000` → `$ 45.000`. Sin decimales (el peso no los usa).
///
/// Acepta `num` o texto numérico (`"45000.00"`, como llega `totalPrice` en
/// las citas). `null` o un texto no numérico → `$ 0`.
String formatCop(Object? value) {
  final amount = _toNum(value).round();
  final formatted = '\$ ${formatCopDigits(amount.abs())}';
  return amount < 0 ? '-$formatted' : formatted;
}

/// `15000` → `15.000`: el monto sin el símbolo, como se ve dentro de un campo
/// de dinero (`CopInputFormatter`, D-24). Negativo → `-15.000`.
String formatCopDigits(int amount) => _copGrouping.format(amount);

/// Máximo de dígitos de un monto en pesos (cabe de sobra en un `int`).
const int copMaxDigits = 15;

/// Texto escrito o pegado → pesos (D-24), o `null` si no hay un monto:
/// `"15.000"`, `"$ 15.000"`, `"15000"` → `15000`. Los puntos y espacios son
/// separadores de miles. Una cola de 1 o 2 decimales (`"15.000,50"`,
/// `"45000.00"`) se descarta: el peso no usa decimales y los grupos de miles
/// siempre tienen 3 cifras. Vacío, sin dígitos, negativo o más de
/// [copMaxDigits] cifras → `null`.
int? parseCop(String? text) {
  if (text == null || text.contains('-')) return null;
  final digits = copDigitsOf(text, dropDecimals: true);
  if (digits.isEmpty || digits.length > copMaxDigits) return null;
  return int.parse(digits);
}

final RegExp _copDecimalTail = RegExp(r'[.,]\d{1,2}\s*$');
final RegExp _nonDigit = RegExp(r'\D');

/// [text] sin una cola de 1 o 2 decimales (`"15.000,50"` → `"15.000"`).
String dropCopDecimals(String text) => text.replaceFirst(_copDecimalTail, '');

/// Solo las cifras de [text], sin ceros a la izquierda (`"0"` se conserva).
/// Con [dropDecimals], antes quita la cola de decimales ([dropCopDecimals]).
/// La usan [parseCop] y `CopInputFormatter`.
String copDigitsOf(String text, {bool dropDecimals = false}) {
  final source = dropDecimals ? dropCopDecimals(text) : text;
  final digits = source.replaceAll(_nonDigit, '');
  final trimmed = digits.replaceFirst(RegExp(r'^0+'), '');
  return trimmed.isEmpty && digits.isNotEmpty ? '0' : trimmed;
}

/// Importe en cualquier moneda: COP con [formatCop]; el resto con su código
/// y dos decimales (`USD 12.50`).
String formatMoney(Object? value, {String currency = 'COP'}) {
  final code = currency.trim().toUpperCase();
  if (code.isEmpty || code == 'COP') return formatCop(value);
  return '$code ${_toNum(value).toStringAsFixed(2)}';
}

final NumberFormat _percentFormat = NumberFormat('#,##0.#', 'es_CO');

/// Porcentaje ya expresado de 0 a 100: `15` → `15 %`, `12.46` → `12,5 %`.
/// Sin tope: muestra lo que llegue (p. ej. más de 100).
String formatPercent(Object? percent) =>
    '${_percentFormat.format(_toNum(percent))} %';

/// `03/11/2026`
String formatDate(DateTime date) => DateFormat('dd/MM/yyyy', 'es').format(date);

/// `03/11/26`
String formatShortDate(DateTime date) =>
    DateFormat('dd/MM/yy', 'es').format(date);

/// `martes 3 noviembre`
String formatWeekdayDayMonth(DateTime date) =>
    DateFormat('EEEE d MMMM', 'es').format(date);

/// `martes, 03 noviembre 2026`
String formatLongDate(DateTime date) =>
    DateFormat('EEEE, dd MMMM yyyy', 'es').format(date);

// --- Horas (D-23): 12 h con "a. m."/"p. m." en toda la app ------------------
//
// **Único** formateador de horas para la UI: `formatClock` y sus variantes.
// Los espacios son de no separación (U+00A0): "9:30 a. m." nunca se parte en
// dos líneas. En tests, construir lo esperado con estas funciones o con
// [timeAmLabel]/[timePmLabel]. Las horas del contrato (`HH:mm`) siguen en
// 24 h: esto es solo presentación.

/// Sufijo de la mañana (00:00–11:59): `a. m.`
const String timeAmLabel = 'a.\u00a0m.';

/// Sufijo de la tarde (12:00–23:59): `p. m.`
const String timePmLabel = 'p.\u00a0m.';

/// `(9, 30)` → `9:30 a. m.`; `(12, 0)` → `12:00 p. m.`; `(0, 5)` →
/// `12:05 a. m.`; `(23, 59)` → `11:59 p. m.` Hora fuera de 0–23 o minuto
/// fuera de 0–59 → [ArgumentError] (error de programación).
String formatClock(int hour, int minute) {
  RangeError.checkValueInInterval(hour, 0, 23, 'hour');
  RangeError.checkValueInInterval(minute, 0, 59, 'minute');
  return '${_clockDigits(hour, minute)}\u00a0${_periodOf(hour)}';
}

String _clockDigits(int hour, int minute) =>
    '${hour % 12 == 0 ? 12 : hour % 12}:${minute.toString().padLeft(2, '0')}';

String _periodOf(int hour) => hour < 12 ? timeAmLabel : timePmLabel;

/// Hora de [time] en 12 h (`3:30 p. m.`). Un `DateTime` no UTC ya es hora de
/// pared del negocio (convención de D-15) y se muestra tal cual; uno UTC es un
/// instante y se pasa antes a la zona del negocio (`BusinessTimeZone`).
String formatTime(DateTime time) {
  final wall = _wallClock(time);
  return formatClock(wall.hour, wall.minute);
}

/// `TimeOfDay` (selector de hora) → `9:30 a. m.`
String formatTimeOfDay(TimeOfDay time) => formatClock(time.hour, time.minute);

/// Hora `HH:mm` (o `HH:mm:ss`) del contrato y de las entidades (`WorkHours`,
/// horario del negocio, ventana de recordatorios) → `9:00 a. m.`. Un texto
/// que no es una hora se devuelve recortado, sin inventar nada.
String formatHhmm(String hhmm) {
  final match = _hhmm.firstMatch(hhmm.trim());
  if (match == null) return hhmm.trim();
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return hhmm.trim();
  return formatClock(hour, minute);
}

final RegExp _hhmm = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$');

/// Rango de horas. Si las dos están en el mismo periodo, el sufijo va una
/// vez: `10:00 – 11:05 a. m.`; si no, `11:30 a. m. – 1:00 p. m.`
String formatTimeRange(DateTime start, DateTime end) {
  final from = _wallClock(start);
  final to = _wallClock(end);
  if (_periodOf(from.hour) == _periodOf(to.hour)) {
    return '${_clockDigits(from.hour, from.minute)} – '
        '${formatClock(to.hour, to.minute)}';
  }
  return '${formatClock(from.hour, from.minute)} – '
      '${formatClock(to.hour, to.minute)}';
}

DateTime _wallClock(DateTime time) =>
    time.isUtc ? BusinessTimeZone.toWallClock(time) : time;

/// Duración en minutos: `45 min`, `1 h`, `1 h 15 min`. Negativo → `0 min`.
String formatDurationMinutes(int minutes) {
  if (minutes < 60) return '${minutes < 0 ? 0 : minutes} min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}

/// Cantidad con su palabra en singular o plural: `1 cita`, `3 citas`, `0 pagos`.
String formatCount(int count, String singular, String plural) =>
    count == 1 ? '1 $singular' : '$count $plural';

/// Diferencia con UTC: `UTC-05:00`, `UTC+05:30`, `UTC` (sin diferencia).
String formatUtcOffset(Duration offset) {
  if (offset == Duration.zero) return 'UTC';
  final sign = offset.isNegative ? '-' : '+';
  final minutes = offset.inMinutes.abs();
  final hours = (minutes ~/ 60).toString().padLeft(2, '0');
  final rest = (minutes % 60).toString().padLeft(2, '0');
  return 'UTC$sign$hours:$rest';
}

/// Ciudad de una zona IANA: `America/Bogota` → `Bogota`,
/// `America/New_York` → `New York`.
String formatZoneCity(String zone) => zone.split('/').last.replaceAll('_', ' ');

num _toNum(Object? value) {
  if (value is num) return value.isFinite ? value : 0;
  if (value is String) return num.tryParse(value.trim()) ?? 0;
  return 0;
}
