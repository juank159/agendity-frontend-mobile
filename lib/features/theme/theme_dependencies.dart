import 'package:get/get.dart';
import 'package:login_signup/features/theme/data/datasources/theme_local_datasource.dart';
import 'package:login_signup/features/theme/data/repositories/theme_repository_impl.dart';
import 'package:login_signup/features/theme/domain/repositories/theme_repository.dart';
import 'package:login_signup/features/theme/domain/usecases/business_palette_memory_usecases.dart';
import 'package:login_signup/features/theme/domain/usecases/get_theme_preference_usecase.dart';
import 'package:login_signup/features/theme/domain/usecases/save_theme_preference_usecase.dart';

/// Datasource, repositorio y use cases de la apariencia del dispositivo
/// (D-22, ARQUITECTURA §4). Sin red ni sesión: se registra antes que
/// `ThemeController` (`init_dependencies`), que es de alcance de app.
abstract final class ThemeDependencies {
  static void init() {
    Get.lazyPut<ThemeLocalDataSource>(() => ThemeLocalDataSourceImpl(),
        fenix: true);
    Get.lazyPut<ThemeRepository>(
        () => ThemeRepositoryImpl(Get.find<ThemeLocalDataSource>()),
        fenix: true);
    Get.lazyPut(() => GetThemePreferenceUseCase(Get.find<ThemeRepository>()),
        fenix: true);
    Get.lazyPut(() => SaveThemePreferenceUseCase(Get.find<ThemeRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetLastBusinessPaletteUseCase(Get.find<ThemeRepository>()),
        fenix: true);
    Get.lazyPut(
        () => RememberBusinessPaletteUseCase(Get.find<ThemeRepository>()),
        fenix: true);
  }
}
