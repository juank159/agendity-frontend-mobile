/// Lectura tolerante de valores de un JSON del backend, para los `fromJson`
/// de los DTO (ARQUITECTURA §2.2).
///
/// El backend manda los `decimal` de Postgres como texto (`"45000.00"`), los
/// `COUNT`/`SUM` ya convertidos con `Number()` y, a veces, `null` donde la app
/// espera un valor. Estas funciones nunca lanzan: devuelven el valor por
/// defecto, y el modelo decide si eso es aceptable.
abstract final class JsonRead {
  /// `num` o texto numérico (con espacios) → `double`; otro valor → [fallback].
  static double asDouble(Object? value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  /// Como [asDouble], redondeado (`"3"`, `3.0` y `2.6` → 3).
  static int asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed.round();
    }
    return fallback;
  }

  /// Texto recortado; `null` si falta o queda vacío.
  static String? asOptionalString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  /// Texto recortado; [fallback] si falta o queda vacío.
  static String asString(Object? value, {String fallback = ''}) =>
      asOptionalString(value) ?? fallback;

  /// `bool`, o texto: todo lo que no sea `"false"` es `true`; `null` → [fallback].
  static bool asBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value == null) return fallback;
    return value.toString().toLowerCase() != 'false';
  }

  /// El objeto si es un mapa JSON; si no, `null`.
  static Map<String, dynamic>? asMap(Object? value) =>
      value is Map<String, dynamic> ? value : null;

  /// Los elementos que son mapas JSON (ignora el resto); `null` → lista vacía.
  static List<Map<String, dynamic>> asMapList(Object? value) => value is List
      ? value.whereType<Map<String, dynamic>>().toList()
      : const [];
}
