import 'package:get/get.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/features/auth/domain/usecases/logout_usecase.dart';
import 'package:login_signup/features/auth/presentation/controllers/logout_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/user_info_controller.dart';
import 'package:login_signup/shared/controller/session_controller.dart';

/// Controllers de sesión con alcance de app (permanentes, `SessionScope`
/// regla 1): `SessionController`, `LogoutController` y `UserInfoController`.
/// Registro **único**; lo llama `DependencyInjection` al arrancar, después de
/// `AuthDependencies` (necesita `LogoutUseCase`). Antes era `UserModule`.
abstract final class SessionBinding {
  static void register() {
    final service = Get.find<SessionService>();
    if (!Get.isRegistered<SessionController>()) {
      Get.put<SessionController>(SessionController(service), permanent: true);
    }

    if (!Get.isRegistered<LogoutController>()) {
      Get.put<LogoutController>(
        LogoutController(logoutUseCase: Get.find<LogoutUseCase>()),
        permanent: true,
      );
    }
    // 401 del Dio 'api' con el token vigente: SessionService ya borró el
    // token; aquí se limpia la UI y se lleva al login.
    service.onSessionExpired =
        () => Get.find<LogoutController>().endSession(expired: true);

    if (!Get.isRegistered<UserInfoController>()) {
      Get.put<UserInfoController>(UserInfoController(), permanent: true);
    }
  }
}
