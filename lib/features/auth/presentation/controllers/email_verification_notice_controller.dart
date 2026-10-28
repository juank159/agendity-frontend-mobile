import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:login_signup/shared/controller/session_controller.dart';
import 'auth_navigation.dart';

/// Aviso "Verifica tu email" del menú lateral mientras el Owner no haya
/// verificado su correo (puede usar la app sin hacerlo, CLAUDE §1).
///
/// El JWT no trae `is_email_verified`; lo trae `GET /auth/me`
/// (`GetCurrentUserUseCase`, 4.08c). Lo registra la ruta home: verificar vuelve a la home (`offAllNamed`), se
/// crea uno nuevo y el aviso desaparece. Si no se puede saber, no se avisa.
class EmailVerificationNoticeController extends GetxController {
  final GetCurrentUserUseCase _getMe;
  final SessionController _session;

  EmailVerificationNoticeController({
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required SessionController session,
  })  : _getMe = getCurrentUserUseCase,
        _session = session;

  /// Email por verificar del Owner; `null` = no hay aviso.
  final pendingEmail = RxnString();

  @override
  void onInit() {
    super.onInit();
    check();
  }

  Future<void> check() async {
    if (!_session.isOwner) {
      pendingEmail.value = null;
      return;
    }
    final result = await _getMe(NoParams());
    pendingEmail.value = result.fold((_) => null, (me) {
      if (me.isEmailVerified) return null;
      final email = me.email.trim().isEmpty ? _session.email : me.email.trim();
      return (email == null || email.isEmpty) ? null : email;
    });
  }

  /// Abre la verificación (pide el código al abrirse).
  Future<void> openVerification() async {
    final email = pendingEmail.value;
    if (email == null) return;
    await Get.toNamed(GetRoutes.verifyEmail,
        arguments: {AuthNavigation.emailKey: email});
  }
}
