import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/shared/controller/session_controller.dart';
import 'auth_navigation.dart';

/// Aviso "Verifica tu email" del menú lateral mientras el Owner no haya
/// verificado su correo (puede usar la app sin hacerlo, CLAUDE §1).
///
/// El JWT no trae `is_email_verified`; lo trae `GET /auth/employees`, que
/// devuelve al propio Owner junto a su equipo (`GetEmployeesUseCase`). Lo
/// registra la ruta home: verificar vuelve a la home (`offAllNamed`), se
/// crea uno nuevo y el aviso desaparece. Si no se puede saber, no se avisa.
class EmailVerificationNoticeController extends GetxController {
  final GetEmployeesUseCase _getTeam;
  final SessionController _session;

  EmailVerificationNoticeController({
    required GetEmployeesUseCase getEmployeesUseCase,
    required SessionController session,
  })  : _getTeam = getEmployeesUseCase,
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
    final result = await _getTeam(NoParams());
    pendingEmail.value = result.fold((_) => null, (team) {
      final me = team.firstWhereOrNull((e) => e.id == _session.userId);
      if (me == null || me.isEmailVerified) return null;
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
