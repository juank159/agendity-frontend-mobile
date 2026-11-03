import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_available_slots_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_offered_by_usecase.dart';

/// Profesional al que se le puede agendar desde la agenda (id y nombre).
class AgendaCandidate {
  final String id;
  final String name;

  const AgendaCandidate({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      other is AgendaCandidate && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// Una hora libre y quién está libre a esa hora.
typedef AgendaSuggestion = ({DateTime at, AgendaCandidate professional});

/// Quién está libre a una hora tocada en la agenda (D-25).
class FreeAtResult {
  final DateTime at;

  /// Libres a [at], en el orden del equipo.
  final List<AgendaCandidate> free;

  /// Horas libres más cercanas a [at] ese día (de cualquier profesional), en
  /// orden.
  final List<AgendaSuggestion> suggestions;

  /// `false` si no se pudo consultar a nadie (sin datos o error): entonces
  /// la agenda abre el formulario y deja decidir al servidor.
  final bool checked;

  const FreeAtResult({
    required this.at,
    this.free = const [],
    this.suggestions = const [],
    this.checked = true,
  });

  const FreeAtResult.unknown(this.at)
      : free = const [],
        suggestions = const [],
        checked = false;
}

/// Busca profesionales libres con los use cases que ya existen (sin
/// conexión también: `GetAvailableSlotsUseCase` calcula en local y
/// `GetServicesOfferedByUseCase` lee de la base local).
///
/// "Libre a las 3:00 p. m." = a esa hora puede empezar **su servicio más
/// corto** (aún no se sabe qué servicio quiere el cliente). El formulario
/// vuelve a pedir las horas con los servicios elegidos.
class AgendaSlotFinder {
  final GetAvailableSlotsUseCase _getSlots;
  final GetServicesOfferedByUseCase _getOffered;

  AgendaSlotFinder({
    required GetAvailableSlotsUseCase getAvailableSlotsUseCase,
    required GetServicesOfferedByUseCase getServicesOfferedByUseCase,
  })  : _getSlots = getAvailableSlotsUseCase,
        _getOffered = getServicesOfferedByUseCase;

  static const maxSuggestions = 4;

  Future<FreeAtResult> freeAt(
      DateTime at, List<AgendaCandidate> candidates) async {
    if (candidates.isEmpty) return FreeAtResult.unknown(at);
    final day = DateTime(at.year, at.month, at.day);
    final all = await Future.wait([
      for (final c in candidates) _slotsOf(c.id, day),
    ]);
    if (all.every((slots) => slots == null)) return FreeAtResult.unknown(at);

    final free = <AgendaCandidate>[];
    final byTime = <DateTime, AgendaCandidate>{};
    for (var i = 0; i < candidates.length; i++) {
      final slots = all[i];
      if (slots == null) continue;
      if (slots.any((s) => s.isAtSameMomentAs(at))) free.add(candidates[i]);
      for (final s in slots) {
        byTime.putIfAbsent(s, () => candidates[i]);
      }
    }
    final nearest = byTime.keys.where((s) => !s.isAtSameMomentAs(at)).toList()
      ..sort((a, b) {
        final da = a.difference(at).abs();
        final db = b.difference(at).abs();
        return da != db ? da.compareTo(db) : a.compareTo(b);
      });
    final picked = nearest.take(maxSuggestions).toList()..sort();
    return FreeAtResult(
      at: at,
      free: free,
      suggestions: [
        for (final s in picked) (at: s, professional: byTime[s]!),
      ],
    );
  }

  /// Horas libres del día para su servicio activo más corto; vacía si no
  /// hace ninguno; `null` si no se pudo consultar.
  Future<List<DateTime>?> _slotsOf(String professionalId, DateTime day) async {
    final offered = await _getOffered(professionalId);
    final services = offered.fold((_) => null, (list) => list);
    if (services == null) return null;
    final active = [
      for (final s in services)
        if (s.isActive && s.id != null) s,
    ];
    if (active.isEmpty) return const [];
    active.sort((a, b) => _minutes(a.duration).compareTo(_minutes(b.duration)));
    final result = await _getSlots(AvailableSlotsQuery(
      professionalId: professionalId,
      day: day,
      serviceIds: [active.first.id!],
    ));
    return result.fold((_) => null, (slots) => slots);
  }

  /// Un servicio sin duración cuenta 30 min (como el backend).
  static int _minutes(int duration) => duration > 0 ? duration : 30;
}
