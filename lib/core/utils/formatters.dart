import 'package:intl/intl.dart';

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
  final formatted = '\$ ${_copGrouping.format(amount.abs())}';
  return amount < 0 ? '-$formatted' : formatted;
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

/// `3:30 p. m.` (12 horas, como fuerza `main.dart`).
String formatTime(DateTime time) => DateFormat('h:mm a', 'es').format(time);

/// `3:30 p. m. - 4:15 p. m.`
String formatTimeRange(DateTime start, DateTime end) =>
    '${formatTime(start)} - ${formatTime(end)}';

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

num _toNum(Object? value) {
  if (value is num) return value.isFinite ? value : 0;
  if (value is String) return num.tryParse(value.trim()) ?? 0;
  return 0;
}
