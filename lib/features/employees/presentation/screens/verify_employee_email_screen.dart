import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/employees/presentation/controllers/verify_employee_email_controller.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_code_field.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:login_signup/shared/widgets/code_expiry_notice.dart';

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
      icon: Icons.mark_email_unread_rounded,
    );
    if (leave) controller.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verificar email'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Salir sin verificar',
            onPressed: _confirmExit,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          children: [
            AppCard(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: tokens.primaryGradient,
                        border: Border.all(color: tokens.innerBorder),
                        boxShadow: tokens.elevation2(tint: tokens.gradientEnd),
                      ),
                      child: Icon(Icons.mark_email_unread_rounded,
                          size: 36, color: tokens.onGradient),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.employeeName.isEmpty
                        ? 'Verificación del email'
                        : 'Verifica el email de ${controller.employeeName}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700, color: scheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  AppNote(
                    'Enviamos un código a ${controller.email}. Al '
                    'verificarlo, el profesional queda activo.',
                    tone: AppTone.info,
                    icon: Icons.mail_rounded,
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final message = controller.errorMessage.value;
                    if (message == null) return const SizedBox.shrink();
                    return AppNote(
                      message,
                      tone: AppTone.error,
                      icon: Icons.error_rounded,
                      margin: const EdgeInsets.only(bottom: 12),
                    );
                  }),
                  AppCodeField(
                    controller: controller.codeController,
                    onCompleted: (_) => controller.verify(),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => controller.expiry.isActive
                      ? CodeExpiryNotice(remaining: controller.expiry.formatted)
                      : const SizedBox.shrink()),
                  const SizedBox(height: 20),
                  Obx(() => AppGradientButton(
                        label: 'Verificar email',
                        icon: Icons.verified_rounded,
                        expand: true,
                        loading: controller.isVerifying.value,
                        onPressed: controller.isBusy ? null : controller.verify,
                      )),
                  const SizedBox(height: 8),
                  Obx(() => TextButton.icon(
                        onPressed: controller.canResend
                            ? controller.requestCode
                            : null,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(controller.resend.isActive
                            ? 'Reenviar en ${controller.resend.formatted}'
                            : 'Reenviar código'),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
