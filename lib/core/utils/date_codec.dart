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
}
