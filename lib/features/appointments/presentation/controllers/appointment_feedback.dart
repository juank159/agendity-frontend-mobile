import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_conflict_ui.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Quién puede hacer qué con las citas (reglas del backend, leídas de la
/// sesión de la UI; el backend las vuelve a comprobar).
abstract final class AppointmentAccess {
  static SessionController? get _session =>
      Get.isRegistered<SessionController>() ? Get.find<SessionController>() : null;

  /// Owner: editar o mover una cita (`PATCH /appointments/:id`).
  static bool canEdit() => _session?.isOwner ?? false;

  /// Owner: registrar pagos (`POST /payments`).
  static bool canPay() => _session?.isOwner ?? false;

  /// El Employee solo agenda para sí: el profesional viene fijado.
  static bool professionalIsFixed() => _session?.isOnlyEmployee ?? false;
}

/// Avisos de la feature según el tipo de failure (es decir, por `code`),
/// nunca por el texto.
abstract final class AppointmentFeedback {
  static const slotUnavailableTitle = 'Horario no disponible';
  static const paidTitle = 'La cita tiene pagos';
  static const paidMessage =
      'Reembolsa los pagos antes de cancelar la cita.';

  /// Sin motivo conocido (backend anterior a 13.04 o sin `details`).
  static const slotUnavailableMessage =
      'El profesional ya no está libre a esa hora.';

  /// Crear o editar una cita (también mover: "Por mover" y el detalle usan
  /// el mismo formulario). [professionalName] = el profesional elegido, para
  /// el motivo de `SlotProblemText` ("Ana no trabaja a esa hora…", 13.06).
  static void showSaveFailure(Failure failure, {String? professionalName}) {
    final reason =
        SlotProblemText.of(failure, professionalName: professionalName);
    switch (failure) {
      case TrialLimitReachedFailure():
        AppDialogs.subscriptionRequired(
            reason: SubscriptionBlockReason.trialEnded);
      case SubscriptionInactiveFailure():
        AppDialogs.subscriptionRequired(
            reason: SubscriptionBlockReason.inactive);
      case SlotUnavailableFailure():
        AppDialogs.info(
          title: slotUnavailableTitle,
          // Sin motivo, el texto del servidor repite el título.
          message: reason ??
              (failure.message == slotUnavailableTitle
                  ? slotUnavailableMessage
                  : failure.message),
          detail: 'Elige otra de las horas libres.',
          tone: AppTone.warning,
          icon: Icons.schedule_rounded,
        );
      case AppointmentInPastFailure():
        AppSnackbar.warning(failure.message, title: 'Hora pasada');
      case ProfessionalInactiveFailure():
        AppDialogs.error(
            title: 'Profesional no disponible', message: failure.message);
      case OutsideBusinessHoursFailure():
        AppDialogs.info(
          title: 'Fuera del horario del negocio',
          message: reason ?? failure.message,
          detail: 'Elige una hora dentro del horario de apertura o cámbialo '
              'en "Mi negocio".',
          tone: AppTone.warning,
          icon: Icons.storefront_rounded,
        );
      case ServiceInactiveFailure():
        AppDialogs.info(
          title: 'Servicio desactivado',
          message: failure.message,
          detail: 'Quítalo de la cita o actívalo de nuevo en Servicios.',
          tone: AppTone.warning,
          icon: Icons.block_rounded,
        );
      case ServiceNotOfferedFailure():
        AppDialogs.info(
          title: 'Servicio no disponible',
          message: failure.message,
          detail: 'Quita ese servicio o elige otro profesional.',
          tone: AppTone.warning,
          icon: Icons.content_cut_rounded,
        );
      case ValidationFailure():
        AppSnackbar.warning(failure.message);
      default:
        showActionFailure(failure, title: 'No se guardó la cita');
    }
  }

  /// Cancelar, completar o leer una cita.
  static void showActionFailure(Failure failure,
      {String title = 'No se pudo completar la acción'}) {
    switch (failure) {
      case AppointmentPaidFailure():
        AppDialogs.info(
          title: paidTitle,
          message: paidMessage,
          tone: AppTone.warning,
          icon: Icons.payments_rounded,
        );
      case InvalidStateTransitionFailure():
        AppDialogs.error(title: 'La cita cambió', message: failure.message);
      case AppointmentNotStartedFailure():
        AppSnackbar.warning(failure.message, title: 'Aún no empieza');
      case ValidationFailure():
        AppSnackbar.warning(failure.message);
      default:
        AppSnackbar.error(failure.message, title: title);
    }
  }
}
