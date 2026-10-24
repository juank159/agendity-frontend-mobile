import 'package:get/get.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/shared/controller/session_controller.dart';
import '../../../features/auth/presentation/controllers/logout_controller.dart';
import '../../../features/auth/presentation/controllers/user_info_controller.dart';

class UserModule {
  /// Registro **único** de la sesión de la UI. Requiere `SessionService`
  /// (core) y `LogoutController` (AuthModule, que se inicia antes).
  static Future<void> init() async {
    try {
      final service = Get.find<SessionService>();
      if (!Get.isRegistered<SessionController>()) {
        Get.put<SessionController>(SessionController(service),
            permanent: true);
      }

      // 401 del Dio 'api' con el token vigente: SessionService ya borró el
      // token; aquí se limpia la UI y se lleva al login.
      service.onSessionExpired = () =>
          Get.find<LogoutController>().endSession(expired: true);

      if (!Get.isRegistered<UserInfoController>()) {
        Get.put<UserInfoController>(
          UserInfoController(),
          permanent: true,
        );
      }
    } catch (e) {
      print('Error initializing UserModule: $e');
      rethrow;
    }
  }
}
