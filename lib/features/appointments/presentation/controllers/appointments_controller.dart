import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_limits.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_limits_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Agenda (home): las citas del rango visible del calendario.
///
/// Solo lee y refleja cambios. El Owner ve todas las del negocio y el
/// Employee solo las suyas: lo filtra el backend. Crear y editar es de
/// `AppointmentFormController`; cancelar, completar y pagar, de
/// `AppointmentActionsController`.
class AppointmentsController extends GetxController {
  final GetAppointmentsUseCase _getAppointments;
  final CheckSubscriptionLimitsUseCase _checkLimits;
  final DateTime Function() _now;

  AppointmentsController({
    required GetAppointmentsUseCase getAppointmentsUseCase,
    required CheckSubscriptionLimitsUseCase checkSubscriptionLimitsUseCase,
    DateTime Function()? now,
  })  : _getAppointments = getAppointmentsUseCase,
        _checkLimits = checkSubscriptionLimitsUseCase,
        _now = now ?? BusinessTimeZone.now;

  final appointments = <AppointmentEntity>[].obs;
  final currentView = CalendarView.day.obs;
  late final Rx<DateTime> selectedDate = _now().obs;
  final isLoading = false.obs;
  final error = Rxn<Failure>();

  /// Las canceladas no ocupan columnas en el calendario (7.04-7): se ocultan
  /// salvo que el usuario pida verlas.
  final showCancelled = false.obs;

  /// Citas que pinta el calendario: sin las canceladas, salvo [showCancelled].
  List<AppointmentEntity> get visibleAppointments => showCancelled.value
      ? appointments.toList()
      : appointments.where((a) => !a.isCancelled).toList();

  void toggleShowCancelled() => showCancelled.toggle();

  /// Inicio sugerido para una cita nueva desde el botón "+": el día visible
  /// de la agenda (7.04-6); si es hoy, ahora.
  DateTime get newAppointmentStart {
    final now = _now();
    final visible = selectedDate.value;
    final sameDay = visible.year == now.year &&
        visible.month == now.month &&
        visible.day == now.day;
    return sameDay ? now : DateTime(visible.year, visible.month, visible.day);
  }

  /// Cambia cuando la app (no el usuario deslizando) mueve el calendario a
  /// otra vista o fecha: el calendario se vuelve a montar en esa fecha.
  final navigation = 0.obs;

  AppointmentsRange? _range;
  int _request = 0;
  Worker? _timeZoneWorker;
  Worker? _syncWorker;

  /// Employee que no es Owner: ve "Mis citas".
  bool get isEmployeeView => Get.isRegistered<SessionController>() &&
      Get.find<SessionController>().isOnlyEmployee;

  String get title {
    final base = isEmployeeView ? 'Mis citas' : 'Agenda';
    final view = switch (currentView.value) {
      CalendarView.day => 'Día',
      CalendarView.week || CalendarView.workWeek => 'Semana',
      CalendarView.month => 'Mes',
      _ => '',
    };
    return view.isEmpty ? base : '$base · $view';
  }

  @override
  void onInit() {
    super.onInit();
    // Si el Owner cambia la zona del negocio (configuración), las horas ya
    // cargadas se piden de nuevo en la zona nueva.
    if (Get.isRegistered<SessionController>()) {
      _timeZoneWorker =
          Get.find<SessionController>().onTimeZoneChanged((_) => reload());
    }
    // Lo que baja de la sincronización (10.03) se ve sin salir de la agenda.
    if (Get.isRegistered<SyncController>()) {
      _syncWorker = Get.find<SyncController>().onDataChanged(reload);
    }
    _load(rangeFor(currentView.value, selectedDate.value));
  }

  @override
  void onClose() {
    _syncWorker?.dispose();
    _timeZoneWorker?.dispose();
    super.onClose();
  }

  /// Rango que se pide para [view] alrededor de [date]: el día, la semana
  /// (lunes a domingo) o las 6 semanas que pinta la vista de mes.
  static AppointmentsRange rangeFor(CalendarView view, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    switch (view) {
      case CalendarView.week:
      case CalendarView.workWeek:
        final monday = day.subtract(Duration(days: day.weekday - 1));
        return AppointmentsRange(
            start: monday,
            end: DateTime(monday.year, monday.month, monday.day + 7));
      case CalendarView.month:
        final first = DateTime(day.year, day.month, 1);
        final start = first.subtract(Duration(days: first.weekday - 1));
        return AppointmentsRange(
            start: start, end: DateTime(start.year, start.month, start.day + 42));
      default:
        return AppointmentsRange.day(day);
    }
  }

  /// Cambia de vista (y de fecha, si se indica) y carga su rango.
  Future<void> changeView(CalendarView view, {DateTime? targetDate}) {
    currentView.value = view;
    if (targetDate != null) selectedDate.value = targetDate;
    navigation.value++;
    return _load(rangeFor(view, selectedDate.value));
  }

  /// Vista de día de [date] (tocar un día en la vista de mes o de semana).
  Future<void> showDay(DateTime date) =>
      changeView(CalendarView.day, targetDate: date);

  /// El usuario se movió en el calendario: se carga el nuevo rango visible.
  void onViewChanged(ViewChangedDetails details) {
    final dates = details.visibleDates;
    if (dates.isEmpty) return;
    selectedDate.value = dates[dates.length ~/ 2];
    final first = dates.first;
    final last = dates.last;
    _load(AppointmentsRange(
      start: DateTime(first.year, first.month, first.day),
      end: DateTime(last.year, last.month, last.day + 1),
    ));
  }

  /// Vuelve a pedir el rango actual (reintento o tras un cambio externo).
  Future<void> reload() => _load(_range, force: true);

  Future<void> _load(AppointmentsRange? range, {bool force = false}) async {
    if (range == null || (!force && range == _range && error.value == null)) {
      return;
    }
    _range = range;
    final request = ++_request;
    isLoading.value = true;
    error.value = null;
    final result = await _getAppointments(range);
    if (request != _request) return; // llegó otra petición después
    isLoading.value = false;
    result.fold(
      (failure) => error.value = failure,
      appointments.assignAll,
    );
  }

  /// Refleja en la agenda una cita creada o cambiada sin recargar todo: la
  /// sustituye, la añade si cae en el rango visible o la quita si salió.
  void applyChange(AppointmentEntity changed) {
    final index = appointments.indexWhere((a) => a.id == changed.id);
    final visible = _range?.contains(changed.startInstant) ?? false;
    if (index >= 0 && visible) {
      appointments[index] = changed;
    } else if (index >= 0) {
      appointments.removeAt(index);
    } else if (visible) {
      appointments.add(changed);
    }
    appointments.sort((a, b) => a.startInstant.compareTo(b.startInstant));
  }

  /// Tras crear una cita: se muestra su día.
  void focusOn(AppointmentEntity created) {
    if (currentView.value == CalendarView.day &&
        (_range?.contains(created.startInstant) ?? false)) {
      applyChange(created);
      return;
    }
    showDay(created.startTime);
  }

  /// ¿Se puede abrir el formulario de una cita nueva? Si el plan ya no
  /// admite citas, muestra el diálogo de suscripción y devuelve `false`. Si
  /// no se puede comprobar, deja seguir: el backend lo decide al crear.
  Future<bool> canStartAppointment() async {
    final result = await _checkLimits(NoParams());
    final limits = result.fold((_) => null, (limits) => limits);
    if (limits == null || limits.canCreateAppointment) return true;
    await AppDialogs.subscriptionRequired(
      reason: limits.block == SubscriptionBlock.trialLimitReached
          ? SubscriptionBlockReason.trialEnded
          : SubscriptionBlockReason.inactive,
    );
    return false;
  }

  /// Citas que empiezan el día de [date] (contador de la vista de mes; las
  /// canceladas cuentan solo si se muestran).
  int countOn(DateTime date) => visibleAppointments
      .where((a) =>
          a.startTime.year == date.year &&
          a.startTime.month == date.month &&
          a.startTime.day == date.day)
      .length;

  AppointmentEntity? byId(String id) =>
      appointments.firstWhereOrNull((a) => a.id == id);
}
