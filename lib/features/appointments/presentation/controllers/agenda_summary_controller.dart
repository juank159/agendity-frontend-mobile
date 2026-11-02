import 'package:get/get.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_appointment_balance_usecase.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';

/// Números de hoy de la cabecera de la agenda (12.04).
class AgendaSummary {
  /// Citas de hoy que no están canceladas.
  final int appointments;

  /// Lo que falta por cobrar de esas citas.
  final double toCollect;

  /// "Ingresos hoy" (solo el Owner): el dinero **recibido hoy**, es decir,
  /// los pagos con fecha de hoy en la zona del negocio, netos de reembolsos
  /// (los mismos "ingresos de hoy" de Informes). No depende de la fecha de
  /// la cita: el abono de hoy a una cita de mañana cuenta; el pago de ayer a
  /// una cita de hoy, no.
  final double income;

  const AgendaSummary({
    required this.appointments,
    required this.toCollect,
    required this.income,
  });

  static const empty = AgendaSummary(appointments: 0, toCollect: 0, income: 0);

  AgendaSummary copyWith({int? appointments, double? toCollect, double? income}) =>
      AgendaSummary(
        appointments: appointments ?? this.appointments,
        toCollect: toCollect ?? this.toCollect,
        income: income ?? this.income,
      );

  @override
  bool operator ==(Object other) =>
      other is AgendaSummary &&
      other.appointments == appointments &&
      other.toCollect == toCollect &&
      other.income == income;

  @override
  int get hashCode => Object.hash(appointments, toCollect, income);

  @override
  String toString() =>
      'AgendaSummary($appointments citas, por cobrar $toCollect, ingresos $income)';
}

/// Cabecera de resumen de la agenda: saludo, fecha del negocio y los números
/// de **hoy** (D-15: el "hoy" del negocio), leídos de los datos locales con
/// los use cases que ya existen:
/// - las citas del día con `GetAppointmentsUseCase`;
/// - lo pagado de una cita con anticipo (`PARTIAL`) con
///   `GetAppointmentBalanceUseCase`; las demás se resuelven con
///   `knownBalanceDue` (sin pagar = el total, pagada = 0);
/// - "Ingresos hoy" (solo el Owner) con `GetPaymentStatsUseCase` sobre el día
///   de hoy: el mismo número que Informes (pagos de hoy, netos de
///   reembolsos; sin conexión lo calcula con los datos locales).
///
/// Se recalcula cuando cambia la lista de la agenda ([agendaChanges]: crear,
/// editar, pagar, sincronizar o cambiar la zona del negocio recargan la
/// agenda).
class AgendaSummaryController extends GetxController {
  final GetAppointmentsUseCase _getAppointments;
  final GetAppointmentBalanceUseCase _getBalance;
  final GetPaymentStatsUseCase? _getPaymentStats;
  final RxList<AppointmentEntity>? _agendaChanges;
  final DateTime Function() _now;

  AgendaSummaryController({
    required GetAppointmentsUseCase getAppointmentsUseCase,
    required GetAppointmentBalanceUseCase getAppointmentBalanceUseCase,
    GetPaymentStatsUseCase? getPaymentStatsUseCase,
    RxList<AppointmentEntity>? agendaChanges,
    DateTime Function()? now,
  })  : _getAppointments = getAppointmentsUseCase,
        _getBalance = getAppointmentBalanceUseCase,
        _getPaymentStats = getPaymentStatsUseCase,
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

  /// Vuelve a calcular los números de hoy. Si una parte falla, conserva su
  /// último valor.
  Future<void> load() async {
    final request = ++_request;
    final results = await Future.wait([_loadAppointments(), _loadIncome()]);
    if (request != _request) return;
    final counts = results[0] as AgendaSummary?;
    final income = results[1] as double?;
    if (counts == null && income == null) return;
    summary.value = summary.value.copyWith(
      appointments: counts?.appointments,
      toCollect: counts?.toCollect,
      income: income,
    );
    isLoaded.value = true;
  }

  /// Citas de hoy y lo que falta por cobrar de ellas (`null` si falla).
  Future<AgendaSummary?> _loadAppointments() async {
    final day = AppointmentsRange.day(today);
    final result = await _getAppointments(day);
    final list = result.fold((_) => null, (list) => list);
    if (list == null) return null;
    final todays = [
      for (final a in list)
        if (!a.isCancelled && day.contains(a.startInstant)) a,
    ];
    var due = 0.0;
    for (final a in todays) {
      due += await _outstanding(a);
    }
    return AgendaSummary(appointments: todays.length, toCollect: due, income: 0);
  }

  /// Dinero recibido hoy (`null` si no aplica o falla): solo el Owner.
  Future<double?> _loadIncome() async {
    final getStats = _getPaymentStats;
    if (getStats == null || !showsIncome) return null;
    final result = await getStats(StatsRange.day(today));
    return result.fold((_) => null, (stats) => stats.totalAmount);
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
