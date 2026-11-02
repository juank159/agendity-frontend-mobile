import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';
import 'package:login_signup/features/settings/domain/repositories/settings_repository.dart';
import 'package:login_signup/features/settings/domain/usecases/get_business_settings_usecase.dart';
import 'package:login_signup/features/theme/data/datasources/theme_local_datasource.dart';
import 'package:login_signup/features/theme/data/repositories/theme_repository_impl.dart';
import 'package:login_signup/features/theme/domain/entities/theme_preference.dart';
import 'package:login_signup/features/theme/domain/usecases/business_palette_memory_usecases.dart';
import 'package:login_signup/features/theme/domain/usecases/get_theme_preference_usecase.dart';
import 'package:login_signup/features/theme/domain/usecases/save_theme_preference_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/controllers/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/session/memory_token_store.dart';

/// Configuración del negocio en memoria (solo `getSettings`).
class _FakeSettings implements SettingsRepository {
  Either<Failure, BusinessSettings> next;
  int reads = 0;

  _FakeSettings(this.next);

  @override
  Future<Either<Failure, BusinessSettings>> getSettings() async {
    reads++;
    return next;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSettings settings;
  late SessionController session;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = _FakeSettings(const Right(BusinessSettings(
        timeZone: 'America/Bogota',
        name: 'Cejas Luna',
        themePalette: AppPalette.rosa)));
    final store = MemoryTokenStore();
    session = SessionController(SessionService(
        tokenStore: store, repository: SessionRepository(store)));
  });

  tearDown(Get.reset);

  void logIn([String user = 'u1']) => session.session.value = Session(
      token: 't-$user',
      userId: user,
      name: 'Ana',
      email: 'ana@negocio.co',
      roles: const [SessionRole.owner]);

  ThemeController build() {
    final repository = ThemeRepositoryImpl(ThemeLocalDataSourceImpl());
    return ThemeController(
      getPreference: GetThemePreferenceUseCase(repository),
      savePreference: SaveThemePreferenceUseCase(repository),
      getLastBusinessPalette: GetLastBusinessPaletteUseCase(repository),
      rememberBusinessPalette: RememberBusinessPaletteUseCase(repository),
      getBusinessSettings: GetBusinessSettingsUseCase(settings),
      session: session,
    );
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('modos: alto contraste = darkTheme alternativo con ThemeMode.dark',
      () async {
    final controller = build()..onInit();
    await settle();
    expect(controller.mode, ThemeModePreference.light);
    expect(controller.themeMode, ThemeMode.light);

    await controller.setMode(ThemeModePreference.highContrast);
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.darkTheme,
        same(ThemeConfig.of(AppPalette.lavanda, AppThemeVariant.highContrast)));

    await controller.setMode(ThemeModePreference.dark);
    expect(controller.darkTheme,
        same(ThemeConfig.of(AppPalette.lavanda, AppThemeVariant.dark)));
    await controller.setMode(ThemeModePreference.system);
    expect(controller.themeMode, ThemeMode.system);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_theme'), 'ThemeType.system');
  });

  test('lee la preferencia guardada (formato heredado de ThemeType)', () async {
    SharedPreferences.setMockInitialValues(
        {'app_theme': 'ThemeType.dark', 'app_palette': 'azul'});
    final controller = build();
    await controller.load();
    expect(controller.mode, ThemeModePreference.dark);
    expect(controller.palette, AppPalette.azul);
    expect(controller.theme,
        same(ThemeConfig.of(AppPalette.azul, AppThemeVariant.light)));
  });

  test('D-22: dispositivo > negocio > lavanda', () async {
    final controller = build();
    await controller.load();
    expect(controller.palette, AppPalette.lavanda);

    logIn();
    await controller.refreshBusiness();
    expect(controller.businessPalette.value, AppPalette.rosa);
    expect(controller.palette, AppPalette.rosa);

    await controller.setPalette(AppPalette.turquesa);
    expect(controller.palette, AppPalette.turquesa);
    expect(controller.usesBusinessPalette, isFalse);

    await controller.setPalette(null);
    expect(controller.usesBusinessPalette, isTrue);
    expect(controller.palette, AppPalette.rosa);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('app_palette'), isFalse);
  });

  test('arranca con la última paleta del negocio (sin parpadeo)', () async {
    SharedPreferences.setMockInitialValues({'app_business_palette': 'coral'});
    final controller = build();
    await controller.load();
    // Sin sesión todavía: no lee la configuración, pinta la recordada.
    expect(settings.reads, 0);
    expect(controller.palette, AppPalette.coral);
  });

  test('al iniciar sesión lee el negocio, lo recuerda y trae el nombre',
      () async {
    final controller = build()..onInit();
    await settle();
    expect(controller.businessName.value, isNull);

    logIn();
    await settle();
    await settle();
    expect(settings.reads, 1);
    expect(controller.palette, AppPalette.rosa);
    expect(controller.businessName.value, 'Cejas Luna');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_business_palette'), 'rosa');

    // Cerrar sesión conserva la paleta (el login no parpadea) y quita el
    // nombre.
    session.session.value = null;
    await settle();
    expect(controller.palette, AppPalette.rosa);
    expect(controller.businessName.value, isNull);
    controller.onClose();
  });

  test('un fallo al leer el negocio conserva la paleta conocida', () async {
    SharedPreferences.setMockInitialValues({'app_business_palette': 'azul'});
    settings.next = const Left(NetworkFailure());
    logIn();
    final controller = build();
    await controller.load();
    expect(settings.reads, 1);
    expect(controller.palette, AppPalette.azul);
  });

  test('applyBusinessSettings (Mi negocio) cambia la paleta al instante',
      () async {
    final controller = build();
    await controller.load();
    controller.applyBusinessSettings(const BusinessSettings(
        timeZone: 'America/Bogota', themePalette: AppPalette.grafito));
    expect(controller.palette, AppPalette.grafito);
    controller.applyBusinessSettings(
        const BusinessSettings(timeZone: 'America/Bogota'));
    expect(controller.palette, AppPalette.lavanda);
  });
}
