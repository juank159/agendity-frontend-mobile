import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/auth/domain/usecases/request_verification_code_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'auth_feedback.dart';
import 'auth_navigation.dart';
import 'package:login_signup/shared/controllers/code_countdown.dart';

/// Verificación del email del Owner recién registrado (`/verify-email`,
/// email en `arguments`). Pide el código al abrirse. El registro ya inició
/// la sesión y el Owner puede usar la app sin verificar (CLAUDE §1): al
/// verificar, o con "Verificar más tarde", entra a la home con esa sesión.
class EmailVerificationController extends GetxController {
  final RequestVerificationCodeUseCase _requestCode;
  final VerifyEmailUseCase _verify;
  final SessionController _session;

  EmailVerificationController({
    required RequestVerificationCodeUseCase requestCodeUseCase,
    required VerifyEmailUseCase verifyEmailUseCase,
    SessionController? session,
    String? email,
  })  : _requestCode = requestCodeUseCase,
        _verify = verifyEmailUseCase,
        _session = session ?? Get.find<SessionController>(),
        email = email ?? AuthNavigation.emailArgument();

  final String email;

  final codeController = TextEditingController();
  final isSending = false.obs;
  final isVerifying = false.obs;
  final errorMessage = RxnString();

  late final countdown = CodeCountdown(
    onExpired: () => errorMessage.value = 'El código venció. Pide uno nuevo.',
  );

  bool get isBusy => isSending.value || isVerifying.value;

  @override
  void onInit() {
    super.onInit();
    if (email.isEmpty) {
      errorMessage.value =
          'No sabemos a qué correo enviar el código. Inicia sesión de nuevo.';
      return;
    }
    requestVerificationCode();
  }

  @override
  void onClose() {
    countdown.dispose();
    codeController.dispose();
    super.onClose();
  }

  /// Envía (o reenvía) el código.
  Future<void> requestVerificationCode() async {
    if (isBusy || email.isEmpty) return;
    isSending.value = true;
    errorMessage.value = null;
    final result = await _requestCode(email);
    if (isClosed) return;
    isSending.value = false;
    result.fold(
      (failure) => errorMessage.value =
          'No se pudo enviar el código: ${AuthFeedback.messageFor(failure)}',
      (_) {
        countdown.start();
        AppSnackbar.info('Enviamos un código de 6 dígitos a $email',
            title: 'Código enviado');
      },
    );
  }

  Future<void> verifyEmail() async {
    if (isBusy || email.isEmpty) return;
    isVerifying.value = true;
    errorMessage.value = null;
    final result = await _verify(
        VerifyEmailParams(email: email, code: codeController.text));
    if (isClosed) return;

    await result.fold(
      (failure) async {
        isVerifying.value = false;
        errorMessage.value = AuthFeedback.messageFor(failure);
      },
      (_) async {
        countdown.stop();
        if (await _enterApp()) {
          AppSnackbar.success('Tu correo quedó verificado',
              title: 'Correo verificado');
        }
        if (!isClosed) isVerifying.value = false;
      },
    );
  }

  /// El Owner entra sin verificar.
  Future<void> skip() => _enterApp();

  /// Home con la sesión del registro; si ya no hay sesión, al login.
  Future<bool> _enterApp() async {
    if (await AuthNavigation.enterHome(
        session: _session, reportMissing: false)) {
      return true;
    }
    Get.offAllNamed(GetRoutes.login);
    AppSnackbar.info('Inicia sesión para continuar');
    return false;
  }
}
