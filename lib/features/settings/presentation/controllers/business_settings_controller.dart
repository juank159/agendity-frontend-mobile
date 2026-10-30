import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/config/env_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/usecases/get_business_settings_usecase.dart';
import 'package:login_signup/features/settings/domain/usecases/update_business_name_usecase.dart';
import 'package:login_signup/features/settings/domain/usecases/update_business_time_zone_usecase.dart';
import 'package:login_signup/features/settings/domain/usecases/update_opening_hours_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/utils/external_link.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Estado de la carga inicial de la configuración.
enum BusinessSettingsStatus { loading, ready, error }

/// Link público de reservas (9.02): la página la sirve el backend en
/// `/reservar/<slug>`, fuera de `/api`. [apiUrl] es la base del API
/// (`…/api`, `EnvConfig.apiUrl`).
String publicBookingLink(String apiUrl, String slug) {
  var base = apiUrl.trim();
  while (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }
  if (base.endsWith('/api')) base = base.substring(0, base.length - 4);
  return '$base/reservar/${Uri.encodeComponent(slug)}';
}

/// "Mi negocio" (solo Owner: la ruta lleva `RoleMiddleware.ownerOnly()`):
/// nombre, link público de reservas, horario de apertura y zona horaria.
///
/// Al guardar una zona nueva, la capa de datos ya la fija en la sesión;
/// aquí se recarga el `SessionController`, y las pantallas con horas ya
/// cargadas (la agenda) las vuelven a pedir porque escuchan
/// `SessionController.onTimeZoneChanged`.
class BusinessSettingsController extends GetxController {
  /// Franja que se propone al abrir un día o activar el horario.
  static const defaultRange = WorkHours(start: '09:00', end: '18:00');

  final GetBusinessSettingsUseCase _getSettings;
  final UpdateBusinessTimeZoneUseCase _updateTimeZone;
  final UpdateBusinessNameUseCase _updateName;
  final UpdateOpeningHoursUseCase _updateOpeningHours;
  final SessionController _session;
  final List<String> _zones;
  final String Function() _apiUrl;
  final ExternalLinkOpener _openLink;

  BusinessSettingsController({
    required GetBusinessSettingsUseCase getBusinessSettingsUseCase,
    required UpdateBusinessTimeZoneUseCase updateBusinessTimeZoneUseCase,
    required UpdateBusinessNameUseCase updateBusinessNameUseCase,
    required UpdateOpeningHoursUseCase updateOpeningHoursUseCase,
    required SessionController session,
    List<String>? zones,
    String Function()? apiUrl,
    ExternalLinkOpener? openLink,
  })  : _getSettings = getBusinessSettingsUseCase,
        _updateTimeZone = updateBusinessTimeZoneUseCase,
        _updateName = updateBusinessNameUseCase,
        _updateOpeningHours = updateOpeningHoursUseCase,
        _session = session,
        _zones = zones ?? BusinessTimeZone.names,
        _apiUrl = apiUrl ?? (() => EnvConfig.apiUrl),
        _openLink = openLink ?? openExternalLink;

  final status = BusinessSettingsStatus.loading.obs;
  final loadError = RxnString();

  /// `true` si el error de carga no se arregla reintentando (sin permiso).
  final loadErrorIsFinal = false.obs;

  /// Configuración guardada en el backend.
  final saved = Rxn<BusinessSettings>();

  // --- Nombre ---------------------------------------------------------------
  final nameController = TextEditingController();
  final nameText = ''.obs;
  final isSavingName = false.obs;

  // --- Horario de apertura ----------------------------------------------------
  /// Limita las citas a un horario (`false` = sin horario, `null` al guardar).
  final limitsHours = false.obs;

  /// Borrador del horario (se guarda con [saveOpeningHours]).
  final draftHours = Rx<OpeningHours>(OpeningHours.closed);
  final isSavingHours = false.obs;

  // --- Zona horaria -----------------------------------------------------------
  final query = ''.obs;
  final isSavingZone = false.obs;
  final searchController = TextEditingController();

  String? get savedZone => saved.value?.timeZone;
  String? get slug => saved.value?.slug;

  /// Link público, o `null` mientras el negocio no tenga nombre (sin slug).
  String? get bookingLink {
    final current = slug;
    return current == null ? null : publicBookingLink(_apiUrl(), current);
  }

  bool get nameChanged => nameText.value.trim() != (saved.value?.name ?? '');

  /// Lo que se guardaría: `null` = sin horario.
  OpeningHours? get _hoursToSave => limitsHours.value ? draftHours.value : null;

  bool get hoursChanged => _hoursToSave != saved.value?.openingHours;

  /// Zonas que contienen el texto buscado, sin distinguir mayúsculas; `_` y
  /// espacio cuentan igual ("new york" encuentra `America/New_York`).
  List<String> get filteredZones {
    final text = _normalize(query.value);
    if (text.isEmpty) return _zones;
    return [
      for (final zone in _zones)
        if (_normalize(zone).contains(text)) zone,
    ];
  }

  /// `UTC-05:00` de [zone] ahora.
  String offsetOf(String zone) =>
      formatUtcOffset(BusinessTimeZone.utcOffset(zone));

  /// Hora actual en [zone] (`3:45 p. m.`).
  String nowIn(String zone) => formatTime(BusinessTimeZone.now(zone));

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    nameController.addListener(_onNameChanged);
    load();
  }

  @override
  void onClose() {
    searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    nameController
      ..removeListener(_onNameChanged)
      ..dispose();
    super.onClose();
  }

  void _onSearchChanged() => query.value = searchController.text;
  void _onNameChanged() => nameText.value = nameController.text;

  Future<void> load() async {
    status.value = BusinessSettingsStatus.loading;
    loadError.value = null;
    loadErrorIsFinal.value = false;
    final result = await _getSettings(NoParams());
    result.fold(
      (failure) {
        loadError.value = failure.message;
        loadErrorIsFinal.value = failure is ForbiddenFailure;
        status.value = BusinessSettingsStatus.error;
      },
      (settings) {
        _apply(settings);
        nameController.text = settings.name ?? '';
        _resetHours(settings);
        status.value = BusinessSettingsStatus.ready;
      },
    );
  }

  void _apply(BusinessSettings settings) => saved.value = settings;

  void _resetHours(BusinessSettings settings) {
    limitsHours.value = settings.hasOpeningHours;
    draftHours.value = settings.openingHours ?? _defaultWeek();
  }

  /// Lunes a sábado de 9:00 a 18:00; domingo cerrado.
  static OpeningHours _defaultWeek() => OpeningHours([
        for (var day = OpeningHoursRange.monday; day < OpeningHoursRange.sunday;
            day++)
          OpeningHoursRange(dayOfWeek: day, hours: defaultRange),
      ]);

  // --- Nombre ---------------------------------------------------------------

  Future<bool> saveName() async {
    if (isSavingName.value || !nameChanged) return false;
    isSavingName.value = true;
    final result = await _updateName(nameController.text);
    isSavingName.value = false;
    return result.fold(
      (failure) {
        _showFailure(failure, 'No se guardó el nombre');
        return false;
      },
      (settings) {
        _apply(settings);
        nameController.text = settings.name ?? '';
        AppSnackbar.success(
            settings.slug == null
                ? 'Nombre guardado'
                : 'Tu link de reservas: ${bookingLink ?? ''}',
            title: 'Nombre guardado');
        return true;
      },
    );
  }

  // --- Link público -----------------------------------------------------------

  Future<void> copyLink() async {
    final link = bookingLink;
    if (link == null) return;
    await Clipboard.setData(ClipboardData(text: link));
    AppSnackbar.success('Pégalo donde quieras compartirlo',
        title: 'Link copiado');
  }

  /// Comparte por WhatsApp (elige el chat en la app). El menú nativo de
  /// compartir necesitaría una dependencia nueva.
  Future<void> shareLink() async {
    final link = bookingLink;
    if (link == null) return;
    final name = saved.value?.name;
    final text = 'Reserva tu cita${name == null ? '' : ' en $name'}: $link';
    final opened = await _openLink(
        Uri.https('wa.me', '/', {'text': text}));
    if (!opened) {
      AppSnackbar.warning('No se pudo abrir WhatsApp. Copia el link y '
          'compártelo a mano.');
    }
  }

  Future<void> openLink() async {
    final link = bookingLink;
    if (link == null) return;
    if (!await _openLink(Uri.parse(link))) {
      AppSnackbar.warning('No se pudo abrir el link');
    }
  }

  // --- Horario de apertura ----------------------------------------------------

  void setLimitsHours(bool value) => limitsHours.value = value;

  List<WorkHours> rangesOn(int day) =>
      [for (final range in draftHours.value.rangesOn(day)) range.hours];

  bool isClosedOn(int day) => draftHours.value.isClosedOn(day);

  void setDayOpen(int day, bool open) => draftHours.value =
      draftHours.value.withDay(day, open ? const [defaultRange] : const []);

  /// Añade una franja después de la última del día (p. ej. la tarde tras
  /// cerrar a mediodía).
  void addRange(int day) {
    final ranges = rangesOn(day);
    final last = ranges.isEmpty ? null : ranges.last;
    final start = last == null ? defaultRange.start : _plusHours(last.end, 1);
    final end = _plusHours(start, 4);
    draftHours.value = draftHours.value.withDay(day, [
      ...ranges,
      WorkHours(start: start, end: end.compareTo(start) > 0 ? end : '23:59'),
    ]);
  }

  void updateRange(int day, int index, {String? start, String? end}) {
    final ranges = rangesOn(day);
    if (index < 0 || index >= ranges.length) return;
    final current = ranges[index];
    ranges[index] =
        WorkHours(start: start ?? current.start, end: end ?? current.end);
    draftHours.value = draftHours.value.withDay(day, ranges);
  }

  void removeRange(int day, int index) {
    final ranges = rangesOn(day);
    if (index < 0 || index >= ranges.length) return;
    ranges.removeAt(index);
    draftHours.value = draftHours.value.withDay(day, ranges);
  }

  void discardHours() {
    final current = saved.value;
    if (current != null) _resetHours(current);
  }

  Future<bool> saveOpeningHours() async {
    if (isSavingHours.value || !hoursChanged) return false;
    isSavingHours.value = true;
    final result = await _updateOpeningHours(_hoursToSave);
    isSavingHours.value = false;
    return result.fold(
      (failure) {
        _showFailure(failure, 'No se guardó el horario');
        return false;
      },
      (settings) {
        _apply(settings);
        _resetHours(settings);
        AppSnackbar.success(
            settings.hasOpeningHours
                ? 'Las citas solo se agendan dentro de este horario'
                : 'El negocio ya no limita las citas por horario',
            title: 'Horario guardado');
        return true;
      },
    );
  }

  static String _plusHours(String hhmm, int hours) {
    final parts = hhmm.split(':');
    final hour = (int.tryParse(parts.first) ?? 9) + hours;
    if (hour > 23) return '23:59';
    return '${hour.toString().padLeft(2, '0')}:${parts.length > 1 ? parts[1] : '00'}';
  }

  // --- Zona horaria -----------------------------------------------------------

  void clearSearch() => searchController.clear();

  /// Guarda la zona [zone] tras confirmar. `true` si se guardó.
  Future<bool> saveTimeZone(String zone) async {
    if (zone == savedZone || isSavingZone.value) return false;
    final confirmed = await AppDialogs.confirm(
      title: '¿Cambiar la zona horaria?',
      message: 'Las horas del negocio pasarán a $zone (${offsetOf(zone)}). '
          'Las citas, pagos y bloqueos ya creados conservan la hora con la '
          'que se guardaron.',
      confirmLabel: 'Cambiar zona',
      icon: Icons.public,
    );
    if (!confirmed) return false;

    isSavingZone.value = true;
    final result = await _updateTimeZone(zone);
    final ok = await result.fold(
      (failure) async {
        AppSnackbar.error(failure.message, title: 'No se pudo guardar');
        return false;
      },
      (settings) async {
        _apply(settings);
        await _session.reload();
        AppSnackbar.success('Las horas se muestran en ${settings.timeZone}',
            title: 'Zona horaria guardada');
        return true;
      },
    );
    isSavingZone.value = false;
    return ok;
  }

  static void _showFailure(Failure failure, String title) {
    if (failure is ValidationFailure) {
      AppSnackbar.warning(failure.message, title: 'Revisa los datos');
    } else {
      AppSnackbar.error(failure.message, title: title);
    }
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll('_', ' ');
}
