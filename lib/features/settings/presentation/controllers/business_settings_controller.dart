import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/settings/domain/usecases/get_business_settings_usecase.dart';
import 'package:login_signup/features/settings/domain/usecases/update_business_time_zone_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Estado de la carga inicial de la configuración.
enum BusinessSettingsStatus { loading, ready, error }

/// Configuración del negocio (solo Owner: la ruta lleva
/// `RoleMiddleware.ownerOnly()`). Hoy, su zona horaria (D-15).
///
/// Al guardar una zona nueva, la capa de datos ya la fija en la sesión;
/// aquí se recarga el `SessionController`, y las pantallas con horas ya
/// cargadas (la agenda) las vuelven a pedir porque escuchan
/// `SessionController.onTimeZoneChanged`.
class BusinessSettingsController extends GetxController {
  final GetBusinessSettingsUseCase _getSettings;
  final UpdateBusinessTimeZoneUseCase _updateTimeZone;
  final SessionController _session;
  final List<String> _zones;

  BusinessSettingsController({
    required GetBusinessSettingsUseCase getBusinessSettingsUseCase,
    required UpdateBusinessTimeZoneUseCase updateBusinessTimeZoneUseCase,
    required SessionController session,
    List<String>? zones,
  })  : _getSettings = getBusinessSettingsUseCase,
        _updateTimeZone = updateBusinessTimeZoneUseCase,
        _session = session,
        _zones = zones ?? BusinessTimeZone.names;

  final status = BusinessSettingsStatus.loading.obs;
  final loadError = RxnString();

  /// `true` si el error de carga no se arregla reintentando (sin permiso).
  final loadErrorIsFinal = false.obs;

  /// Zona guardada en el backend.
  final savedZone = RxnString();

  /// Zona elegida en la lista (aún sin guardar si difiere de [savedZone]).
  final selectedZone = RxnString();

  final query = ''.obs;
  final isSaving = false.obs;
  final searchController = TextEditingController();

  bool get hasChanges =>
      selectedZone.value != null && selectedZone.value != savedZone.value;

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
    load();
  }

  @override
  void onClose() {
    searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.onClose();
  }

  void _onSearchChanged() => query.value = searchController.text;

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
        savedZone.value = settings.timeZone;
        selectedZone.value = settings.timeZone;
        status.value = BusinessSettingsStatus.ready;
      },
    );
  }

  void select(String zone) => selectedZone.value = zone;

  void clearSearch() => searchController.clear();

  /// Guarda la zona elegida tras confirmar. `true` si se guardó.
  Future<bool> save() async {
    final zone = selectedZone.value;
    if (zone == null || !hasChanges || isSaving.value) return false;
    final confirmed = await AppDialogs.confirm(
      title: '¿Cambiar la zona horaria?',
      message: 'Las horas del negocio pasarán a $zone (${offsetOf(zone)}). '
          'Las citas, pagos y bloqueos ya creados conservan la hora con la '
          'que se guardaron.',
      confirmLabel: 'Cambiar zona',
      icon: Icons.public,
    );
    if (!confirmed) return false;

    isSaving.value = true;
    final result = await _updateTimeZone(zone);
    final saved = await result.fold(
      (failure) async {
        AppSnackbar.error(failure.message, title: 'No se pudo guardar');
        return false;
      },
      (settings) async {
        savedZone.value = settings.timeZone;
        selectedZone.value = settings.timeZone;
        await _session.reload();
        AppSnackbar.success('Las horas se muestran en ${settings.timeZone}',
            title: 'Zona horaria guardada');
        return true;
      },
    );
    isSaving.value = false;
    return saved;
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll('_', ' ');
}
