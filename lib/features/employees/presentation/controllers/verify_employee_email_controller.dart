import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/employees/domain/usecases/request_employee_verification_code_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/verify_employee_email_usecase.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'employee_feedback.dart';
import 'employee_navigation.dart';

/// Verificación del email de un empleado (`/verify-employee-email`). Envía
/// el código al abrirse; al verificarlo el backend lo **activa** y la
/// pantalla vuelve con `result: true` a quien la abrió (alta o lista).
/// Cancelar vuelve con `false`: el empleado queda pendiente de verificación.
class VerifyEmployeeEmailController extends GetxController {
  /// Vigencia del código en el backend.
  static const codeLifetime = Duration(minutes: 10);

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

  /// Segundos hasta que vence el código enviado (0 = sin código vigente).
  final expiresIn = 0.obs;

  /// Segundos hasta poder reenviar (0 = se puede).
  final resendIn = 0.obs;

  Timer? _ticker;

  bool get canResend => resendIn.value == 0 && !isSending.value;
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
    _ticker?.cancel();
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
      _startCountdowns();
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
      _ticker?.cancel();
      Get.back(result: true);
      return true;
    });
  }

  /// Sale sin verificar: el empleado queda pendiente de verificación.
  void cancel() => Get.back(result: false);

  void _startCountdowns() {
    expiresIn.value = codeLifetime.inSeconds;
    resendIn.value = resendDelay.inSeconds;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (resendIn.value > 0) resendIn.value--;
    if (expiresIn.value > 0) {
      expiresIn.value--;
      if (expiresIn.value == 0) {
        errorMessage.value = 'El código venció. Pide uno nuevo.';
      }
    }
    if (resendIn.value == 0 && expiresIn.value == 0) _ticker?.cancel();
  }

  static String formatSeconds(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
