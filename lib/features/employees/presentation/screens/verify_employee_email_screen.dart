import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/employees/presentation/controllers/verify_employee_email_controller.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/code_expiry_notice.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Verificación del email de un empleado con el código de 6 dígitos. Salir
/// pide confirmación: el empleado queda pendiente de verificación.
class VerifyEmployeeEmailScreen extends GetView<VerifyEmployeeEmailController> {
  const VerifyEmployeeEmailScreen({super.key});

  Future<void> _confirmExit() async {
    final leave = await AppDialogs.confirm(
      title: '¿Salir sin verificar?',
      message: 'El profesional quedará pendiente de verificación y no podrá '
          'iniciar sesión ni recibir citas. Puedes verificarlo después desde '
          'la lista.',
      confirmLabel: 'Salir',
      cancelLabel: 'Seguir verificando',
      icon: Icons.mark_email_unread_outlined,
    );
    if (leave) controller.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = context.tokens.info;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verificar email'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Salir sin verificar',
            onPressed: _confirmExit,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.mark_email_unread_outlined,
                size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              controller.employeeName.isEmpty
                  ? 'Verificación del email'
                  : 'Verifica el email de ${controller.employeeName}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: info.container,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Enviamos un código a ${controller.email}. Al verificarlo, '
                'el profesional queda activo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: info.onContainer),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final message = controller.errorMessage.value;
              if (message == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error),
                ),
              );
            }),
            PinCodeTextField(
              appContext: context,
              controller: controller.codeController,
              // Lo libera el controller en onClose, no el campo.
              autoDisposeControllers: false,
              length: 6,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              enableActiveFill: true,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 50,
                fieldWidth: 40,
                activeFillColor: scheme.surface,
                inactiveFillColor: scheme.surface,
                selectedFillColor: scheme.surface,
                activeColor: scheme.primary,
                inactiveColor: scheme.outlineVariant,
                selectedColor: scheme.primary,
              ),
              onChanged: (_) {},
              onCompleted: (_) => controller.verify(),
            ),
            const SizedBox(height: 8),
            Obx(() => controller.expiry.isActive
                ? CodeExpiryNotice(remaining: controller.expiry.formatted)
                : const SizedBox.shrink()),
            const SizedBox(height: 24),
            Obx(() => FilledButton(
                  onPressed: controller.isBusy ? null : controller.verify,
                  child: controller.isVerifying.value
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Verificar email'),
                )),
            const SizedBox(height: 8),
            Obx(() => TextButton.icon(
                  onPressed:
                      controller.canResend ? controller.requestCode : null,
                  icon: const Icon(Icons.refresh),
                  label: Text(controller.resend.isActive
                      ? 'Reenviar en ${controller.resend.formatted}'
                      : 'Reenviar código'),
                )),
          ],
        ),
      ),
    );
  }
}
