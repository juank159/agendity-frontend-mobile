import 'package:get/get.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_appointment_balance_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';

/// Números de hoy de la cabecera de la agenda (12.04).
class AgendaSummary {
  /// Citas de hoy que no están canceladas.
  final int appointments;

  /// Lo que falta por cobrar de esas citas.
  final double toCollect;

  /// Lo ya cobrado (neto) de esas citas: "Ingresos hoy", solo para el Owner.
  final double collected;

  const AgendaSummary({
    required this.appointments,
    required this.toCollect,
    required this.collected,
  });

  static const empty =
      AgendaSummary(appointments: 0, toCollect: 0, collected: 0);

  @override
  bool operator ==(Object other) =>
      other is AgendaSummary &&
      other.appointments == appointments &&
      other.toCollect == toCollect &&
      other.collected == collected;

  @override
  int get hashCode => Object.hash(appointments, toCollect, collected);

  @override
  String toString() =>
      'AgendaSummary($appointments citas, por cobrar $toCollect, cobrado $collected)';
}

/// Cabecera de resumen de la agenda: saludo, fecha del negocio y los números
/// de **hoy** (D-15: el "hoy" del negocio), leídos de los datos locales con
/// los use cases que ya existen:
/// - las citas del día con `GetAppointmentsUseCase`;
/// - lo pagado de una cita con anticipo (`PARTIAL`) con
///   `GetAppointmentBalanceUseCase`; las demás se resuelven con
///   `knownBalanceDue` (sin pagar = el total, pagada = 0).
///
/// Se recalcula cuando cambia la lista de la agenda ([agendaChanges]: crear,
/// editar, pagar, sincronizar o cambiar la zona del negocio recargan la
/// agenda).
class AgendaSummaryController extends GetxController {
  final GetAppointmentsUseCase _getAppointments;
  final GetAppointmentBalanceUseCase _getBalance;
  final RxList<AppointmentEntity>? _agendaChanges;
  final DateTime Function() _now;

  AgendaSummaryController({
    required GetAppointmentsUseCase getAppointmentsUseCase,
    required GetAppointmentBalanceUseCase getAppointmentBalanceUseCase,
    RxList<AppointmentEntity>? agendaChanges,
    DateTime Function()? now,
  })  : _getAppointments = getAppointmentsUseCase,
        _getBalance = getAppointmentBalanceUseCase,
        _agendaChanges = agendaChanges,
        _now = now ?? BusinessTimeZone.now;

  final summary = AgendaSummary.empty.obs;

  /// `false` hasta la primera carga (las cifras se pintan como esqueleto).
  final isLoaded = false.obs;

  /// Cabecera desplegada (tarjetas) o plegada (una línea).
  final expanded = true.obs;

  Worker? _agendaWorker;
  int _request = 0;

  /// Hoy en el negocio.
  DateTime get today {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  SessionController? get _session => Get.isRegistered<SessionController>()
      ? Get.find<SessionController>()
      : null;

  /// "Ingresos hoy" es solo del Owner.
  bool get showsIncome => _session?.isOwner ?? false;

  /// "Hola, Paula" (el primer nombre) o "Hola" si no se conoce.
  String get greeting {
    final name = (_session?.name ?? '').trim();
    if (name.isEmpty) return 'Hola';
    return 'Hola, ${name.split(RegExp(r'\s+')).first}';
  }

  void toggleExpanded() => expanded.toggle();

  @override
  void onInit() {
    super.onInit();
    final changes = _agendaChanges;
    if (changes != null) {
      _agendaWorker = ever<List<AppointmentEntity>>(changes, (_) => load());
    }
    load();
  }

  @override
  void onClose() {
    _agendaWorker?.dispose();
    super.onClose();
  }

  /// Vuelve a calcular los números de hoy. Si falla, conserva los últimos.
  Future<void> load() async {
    final request = ++_request;
    final day = AppointmentsRange.day(today);
    final result = await _getAppointments(day);
    final list = result.fold((_) => null, (list) => list);
    if (list == null || request != _request) return;
    final todays = [
      for (final a in list)
        if (!a.isCancelled && day.contains(a.startInstant)) a,
    ];
    var due = 0.0;
    var paid = 0.0;
    for (final a in todays) {
      final outstanding = await _outstanding(a);
      due += outstanding;
      paid += (a.totalPrice - outstanding).clamp(0.0, a.totalPrice).toDouble();
    }
    if (request != _request) return;
    summary.value = AgendaSummary(
      appointments: todays.length,
      toCollect: due,
      collected: paid,
    );
    isLoaded.value = true;
  }

  /// Saldo de [a]: sin consultar si se sabe; con anticipo, por sus pagos
  /// (si no se pueden leer, cuenta el total).
  Future<double> _outstanding(AppointmentEntity a) async {
    final known = a.knownBalanceDue;
    if (known != null) return known;
    final result = await _getBalance(
        AppointmentBalanceParams(appointmentId: a.id, total: a.totalPrice));
    return result.fold((_) => a.totalPrice, (balance) => balance.outstanding);
  }
}
