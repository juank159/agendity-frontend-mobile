import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';

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
            (destructive ? Icons.delete_outline_rounded : Icons.help_outline_rounded),
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

  /// Fallo temporal que se arregla repitiendo (p. ej. `EmailDeliveryFailure`:
  /// el correo con el código no salió). `true` si se pulsa "Reintentar".
  static Future<bool> retry({
    required String title,
    required String message,
  }) =>
      confirm(
        title: title,
        message: message,
        confirmLabel: 'Reintentar',
        cancelLabel: 'Ahora no',
        icon: Icons.refresh_rounded,
      );

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
      icon: Icons.error_outline_rounded,
      actionLabel: actionLabel,
    );
  }

  /// Información con un solo botón.
  static Future<void> info({
    required String title,
    required String message,
    String? detail,
    AppTone tone = AppTone.info,
    IconData icon = Icons.info_outline_rounded,
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
            ? Icons.workspace_premium_rounded
            : Icons.assignment_late_rounded,
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
/// en diálogos de feature con el mismo aspecto (guía §3, 12.07): ícono del
/// tono en un círculo con halo, título w700, mensaje, detalle opcional y
/// botones al pie a todo el ancho.
///
/// El botón principal es `AppGradientButton` (degradado de la paleta); con
/// [destructive], un `FilledButton` del color de error. Los dos son
/// `FilledButton` para los tests (`find.widgetWithText(FilledButton, …)`).
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.tokens.tone(tone);
    final extra = detail;
    final secondary = secondaryLabel;

    void close(Object? result) => Navigator.of(context).pop(result);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.container,
                    border: Border.all(
                        color: colors.color.withValues(alpha: 0.28), width: 6),
                    boxShadow: context.tokens.elevation1(tint: colors.color),
                  ),
                  child: Icon(icon, color: colors.color, size: 34),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700, color: scheme.onSurface),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
              ),
              if (extra != null) ...[
                const SizedBox(height: 8),
                Text(
                  extra,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                ),
              ],
              const SizedBox(height: 24),
              if (destructive)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => close(primaryResult),
                  child: Text(primaryLabel),
                )
              else
                AppGradientButton(
                  label: primaryLabel,
                  expand: true,
                  onPressed: () => close(primaryResult),
                ),
              if (secondary != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  onPressed: () => close(secondaryResult),
                  child: Text(secondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
