import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/services/notification_service.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_upcoming_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/mark_reminder_sent_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/prepare_reminder_usecase.dart';
import 'package:login_signup/shared/utils/external_link.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Recordatorios manuales por WhatsApp (D-05): las próximas citas pendientes
/// o confirmadas sin recordatorio (nunca canceladas) y el envío.
///
/// Enviar = el backend prepara el enlace `wa.me` (teléfono por la cita) →
/// se abre WhatsApp → se marca como enviado. Además programa un aviso local
/// 30 min antes de cada cita de la lista.
class AppointmentReminderController extends GetxController {
  static const localNoticeLead = Duration(minutes: 30);

  final GetUpcomingAppointmentsUseCase _getUpcoming;
  final PrepareReminderUseCase _prepare;
  final MarkReminderSentUseCase _markSent;
  final ExternalLinkOpener _openLink;
  final NotificationService Function() _notifications;
  final DateTime Function() _now;

  AppointmentReminderController({
    required GetUpcomingAppointmentsUseCase getUpcomingAppointmentsUseCase,
    required PrepareReminderUseCase prepareReminderUseCase,
    required MarkReminderSentUseCase markReminderSentUseCase,
    ExternalLinkOpener? openLink,
    NotificationService Function()? notifications,
    DateTime Function()? now,
  })  : _getUpcoming = getUpcomingAppointmentsUseCase,
        _prepare = prepareReminderUseCase,
        _markSent = markReminderSentUseCase,
        _openLink = openLink ?? openExternalLink,
        _notifications = notifications ?? NotificationService.new,
        _now = now ?? DateTime.now;

  final upcoming = <AppointmentEntity>[].obs;
  final isLoading = false.obs;
  final error = Rxn<Failure>();

  /// Cita cuyo recordatorio se está preparando.
  final sendingId = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    error.value = null;
    final result = await _getUpcoming(NoParams());
    isLoading.value = false;
    result.fold(
      (failure) => error.value = failure,
      (appointments) {
        upcoming.assignAll(appointments);
        appointments.forEach(_scheduleLocalNotice);
      },
    );
  }

  /// Quita de la lista las citas que ya empezaron (al enviar: la lista pudo
  /// quedarse abierta un rato).
  void prunePast() {
    final now = _now();
    upcoming.removeWhere((a) => !a.startTime.isAfter(now));
  }

  /// Abre WhatsApp con el recordatorio de [appointment] y lo marca enviado.
  Future<void> send(AppointmentEntity appointment) async {
    if (sendingId.value != null) return;
    prunePast();
    if (!upcoming.any((a) => a.id == appointment.id)) {
      AppSnackbar.info('La cita ya empezó');
      return;
    }
    sendingId.value = appointment.id;
    try {
      final prepared = await _prepare(appointment.id);
      final reminder = prepared.fold((failure) {
        AppSnackbar.error(failure.message,
            title: 'No se pudo preparar el recordatorio');
        return null;
      }, (reminder) => reminder);
      if (reminder == null) return;

      final link = Uri.tryParse(reminder.whatsappUrl);
      if (link == null || !await _openLink(link)) {
        AppSnackbar.error('No se pudo abrir WhatsApp');
        return;
      }

      final marked = await _markSent(appointment.id);
      upcoming.removeWhere((a) => a.id == appointment.id);
      _cancelLocalNotice(appointment);
      marked.fold(
        (_) => AppSnackbar.warning(
            'Se abrió WhatsApp, pero no se pudo registrar el envío'),
        (_) => AppSnackbar.success(
            'Recordatorio para ${appointment.clientName} listo en WhatsApp'),
      );
    } finally {
      sendingId.value = null;
    }
  }

  void _scheduleLocalNotice(AppointmentEntity appointment) {
    final services = appointment.serviceNames.join(', ');
    _notifications().scheduleAppointmentReminder(
      id: appointment.id.hashCode,
      title: 'Cita próxima',
      body: '${appointment.clientName}'
          '${services.isEmpty ? '' : ' · $services'}'
          ' a las ${formatTime(appointment.startTime)}',
      scheduledTime: appointment.startTime.subtract(localNoticeLead),
      payload: appointment.id,
    );
  }

  void _cancelLocalNotice(AppointmentEntity appointment) =>
      _notifications().cancelNotification(appointment.id.hashCode);
}
