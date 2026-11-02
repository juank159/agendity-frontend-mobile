import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/app_logger.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/usecases/get_business_settings_usecase.dart';
import 'package:login_signup/features/theme/domain/entities/theme_preference.dart';
import 'package:login_signup/features/theme/domain/usecases/business_palette_memory_usecases.dart';
import 'package:login_signup/features/theme/domain/usecases/get_theme_preference_usecase.dart';
import 'package:login_signup/features/theme/domain/usecases/resolve_palette.dart';
import 'package:login_signup/features/theme/domain/usecases/save_theme_preference_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';

/// Apariencia de la app (D-22). Registro **único** en
/// `core/di/init_dependencies.dart` (permanente: el tema sobrevive al logout).
///
/// - Paleta = `resolvePalette(la del dispositivo, la del negocio)`; la del
///   negocio llega con `GetBusinessSettingsUseCase` al iniciar sesión y cada
///   vez que la sincronización trae datos (`SyncController.onDataChanged`).
/// - Arranca con la última paleta del negocio guardada en el dispositivo, para
///   no parpadear de lavanda a la del negocio.
/// - El modo es siempre del dispositivo.
///
/// No cambia el tema por su cuenta: `main.dart` lee [theme], [darkTheme] y
/// [themeMode] dentro de un `GetX<ThemeController>`. También guarda el nombre
/// del negocio que trae la misma lectura, para la cabecera del menú.
class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  final GetThemePreferenceUseCase _getPreference;
  final SaveThemePreferenceUseCase _savePreference;
  final GetLastBusinessPaletteUseCase _getLastBusinessPalette;
  final RememberBusinessPaletteUseCase _rememberBusinessPalette;

  /// `null` = sin configuración del negocio (tests de pantallas sueltas).
  final GetBusinessSettingsUseCase? _getBusinessSettings;
  final SessionController? _session;
  final SyncController? _sync;

  ThemeController({
    GetThemePreferenceUseCase? getPreference,
    SaveThemePreferenceUseCase? savePreference,
    GetLastBusinessPaletteUseCase? getLastBusinessPalette,
    RememberBusinessPaletteUseCase? rememberBusinessPalette,
    GetBusinessSettingsUseCase? getBusinessSettings,
    SessionController? session,
    SyncController? sync,
  })  : _getPreference = getPreference ?? Get.find(),
        _savePreference = savePreference ?? Get.find(),
        _getLastBusinessPalette = getLastBusinessPalette ?? Get.find(),
        _rememberBusinessPalette = rememberBusinessPalette ?? Get.find(),
        _getBusinessSettings = getBusinessSettings ??
            (Get.isRegistered<GetBusinessSettingsUseCase>()
                ? Get.find<GetBusinessSettingsUseCase>()
                : null),
        _session = session ??
            (Get.isRegistered<SessionController>()
                ? Get.find<SessionController>()
                : null),
        _sync = sync ??
            (Get.isRegistered<SyncController>()
                ? Get.find<SyncController>()
                : null);

  /// Lo elegido en este dispositivo (paleta propia o `null`, y modo).
  final preference = ThemePreference.initial.obs;

  /// Paleta del negocio (la última conocida mientras no se lea otra).
  final businessPalette = Rxn<AppPalette>();

  /// Nombre del negocio de la sesión (cabecera del menú); `null` sin sesión
  /// o sin nombre.
  final businessName = RxnString();

  final List<Worker> _workers = [];
  int _businessRequest = 0;
  String? _sessionUser;

  // --- Lecturas -----------------------------------------------------------------

  ThemeModePreference get mode => preference.value.mode;

  /// `true` si el dispositivo sigue la paleta del negocio.
  bool get usesBusinessPalette => preference.value.usesBusinessPalette;

  /// Paleta que se pinta (D-22).
  AppPalette get palette =>
      resolvePalette(preference.value.palette, businessPalette.value);

  ThemeMode get themeMode => switch (mode) {
        ThemeModePreference.light => ThemeMode.light,
        ThemeModePreference.dark ||
        ThemeModePreference.highContrast =>
          ThemeMode.dark,
        ThemeModePreference.system => ThemeMode.system,
      };

  ThemeData get theme => ThemeConfig.of(palette, AppThemeVariant.light);

  /// El alto contraste es el tema oscuro alternativo (con `ThemeMode.dark`).
  ThemeData get darkTheme => ThemeConfig.of(
      palette,
      mode == ThemeModePreference.highContrast
          ? AppThemeVariant.highContrast
          : AppThemeVariant.dark);

  // --- Ciclo de vida --------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    final session = _session;
    if (session != null) {
      _sessionUser = session.session.value?.userId;
      _workers.add(ever(session.session, (_) => _onSessionChanged()));
    }
    final sync = _sync;
    if (sync != null) _workers.add(sync.onDataChanged(refreshBusiness));
    unawaited(load());
  }

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }

  /// Lee la preferencia y la última paleta del negocio; con sesión, también
  /// la configuración del negocio.
  Future<void> load() async {
    final saved = await _getPreference(NoParams());
    saved.fold(
      (failure) => AppLogger.error('No se leyó la apariencia', failure.message),
      (value) => preference.value = value,
    );
    final last = await _getLastBusinessPalette(NoParams());
    last.fold((_) {}, (value) {
      // Una lectura del negocio que ya llegó manda sobre la copia guardada.
      if (_businessRequest == 0) businessPalette.value = value;
    });
    if (_session?.isLoggedIn ?? false) await refreshBusiness();
  }

  void _onSessionChanged() {
    final user = _session?.session.value?.userId;
    if (user == _sessionUser) return;
    _sessionUser = user;
    if (user == null) {
      // Al cerrar sesión se conserva la paleta (el login no parpadea).
      businessName.value = null;
      return;
    }
    unawaited(refreshBusiness());
  }

  /// Vuelve a leer la configuración del negocio (local; sin conexión también)
  /// y aplica su paleta. Silencioso: un fallo conserva la paleta conocida.
  Future<void> refreshBusiness() async {
    final getSettings = _getBusinessSettings;
    if (getSettings == null || !(_session?.isLoggedIn ?? false)) return;
    final request = ++_businessRequest;
    final result = await getSettings(NoParams());
    if (request != _businessRequest) return; // Llegó una lectura más nueva.
    result.fold(
      (failure) => AppLogger.debug(
          'Tema: sin configuración del negocio (${failure.message})'),
      applyBusinessSettings,
    );
  }

  /// Aplica la configuración del negocio recién leída o guardada (p. ej. tras
  /// cambiar el "Color del negocio" en Mi negocio).
  void applyBusinessSettings(BusinessSettings settings) {
    ++_businessRequest;
    businessName.value = settings.name;
    final palette = settings.themePalette;
    if (palette == businessPalette.value) return;
    businessPalette.value = palette;
    unawaited(_rememberBusinessPalette(palette));
  }

  // --- Cambios del usuario ----------------------------------------------------------

  Future<void> setMode(ThemeModePreference mode) =>
      _save(preference.value.copyWith(mode: mode));

  /// Paleta propia de este dispositivo; `null` = "Usar el del negocio".
  Future<void> setPalette(AppPalette? palette) => _save(palette == null
      ? preference.value.copyWith(usesBusinessPalette: true)
      : preference.value.copyWith(palette: palette));

  Future<void> _save(ThemePreference next) async {
    final previous = preference.value;
    preference.value = next;
    final result = await _savePreference(next);
    result.fold((failure) {
      AppLogger.error('No se guardó la apariencia', failure.message);
      preference.value = previous;
    }, (_) {});
  }
}
