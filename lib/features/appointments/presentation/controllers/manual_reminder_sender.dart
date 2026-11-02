import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/usecases/mark_reminder_sent_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/prepare_reminder_usecase.dart';
import 'package:login_signup/shared/utils/external_link.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Envío del recordatorio **manual** por WhatsApp de una cita (D-05):
/// el backend prepara el enlace `wa.me` → se abre WhatsApp → se marca como
/// enviado. Avisa con `AppSnackbar` en cada caso.
///
/// Único flujo de envío: lo usan la lista de recordatorios
/// (`AppointmentReminderController`) y el detalle de la cita
/// (`AppointmentActionsController`, 12.07).
class ManualReminderSender {
  final PrepareReminderUseCase _prepare;
  final MarkReminderSentUseCase _markSent;
  final ExternalLinkOpener _openLink;

  ManualReminderSender({
    required PrepareReminderUseCase prepareReminderUseCase,
    required MarkReminderSentUseCase markReminderSentUseCase,
    ExternalLinkOpener? openLink,
  })  : _prepare = prepareReminderUseCase,
        _markSent = markReminderSentUseCase,
        _openLink = openLink ?? openExternalLink;

  /// `true` si WhatsApp se abrió con el recordatorio (aunque no se haya
  /// podido registrar el envío: el mensaje ya está en manos del usuario).
  Future<bool> send(AppointmentEntity appointment) async {
    final prepared = await _prepare(appointment.id);
    final reminder = prepared.fold((failure) {
      AppSnackbar.error(failure.message,
          title: 'No se pudo preparar el recordatorio');
      return null;
    }, (reminder) => reminder);
    if (reminder == null) return false;

    final link = Uri.tryParse(reminder.whatsappUrl);
    if (link == null || !await _openLink(link)) {
      AppSnackbar.error('No se pudo abrir WhatsApp');
      return false;
    }

    final marked = await _markSent(appointment.id);
    marked.fold(
      (_) => AppSnackbar.warning(
          'Se abrió WhatsApp, pero no se pudo registrar el envío'),
      (_) => AppSnackbar.success(
          'Recordatorio para ${appointment.clientName} listo en WhatsApp'),
    );
    return true;
  }
}
