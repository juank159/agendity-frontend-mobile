import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/services/notification_service.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_upcoming_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/mark_reminder_sent_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/prepare_reminder_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/manual_reminder_sender.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';
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
  final ManualReminderSender _sender;
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
        _sender = ManualReminderSender(
          prepareReminderUseCase: prepareReminderUseCase,
          markReminderSentUseCase: markReminderSentUseCase,
          openLink: openLink,
        ),
        _notifications = notifications ?? NotificationService.new,
        _now = now ?? BusinessTimeZone.now;

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

  /// Deslizar para refrescar (10.03): sincroniza y vuelve a leer.
  Future<void> refreshFromServer() async {
    if (Get.isRegistered<SyncController>()) {
      await Get.find<SyncController>().syncNow();
    }
    await fetch();
  }

  /// Quita de la lista las citas que ya empezaron (al enviar: la lista pudo
  /// quedarse abierta un rato). Compara instantes: una cita guardada en otra
  /// zona (6.03) conserva la suya.
  void prunePast() {
    final now = BusinessTimeZone.toInstant(_now());
    upcoming.removeWhere((a) => !a.startInstant.isAfter(now));
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
      if (!await _sender.send(appointment)) return;
      upcoming.removeWhere((a) => a.id == appointment.id);
      _cancelLocalNotice(appointment);
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
      // El instante (UTC), no la hora de pared: una cita guardada en otra
      // zona (6.03) avisa a su hora real.
      scheduledTime: appointment.startInstant.subtract(localNoticeLead),
      payload: appointment.id,
    );
  }

  void _cancelLocalNotice(AppointmentEntity appointment) =>
      _notifications().cancelNotification(appointment.id.hashCode);
}
