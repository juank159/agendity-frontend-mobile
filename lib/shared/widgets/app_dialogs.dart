import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/shared/controller/session_controller.dart';

/// Motivo por el que la suscripción bloquea una acción.
enum SubscriptionBlockReason { trialEnded, inactive }

/// Diálogos comunes de la app. Todos usan el tema (modo oscuro incluido) y
/// se cierran con el `Navigator` del propio diálogo: `Get.back()` cerraría
/// antes un snackbar abierto que el diálogo.
abstract final class AppDialogs {
  /// Pide confirmación. Devuelve `true` solo si se pulsa [confirmLabel].
  /// Con [destructive] el botón de confirmar usa el color de error.
  static Future<bool> confirm({
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool destructive = false,
    IconData? icon,
  }) async {
    final result = await Get.dialog<bool>(
      AppDialog(
        tone: destructive ? AppTone.error : AppTone.info,
        icon: icon ??
            (destructive ? Icons.delete_outline : Icons.help_outline_rounded),
        title: title,
        message: message,
        primaryLabel: confirmLabel,
        primaryResult: true,
        destructive: destructive,
        secondaryLabel: cancelLabel,
        secondaryResult: false,
      ),
      barrierDismissible: true,
    );
    return result ?? false;
  }

  /// Error que el usuario debe leer antes de seguir (lo pasajero va en
  /// `AppSnackbar.error`).
  static Future<void> error({
    required String message,
    String title = 'Ocurrió un error',
    String actionLabel = 'Entendido',
  }) {
    return info(
      title: title,
      message: message,
      tone: AppTone.error,
      icon: Icons.error_outline,
      actionLabel: actionLabel,
    );
  }

  /// Información con un solo botón.
  static Future<void> info({
    required String title,
    required String message,
    String? detail,
    AppTone tone = AppTone.info,
    IconData icon = Icons.info_outline,
    String actionLabel = 'Entendido',
    bool barrierDismissible = true,
  }) async {
    await Get.dialog<void>(
      AppDialog(
        tone: tone,
        icon: icon,
        title: title,
        message: message,
        detail: detail,
        primaryLabel: actionLabel,
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  /// **Único** diálogo de suscripción: fin del trial o suscripción inactiva.
  /// El Owner ve "Ver planes" (ruta de planes); el Employee no puede comprar
  /// planes (la ruta es solo del Owner) y se le pide avisar al dueño.
  /// [message] sustituye al texto por defecto del [reason].
  static Future<void> subscriptionRequired({
    SubscriptionBlockReason reason = SubscriptionBlockReason.trialEnded,
    String? message,
    bool? canManagePlans,
  }) async {
    final isOwner = canManagePlans ?? _currentUserIsOwner();
    final trialEnded = reason == SubscriptionBlockReason.trialEnded;
    final title = trialEnded ? 'Plan de prueba finalizado' : 'Suscripción inactiva';
    final body = (message != null && message.trim().isNotEmpty)
        ? message.trim()
        : trialEnded
            ? 'Has alcanzado el límite de citas de tu plan de prueba. '
                'Adquiere un plan para seguir gestionando tus citas.'
            : 'Tu suscripción no está activa. '
                'Renueva tu plan para seguir gestionando tus citas.';

    final goToPlans = await Get.dialog<bool>(
      AppDialog(
        tone: trialEnded ? AppTone.warning : AppTone.error,
        icon: trialEnded
            ? Icons.workspace_premium_outlined
            : Icons.assignment_late_outlined,
        title: title,
        message: body,
        detail: isOwner
            ? null
            : 'Pide al administrador del negocio que adquiera un plan.',
        primaryLabel: isOwner ? 'Ver planes disponibles' : 'Entendido',
        primaryResult: isOwner,
        secondaryLabel: isOwner ? 'Ahora no' : null,
        secondaryResult: false,
      ),
      barrierDismissible: true,
    );

    if (goToPlans == true) {
      await Get.toNamed(GetRoutes.subscriptionPlans);
    }
  }

  static bool _currentUserIsOwner() {
    if (!Get.isRegistered<SessionController>()) return true;
    return Get.find<SessionController>().isOwner;
  }
}

/// Cuerpo común de los diálogos de [AppDialogs]. Público para reutilizarlo
/// en diálogos de feature con el mismo aspecto.
class AppDialog extends StatelessWidget {
  final AppTone tone;
  final IconData icon;
  final String title;
  final String message;
  final String? detail;
  final String primaryLabel;
  final Object? primaryResult;
  final bool destructive;
  final String? secondaryLabel;
  final Object? secondaryResult;

  const AppDialog({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.detail,
    this.primaryResult,
    this.destructive = false,
    this.secondaryLabel,
    this.secondaryResult,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.tokens.tone(tone);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.container,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.color, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
              ),
              if (detail != null) ...[
                const SizedBox(height: 8),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                        )
                      : null,
                  onPressed: () => Navigator.of(context).pop(primaryResult),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(primaryLabel),
                  ),
                ),
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(secondaryResult),
                  child: Text(secondaryLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
