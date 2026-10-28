import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/di/session_scope.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'package:login_signup/core/utils/app_logger.dart';

/// Único punto de cierre de sesión: el botón del drawer ([logout]) y la
/// sesión expirada ([endSession] con `expired: true`, conectado en
/// `SessionBinding`). Alcance de app (permanente).
///
/// Orden: borra la sesión → limpieza local del repositorio → navega a login
/// → cuando las pantallas de la sesión ya no están montadas, borra los
/// controllers de las features (`SessionScope.reset`) → avisa.
class LogoutController extends GetxController {
  final LogoutUseCase _logoutUseCase;
  final Future<void> Function() _resetScope;
  final Future<void> Function() _afterNavigation;

  final RxBool isLoading = false.obs;
  bool _ending = false;

  LogoutController({
    required LogoutUseCase logoutUseCase,
    Future<void> Function()? resetScope,
    Future<void> Function()? afterNavigation,
  })  : _logoutUseCase = logoutUseCase,
        _resetScope = resetScope ?? SessionScope.reset,
        _afterNavigation = afterNavigation ?? _nextFrames;

  Future<void> logout() => endSession();

  Future<void> endSession({bool expired = false}) async {
    if (_ending) return;
    _ending = true;
    isLoading.value = true;
    try {
      if (Get.isRegistered<SessionController>()) {
        await Get.find<SessionController>().end();
      }
      final result = await _logoutUseCase(NoParams());
      result.fold(
        (failure) => AppLogger.error(
            'Logout: limpieza local con error', failure.message),
        (_) {},
      );

      // Sin await: el Future de offAllNamed solo termina cuando la ruta de
      // login se cierra (en el próximo login), y bloquearía este método.
      Get.offAllNamed(GetRoutes.login);
      await _afterNavigation();
      await _resetScope();

      if (expired) {
        AppSnackbar.warning('Tu sesión expiró. Inicia sesión de nuevo.',
            title: 'Sesión expirada');
      } else {
        AppSnackbar.success('Sesión cerrada correctamente');
      }
    } catch (e) {
      AppLogger.error('Error en logout', e);
      AppSnackbar.error('Error al cerrar sesión');
    } finally {
      isLoading.value = false;
      _ending = false;
    }
  }

  /// Deja que la navegación quite las pantallas de la sesión antes de borrar
  /// sus controllers (si no, un `Obx` montado podría leer uno ya cerrado).
  static Future<void> _nextFrames() async {
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;
  }
}
