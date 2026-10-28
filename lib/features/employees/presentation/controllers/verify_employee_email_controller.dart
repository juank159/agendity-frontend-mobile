import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/employees/domain/usecases/request_employee_verification_code_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/verify_employee_email_usecase.dart';
import 'package:login_signup/shared/controller/code_countdown.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'employee_feedback.dart';
import 'employee_navigation.dart';

/// Verificación del email de un empleado (`/verify-employee-email`). Envía
/// el código al abrirse; al verificarlo el backend lo **activa** y la
/// pantalla vuelve con `result: true` a quien la abrió (alta o lista).
/// Cancelar vuelve con `false`: el empleado queda pendiente de verificación.
class VerifyEmployeeEmailController extends GetxController {
  /// Espera antes de poder pedir otro código.
  static const resendDelay = Duration(seconds: 60);

  final RequestEmployeeVerificationCodeUseCase _requestCode;
  final VerifyEmployeeEmailUseCase _verify;

  VerifyEmployeeEmailController({
    required RequestEmployeeVerificationCodeUseCase
        requestVerificationCodeUseCase,
    required VerifyEmployeeEmailUseCase verifyEmployeeEmailUseCase,
    String? employeeId,
    String? email,
    String? employeeName,
  })  : _requestCode = requestVerificationCodeUseCase,
        _verify = verifyEmployeeEmailUseCase,
        employeeId = employeeId ??
            EmployeeNavigation.argument(EmployeeNavigation.employeeIdKey),
        email = email ?? EmployeeNavigation.argument(EmployeeNavigation.emailKey),
        employeeName = employeeName ??
            EmployeeNavigation.argument(EmployeeNavigation.nameKey);

  final String employeeId;
  final String email;
  final String employeeName;

  final codeController = TextEditingController();

  final isSending = false.obs;
  final isVerifying = false.obs;
  final errorMessage = RxnString();

  /// Vigencia del código enviado (inactiva = sin código vigente).
  late final expiry = CodeCountdown(
    onExpired: () => errorMessage.value = 'El código venció. Pide uno nuevo.',
  );

  /// Espera hasta poder reenviar (inactiva = se puede).
  final resend = CodeCountdown(lifetime: resendDelay);

  bool get canResend => !resend.isActive && !isSending.value;
  bool get isBusy => isSending.value || isVerifying.value;

  @override
  void onInit() {
    super.onInit();
    if (employeeId.isEmpty || email.isEmpty) {
      errorMessage.value = 'Faltan los datos del profesional a verificar.';
      return;
    }
    requestCode();
  }

  @override
  void onClose() {
    expiry.dispose();
    resend.dispose();
    codeController.dispose();
    super.onClose();
  }

  /// Envía (o reenvía) el código al email del empleado.
  Future<void> requestCode() async {
    if (isSending.value || employeeId.isEmpty) return;
    isSending.value = true;
    errorMessage.value = null;
    final result = await _requestCode(email);
    if (isClosed) return;
    isSending.value = false;
    result.fold((failure) {
      errorMessage.value = 'No se pudo enviar el código: '
          '${EmployeeFeedback.messageFor(failure)}';
    }, (_) {
      expiry.start();
      resend.start();
      AppSnackbar.info('Enviamos un código de 6 dígitos a $email',
          title: 'Código enviado');
    });
  }

  /// Verifica el código. `true` si se verificó (y la pantalla se cerró).
  Future<bool> verify() async {
    if (isBusy || employeeId.isEmpty) return false;
    isVerifying.value = true;
    errorMessage.value = null;
    final result = await _verify(VerifyEmployeeEmailParams(
        employeeId: employeeId, code: codeController.text));
    if (isClosed) return false;
    isVerifying.value = false;
    return result.fold((failure) {
      errorMessage.value = EmployeeFeedback.messageFor(failure);
      return false;
    }, (_) {
      expiry.stop();
      resend.stop();
      Get.back(result: true);
      return true;
    });
  }

  /// Sale sin verificar: el empleado queda pendiente de verificación.
  void cancel() => Get.back(result: false);
}
