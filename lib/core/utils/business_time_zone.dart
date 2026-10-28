import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Zona horaria del negocio (D-15) y conversiones entre instantes y horas de
/// pared. **Único** sitio de la app que sabe de zonas IANA (usa el paquete
/// `timezone`, con la base de datos `latest_all`).
///
/// Convención de toda la app: un `DateTime` **no UTC** es una hora de pared
/// del negocio (lo que se ve en su reloj, en su zona), nunca la del
/// dispositivo. Por eso la UI puede seguir usando `DateTime(y, m, d, h, min)`,
/// `DateFormat` y los calendarios sin saber de zonas: `DateCodec` convierte en
/// la frontera con el backend y [now] da el "ahora" del negocio.
///
/// - [current]: zona del negocio de la sesión. La fija `SessionService` (de
///   `GET /auth/me`, al iniciar sesión y en el auto-login, y al cambiarla en
///   la configuración). Sin sesión, [fallback] (= `BUSINESS_TIMEZONE` por
///   defecto del backend).
/// - [toWallClock]: instante → hora de pared en una zona.
/// - [toInstant]: hora de pared en una zona → instante UTC.
///
/// Límite conocido: una hora de pared que no existe en la zona del
/// **dispositivo** (el salto de un cambio de horario de verano) la normaliza
/// `DateTime`. Las zonas de Colombia y Venezuela no tienen horario de verano.
abstract final class BusinessTimeZone {
  /// Zona por defecto antes de conocer la del negocio (la misma que usa el
  /// backend para un negocio sin zona).
  static const fallback = 'America/Bogota';

  static bool _initialized = false;
  static Map<String, String>? _canonicalByLowerName;
  static String _current = fallback;

  /// Reloj de la app (instante). Solo se cambia en tests.
  static DateTime Function() clock = DateTime.now;

  /// Carga la base de datos de zonas (una vez). La llaman las conversiones;
  /// también quien use el paquete `timezone` directamente
  /// (`NotificationService`), para no cargar dos bases distintas.
  static void ensureInitialized() {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _initialized = true;
  }

  /// Zona IANA del negocio de la sesión.
  static String get current => _current;

  /// Fija la zona del negocio. Devuelve `false` (y no cambia nada) si [name]
  /// no es una zona IANA conocida.
  static bool use(String? name) {
    final canonical = canonicalName(name);
    if (canonical == null) return false;
    _current = canonical;
    return true;
  }

  /// Vuelve a [fallback] (al cerrar sesión).
  static void reset() => _current = fallback;

  /// Nombre canónico de [name] (sin distinguir mayúsculas ni espacios, como
  /// el backend: `america/bogota` → `America/Bogota`), o `null` si no es una
  /// zona IANA conocida.
  static String? canonicalName(String? name) {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return _byLowerName()[trimmed.toLowerCase()];
  }

  static bool isValid(String? name) => canonicalName(name) != null;

  /// Zonas geográficas (`America/Bogota`, `Europe/Madrid`…) más `UTC`,
  /// ordenadas: la lista para elegir la zona del negocio.
  static List<String> get names {
    final names = _byLowerName()
        .values
        .where((name) => name == 'UTC' || _regionPrefix.hasMatch(name))
        .toSet()
        .toList()
      ..sort();
    return List.unmodifiable(names);
  }

  static final _regionPrefix = RegExp(
      r'^(Africa|America|Antarctica|Asia|Atlantic|Australia|Europe|Indian|Pacific)/');

  /// Diferencia con UTC de [zone] (por defecto, la del negocio) en el
  /// instante [at] (por defecto, ahora). Bogotá: `-5 h`; Caracas: `-4 h`.
  static Duration utcOffset([String? zone, DateTime? at]) {
    final instant = at ?? clock();
    return Duration(
        milliseconds: _location(zone)
            .timeZone(instant.toUtc().millisecondsSinceEpoch)
            .offset);
  }

  /// "Ahora" en el reloj del negocio (hora de pared, no UTC). Es el que decide
  /// "hoy", "solo a futuro" y "próximos días".
  static DateTime now([String? zone]) => toWallClock(clock(), zone);

  /// Hoy a las 00:00 en el calendario del negocio.
  static DateTime today([String? zone]) {
    final wall = now(zone);
    return DateTime(wall.year, wall.month, wall.day);
  }

  /// Hora de pared en [zone] (por defecto, la del negocio; una zona
  /// desconocida cuenta como la del negocio) del instante [instant].
  /// Un `DateTime` no UTC se toma como instante del dispositivo.
  static DateTime toWallClock(DateTime instant, [String? zone]) {
    final zoned = tz.TZDateTime.from(instant, _location(zone));
    return DateTime(zoned.year, zoned.month, zoned.day, zoned.hour,
        zoned.minute, zoned.second, zoned.millisecond, zoned.microsecond);
  }

  /// Instante (UTC) de la hora de pared [wall] en [zone] (por defecto, la del
  /// negocio). Un [wall] ya en UTC es un instante y se devuelve tal cual.
  static DateTime toInstant(DateTime wall, [String? zone]) {
    if (wall.isUtc) return wall;
    return tz.TZDateTime(_location(zone), wall.year, wall.month, wall.day,
            wall.hour, wall.minute, wall.second, wall.millisecond,
            wall.microsecond)
        .toUtc();
  }

  static tz.Location _location(String? zone) {
    ensureInitialized();
    final name = canonicalName(zone) ?? canonicalName(_current) ?? fallback;
    return tz.getLocation(name);
  }

  static Map<String, String> _byLowerName() {
    ensureInitialized();
    return _canonicalByLowerName ??= {
      for (final name in tz.timeZoneDatabase.locations.keys)
        name.toLowerCase(): name,
    };
  }
}
