import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/usecases/agenda_hours.dart';
import 'package:login_signup/features/appointments/domain/usecases/free_slots.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/agenda_slot_finder.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/usecases/get_business_settings_usecase.dart';
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
///
/// Horario (D-25): con el horario de apertura del negocio (feature
/// `settings`) y los horarios del equipo (feature `employees`), ambos por
/// sus use cases, decide el rango de horas de cada día y lo que no se puede
/// reservar (`AgendaHours`). Sin esos use cases, la agenda no limita nada.
class AppointmentsController extends GetxController {
  final GetAppointmentsUseCase _getAppointments;
  final CheckSubscriptionLimitsUseCase _checkLimits;
  final GetBusinessSettingsUseCase? _getSettings;
  final GetEmployeesUseCase? _getTeam;

  /// Quién está libre a una hora tocada; `null` = el formulario decide.
  final AgendaSlotFinder? slotFinder;
  final DateTime Function() _now;

  AppointmentsController({
    required GetAppointmentsUseCase getAppointmentsUseCase,
    required CheckSubscriptionLimitsUseCase checkSubscriptionLimitsUseCase,
    GetBusinessSettingsUseCase? getBusinessSettingsUseCase,
    GetEmployeesUseCase? getEmployeesUseCase,
    this.slotFinder,
    DateTime Function()? now,
  })  : _getAppointments = getAppointmentsUseCase,
        _checkLimits = checkSubscriptionLimitsUseCase,
        _getSettings = getBusinessSettingsUseCase,
        _getTeam = getEmployeesUseCase,
        _now = now ?? BusinessTimeZone.now;

  /// "Ahora" del negocio (el reloj inyectable).
  DateTime now() => _now();

  final appointments = <AppointmentEntity>[].obs;
  final currentView = CalendarView.day.obs;
  late final Rx<DateTime> selectedDate = _now().obs;
  final isLoading = false.obs;

  /// Buscando quién está libre a la hora tocada (barra de carga).
  final isFinding = false.obs;
  final error = Rxn<Failure>();

  /// Las canceladas no ocupan columnas en el calendario (7.04-7): se ocultan
  /// salvo que el usuario pida verlas.
  final showCancelled = false.obs;

  /// Citas que pinta el calendario: sin las canceladas, salvo
  /// [showCancelled], y solo las del profesional del filtro, si hay uno.
  List<AppointmentEntity> get visibleAppointments {
    final only = professionalFilter.value;
    return [
      for (final a in appointments)
        if ((showCancelled.value || !a.isCancelled) &&
            (only == null || a.professionalId == only))
          a,
    ];
  }

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
    // Lo que baja de la sincronización (10.03) se ve sin salir de la agenda;
    // también un horario editado en "Mi negocio" o en el personal.
    if (Get.isRegistered<SyncController>()) {
      _syncWorker = Get.find<SyncController>().onDataChanged(() {
        _load(_range, force: true, silent: true);
        loadHours();
      });
    }
    _load(rangeFor(currentView.value, selectedDate.value));
    loadHours();
  }

  // --- Horario de la agenda (D-25) ------------------------------------------

  /// Horario que limita la agenda (apertura, equipo y filtro).
  final hours = AgendaHours.unlimited.obs;

  /// Profesionales a los que se puede agendar (activos), con su horario.
  final team = <EmployeeEntity>[].obs;

  /// Profesional elegido en las opciones de la agenda (solo el Owner);
  /// `null` = todo el equipo.
  final professionalFilter = RxnString();

  AgendaHours _base = AgendaHours.unlimited;
  int _hoursRequest = 0;

  String? get _sessionUserId => Get.isRegistered<SessionController>()
      ? Get.find<SessionController>().userId
      : null;

  /// Lee el horario de apertura y el del equipo (local, también sin
  /// conexión). Sin use cases o si fallan, la agenda no limita nada.
  Future<void> loadHours() async {
    final getSettings = _getSettings;
    final getTeam = _getTeam;
    if (getSettings == null && getTeam == null) return;
    final request = ++_hoursRequest;
    final settingsCall = getSettings?.call(NoParams());
    final teamCall = getTeam?.call(NoParams());
    final settings = (await settingsCall)?.fold((_) => null, (s) => s);
    final loaded = (await teamCall)?.fold((_) => null, (list) => list);
    if (request != _hoursRequest) return;
    final active = [
      for (final e in loaded ?? const <EmployeeEntity>[])
        if (e.canBeScheduled) e,
    ];
    team.assignAll(active);
    if (professionalFilter.value != null &&
        !active.any((e) => e.id == professionalFilter.value)) {
      professionalFilter.value = null;
    }
    _base = AgendaHours(
      business: _openingWindows(settings?.openingHours),
      team: [for (final e in active) AgendaHours.weekly(e.schedule)],
    );
    _applyFilter();
  }

  static List<ScheduleWindow>? _openingWindows(OpeningHours? opening) =>
      opening == null
          ? null
          : [
              for (final r in opening.ranges)
                if (AgendaHours.window(r.dayOfWeek, r.hours) case final w?) w,
            ];

  /// Profesional cuyo horario se sombrea: la empleada (su agenda) o el del
  /// filtro.
  String? get shadedProfessionalId =>
      isEmployeeView ? _sessionUserId : professionalFilter.value;

  /// Nombre del profesional del filtro (`null` para la empleada: "tú").
  String? get filteredProfessionalName {
    final id = professionalFilter.value;
    if (id == null || isEmployeeView) return null;
    return team.firstWhereOrNull((e) => e.id == id)?.fullName;
  }

  void _applyFilter() {
    final id = shadedProfessionalId;
    final member = id == null ? null : team.firstWhereOrNull((e) => e.id == id);
    hours.value = _base.withProfessional(
        member == null ? null : AgendaHours.weekly(member.schedule));
  }

  /// Ver solo las citas (y el horario) de un profesional; `null` = todos.
  void filterByProfessional(String? professionalId) {
    if (isEmployeeView) return;
    professionalFilter.value = professionalId;
    _applyFilter();
  }

  /// Inicio y fin de las citas visibles (para no esconder ninguna).
  Iterable<(DateTime, DateTime)> get _visibleSpans =>
      visibleAppointments.map((a) => (a.startTime, a.endTime));

  /// El día [date]: rango de horas y lo que no se puede reservar.
  AgendaDay dayHours(DateTime date) =>
      hours.value.day(date, appointments: _visibleSpans);

  /// La semana que se ve (lunes a domingo de [selectedDate]).
  AgendaWeek weekHours() {
    final range = rangeFor(CalendarView.week, selectedDate.value);
    return hours.value.week(
      [
        for (var i = 0; i < 7; i++)
          DateTime(range.start.year, range.start.month, range.start.day + i),
      ],
      appointments: _visibleSpans,
    );
  }

  /// A quién se le puede agendar desde la agenda: la empleada, solo a sí
  /// misma; con filtro, a ese profesional; si no, al equipo activo (el
  /// Owner, el último).
  List<AgendaCandidate> get bookingCandidates {
    if (isEmployeeView) {
      final session = Get.find<SessionController>();
      return [
        AgendaCandidate(id: session.userId, name: session.name ?? 'Yo'),
      ];
    }
    final only = professionalFilter.value;
    // Primero las empleadas; el Owner, al final (si también atiende).
    final ordered = [
      ...team.where((e) => !e.isOwner),
      ...team.where((e) => e.isOwner),
    ];
    return [
      for (final e in ordered)
        if (only == null || e.id == only)
          AgendaCandidate(id: e.id, name: e.fullName),
    ];
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

  /// Flechas de la barra de la agenda: un día, una semana o un mes hacia
  /// delante ([direction] = 1) o hacia atrás (-1).
  Future<void> step(int direction) {
    final d = selectedDate.value;
    final target = switch (currentView.value) {
      CalendarView.month => DateTime(d.year, d.month + direction, 1),
      CalendarView.week ||
      CalendarView.workWeek =>
        DateTime(d.year, d.month, d.day + 7 * direction),
      _ => DateTime(d.year, d.month, d.day + direction),
    };
    return changeView(currentView.value, targetDate: target);
  }

  /// "Hoy": la vista actual en el día de hoy del negocio.
  Future<void> goToToday() =>
      changeView(currentView.value, targetDate: _now());

  /// ¿El rango visible incluye hoy? (si no, la barra ofrece "Hoy").
  bool get showsToday {
    final today = _now();
    final visible = selectedDate.value;
    if (currentView.value == CalendarView.month) {
      return visible.year == today.year && visible.month == today.month;
    }
    return rangeFor(currentView.value, visible)
        .contains(DateTime(today.year, today.month, today.day, 12));
  }

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
  Future<void> reload() {
    loadHours();
    return _load(_range, force: true);
  }

  /// [silent] (recarga tras una sincronización, 7.05d): sin la barra de
  /// carga y, si falla con citas ya pintadas, se conservan sin error.
  Future<void> _load(AppointmentsRange? range,
      {bool force = false, bool silent = false}) async {
    if (range == null || (!force && range == _range && error.value == null)) {
      return;
    }
    _range = range;
    final request = ++_request;
    if (!silent) {
      isLoading.value = true;
      error.value = null;
    }
    final result = await _getAppointments(range);
    if (request != _request) return; // llegó otra petición después
    // También si es silenciosa: pudo dejar sin efecto una carga visible.
    isLoading.value = false;
    result.fold(
      (failure) {
        if (!silent || appointments.isEmpty) error.value = failure;
      },
      (loaded) {
        error.value = null;
        appointments.assignAll(loaded);
      },
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
