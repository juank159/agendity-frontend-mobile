import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_notice_controller.dart';

/// "Verifica tu email" en el menú lateral mientras el Owner no lo haya
/// verificado. Toca → pantalla de verificación (pide el código). Sin su
/// controller registrado (fuera de la home) no muestra nada.
class EmailVerificationNotice extends StatelessWidget {
  const EmailVerificationNotice({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<EmailVerificationNoticeController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<EmailVerificationNoticeController>();
    final colors = context.tokens.warning;
    return Obx(() {
      final email = controller.pendingEmail.value;
      if (email == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Material(
          color: colors.container,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            key: const Key('verify-email-notice'),
            leading: Icon(Icons.mark_email_unread_outlined, color: colors.color),
            title: Text('Verifica tu email',
                style: TextStyle(
                    color: colors.onContainer, fontWeight: FontWeight.bold)),
            subtitle: Text('Te enviaremos un código a $email',
                style: TextStyle(color: colors.onContainer)),
            trailing: Icon(Icons.chevron_right, color: colors.onContainer),
            onTap: () {
              Navigator.of(context).maybePop();
              controller.openVerification();
            },
          ),
        ),
      );
    });
  }
}
