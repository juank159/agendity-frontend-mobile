/// Fechas en el contrato HTTP (ARQUITECTURA.md §3, backend 2.05).
///
/// - **Enviar** un instante: [encode] → ISO 8601 en UTC (`…Z`). El backend
///   respeta el offset; sin offset leería la hora como de Bogotá, así que no
///   se envía nunca un ISO sin offset.
/// - **Enviar** un día (filtros de estadísticas): [encodeDay] → `yyyy-MM-dd`,
///   que el backend entiende como el día completo del negocio.
/// - **Recibir**: [decode]/[tryDecode] → `DateTime` en la zona del dispositivo.
///   El backend responde con el offset del negocio (`…T08:00:00.000-05:00`);
///   `DateTime.parse` lo deja en UTC y sin `toLocal()` la UI mostraría la hora UTC.
abstract final class DateCodec {
  static String encode(DateTime value) => value.toUtc().toIso8601String();

  static String? encodeOrNull(DateTime? value) =>
      value == null ? null : encode(value);

  /// Día de calendario tal como lo ve el usuario (sin convertir de zona).
  static String encodeDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// Lanza `FormatException` si [value] no es una fecha ISO 8601.
  static DateTime decode(String value) =>
      DateTime.parse(value.trim()).toLocal();

  /// `null` si el valor falta, está vacío o no es una fecha. Acepta también un
  /// `DateTime` ya construido.
  static DateTime? tryDecode(Object? value) {
    if (value is DateTime) return value.toLocal();
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim())?.toLocal();
  }

  static final _dayPrefix = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');

  /// Inverso de [encodeDay]: un día del negocio → `DateTime(y, m, d)` local a
  /// medianoche, **sin convertir de zona**. Acepta `"2026-10-21"` (desglose
  /// diario) y también un instante con el offset del negocio
  /// (`"2026-10-21T23:59:59.999-05:00"`, límites de un período): se queda con
  /// la fecha escrita, que es el día del negocio. Con [decode], en un
  /// dispositivo en otra zona ese fin de día caería en el día siguiente.
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
