import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/app_logger.dart';
import 'package:login_signup/features/theme/data/datasources/theme_local_datasource.dart';
import 'package:login_signup/features/theme/data/models/theme_preference_model.dart';
import 'package:login_signup/features/theme/data/repositories/theme_repository_impl.dart';
import 'package:login_signup/features/theme/domain/entities/theme_preference.dart';
import 'package:login_signup/features/theme/domain/usecases/get_theme_preference_usecase.dart';
import 'package:login_signup/features/theme/domain/usecases/resolve_palette.dart';
import 'package:login_signup/features/theme/domain/usecases/save_theme_preference_usecase.dart';
import 'package:login_signup/shared/controllers/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Failure? leftOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => null);

T rightOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('Left: ${leftOf(result)}'));

class _BrokenDataSource implements ThemeLocalDataSource {
  @override
  Future<ThemePreferenceModel> read() async => throw StateError('disco');

  @override
  Future<void> write(ThemePreferenceModel model) async =>
      throw StateError('disco');
}

void main() {
  group('AppPalette', () {
    test('ids estables, iguales a los del backend (THEME_PALETTES)', () {
      expect(AppPalette.values.map((p) => p.id),
          ['lavanda', 'rosa', 'azul', 'turquesa', 'coral', 'grafito']);
      expect(AppPalette.fallback, AppPalette.lavanda);
    });

    test('fromId: tolera espacios y mayúsculas; desconocido → null', () {
      for (final palette in AppPalette.values) {
        expect(AppPalette.fromId(palette.id), palette);
      }
      expect(AppPalette.fromId(' Rosa '), AppPalette.rosa);
      for (final raw in [null, '', 'morado', 'lavender', 3, true]) {
        expect(AppPalette.fromId(raw), isNull, reason: '$raw');
      }
    });
  });

  group('resolvePalette (D-22)', () {
    test('manda el dispositivo; luego el negocio; luego lavanda', () {
      expect(resolvePalette(AppPalette.rosa, AppPalette.azul), AppPalette.rosa);
      expect(resolvePalette(null, AppPalette.azul), AppPalette.azul);
      expect(resolvePalette(null, null), AppPalette.lavanda);
      expect(resolvePalette(AppPalette.grafito, null), AppPalette.grafito);
    });

    test('todas las combinaciones', () {
      for (final device in [null, ...AppPalette.values]) {
        for (final business in [null, ...AppPalette.values]) {
          expect(resolvePalette(device, business),
              device ?? business ?? AppPalette.lavanda);
        }
      }
    });
  });

  group('ThemePreference', () {
    test('inicial: sin paleta propia (la del negocio) y modo claro', () {
      expect(ThemePreference.initial,
          const ThemePreference(mode: ThemeModePreference.light));
      expect(ThemePreference.initial.usesBusinessPalette, isTrue);
    });

    test('igualdad y copyWith', () {
      const a = ThemePreference(
          palette: AppPalette.coral, mode: ThemeModePreference.dark);
      expect(a.copyWith(), a);
      expect(a.hashCode,
          const ThemePreference(
                  palette: AppPalette.coral, mode: ThemeModePreference.dark)
              .hashCode);
      expect(a.copyWith(mode: ThemeModePreference.system).mode,
          ThemeModePreference.system);
      expect(a.copyWith(palette: AppPalette.rosa).palette, AppPalette.rosa);
      final business = a.copyWith(usesBusinessPalette: true);
      expect(business.palette, isNull);
      expect(business.mode, ThemeModePreference.dark);
      expect(a == business, isFalse);
    });

    test('ThemeModePreference.fromId', () {
      for (final mode in ThemeModePreference.values) {
        expect(ThemeModePreference.fromId(mode.id), mode);
      }
      expect(ThemeModePreference.fromId('oscuro'), isNull);
      expect(ThemeModePreference.fromId(null), isNull);
    });
  });

  group('ThemePreferenceModel', () {
    test('guarda el modo con el formato heredado de ThemeController', () {
      final model = ThemePreferenceModel.fromEntity(const ThemePreference(
          palette: AppPalette.azul, mode: ThemeModePreference.highContrast));
      expect(model.storedMode, 'ThemeType.highContrast');
      expect(model.storedPalette, 'azul');
      expect(model.toEntity(),
          const ThemePreference(
              palette: AppPalette.azul,
              mode: ThemeModePreference.highContrast));
    });

    test('el formato coincide con el enum ThemeType de hoy', () {
      for (final type in ThemeType.values) {
        final mode =
            ThemePreferenceModel(storedMode: type.toString()).toEntity().mode;
        expect(mode.id, type.name);
      }
    });

    test('lee el id suelto; ilegible o vacío → valores iniciales', () {
      expect(const ThemePreferenceModel(storedMode: 'dark').toEntity().mode,
          ThemeModePreference.dark);
      expect(const ThemePreferenceModel().toEntity(), ThemePreference.initial);
      expect(
          const ThemePreferenceModel(
                  storedMode: 'ThemeType.sepia', storedPalette: 'morado')
              .toEntity(),
          ThemePreference.initial);
    });
  });

  group('repositorio local (SharedPreferences)', () {
    late ThemeRepositoryImpl repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = ThemeRepositoryImpl(ThemeLocalDataSourceImpl());
    });

    test('sin nada guardado → inicial', () async {
      expect(rightOf(await GetThemePreferenceUseCase(repository)(NoParams())),
          ThemePreference.initial);
    });

    test('conserva la elección de los usuarios actuales (clave app_theme)',
        () async {
      SharedPreferences.setMockInitialValues(
          {'app_theme': ThemeType.dark.toString()});
      expect(rightOf(await repository.getPreference()),
          const ThemePreference(mode: ThemeModePreference.dark));
    });

    test('guardar y leer; null quita la paleta propia', () async {
      const chosen = ThemePreference(
          palette: AppPalette.turquesa, mode: ThemeModePreference.system);
      expect(rightOf(await SaveThemePreferenceUseCase(repository)(chosen)),
          chosen);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme'), 'ThemeType.system');
      expect(prefs.getString('app_palette'), 'turquesa');
      expect(rightOf(await repository.getPreference()), chosen);

      final business = chosen.copyWith(usesBusinessPalette: true);
      rightOf(await repository.savePreference(business));
      expect(prefs.containsKey('app_palette'), isFalse);
      expect(rightOf(await repository.getPreference()), business);
    });

    test('ThemeController de hoy lee lo que guarda el repositorio', () async {
      rightOf(await repository.savePreference(
          const ThemePreference(mode: ThemeModePreference.highContrast)));
      final controller = ThemeController()..onInit();
      await Future<void>.delayed(Duration.zero);
      expect(controller.themeType, ThemeType.highContrast);
    });

    test('un fallo del almacenamiento → Left, sin excepción', () async {
      final original = AppLogger.sink;
      final logged = <String>[];
      AppLogger.sink = logged.add;
      addTearDown(() => AppLogger.sink = original);
      final broken = ThemeRepositoryImpl(_BrokenDataSource());
      expect(leftOf(await broken.getPreference()), isA<Failure>());
      expect(leftOf(await broken.savePreference(ThemePreference.initial)),
          isA<Failure>());
      expect(logged, hasLength(2));
    });
  });
}
