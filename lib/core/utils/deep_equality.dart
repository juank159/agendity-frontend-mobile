/// Igualdad por contenido de listas y mapas para el `==`/`hashCode` de las
/// entidades (el dominio no puede usar `listEquals`/`mapEquals` de Flutter).
abstract final class DeepEquality {
  /// Mismos elementos en el mismo orden.
  static bool lists<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Mismas claves con los mismos valores (sin importar el orden).
  static bool maps<K, V>(Map<K, V> a, Map<K, V> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  /// `hashCode` coherente con [maps] (no depende del orden).
  static int mapHash<K, V>(Map<K, V> map) => Object.hashAllUnordered(
      map.entries.map((entry) => Object.hash(entry.key, entry.value)));
}
