import 'package:get/get.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/usecases/cancel_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/complete_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/mark_reminder_sent_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/prepare_reminder_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_feedback.dart';
import 'package:login_signup/features/appointments/presentation/controllers/manual_reminder_sender.dart';
import 'package:login_signup/features/payments/domain/entities/appointment_balance.dart';
import 'package:login_signup/features/payments/domain/usecases/get_appointment_balance_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_payments_in_review_usecase.dart';
import 'package:login_signup/shared/utils/external_link.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Acciones sobre una cita desde su detalle: cancelar, completar, saldo
/// pendiente para pagar, resumen de pagos (12.07), recordatorio por
/// WhatsApp (12.07) y refresco tras un pago. Cada acción devuelve la cita
/// tal como quedó (para reflejarla en la agenda) o `null` si falló, después
/// de avisar. Lo registra `AppointmentsBinding`.
class AppointmentActionsController extends GetxController {
  final CancelAppointmentUseCase _cancel;
  final CompleteAppointmentUseCase _complete;
  final GetAppointmentUseCase _getAppointment;
  final GetAppointmentBalanceUseCase _getBalance;
  final GetPaymentsInReviewUseCase? _getInReview;
  final ManualReminderSender? _reminders;

  AppointmentActionsController({
    GetPaymentsInReviewUseCase? getPaymentsInReviewUseCase,
    PrepareReminderUseCase? prepareReminderUseCase,
    MarkReminderSentUseCase? markReminderSentUseCase,
    ExternalLinkOpener? openLink,
    required CancelAppointmentUseCase cancelAppointmentUseCase,
    required CompleteAppointmentUseCase completeAppointmentUseCase,
    required GetAppointmentUseCase getAppointmentUseCase,
    required GetAppointmentBalanceUseCase getAppointmentBalanceUseCase,
  })  : _cancel = cancelAppointmentUseCase,
        _complete = completeAppointmentUseCase,
        _getAppointment = getAppointmentUseCase,
        _getBalance = getAppointmentBalanceUseCase,
        _getInReview = getPaymentsInReviewUseCase,
        _reminders = prepareReminderUseCase == null ||
                markReminderSentUseCase == null
            ? null
            : ManualReminderSender(
                prepareReminderUseCase: prepareReminderUseCase,
                markReminderSentUseCase: markReminderSentUseCase,
                openLink: openLink,
              );

  /// Pagos en revisión de [appointmentId] (10.03, solo Owner; sin el use
  /// case o con error, ninguno).
  Future<int> paymentsInReviewOf(String appointmentId) async {
    final useCase = _getInReview;
    if (useCase == null || !AppointmentAccess.canPay()) return 0;
    final result = await useCase(NoParams());
    return result.fold(
        (_) => 0,
        (items) =>
            items.where((i) => i.payment.appointmentId == appointmentId).length);
  }

  /// Id de la cita con una acción en curso (para deshabilitar botones).
  final busyId = RxnString();

  bool isBusy(String id) => busyId.value == id;

  Future<AppointmentEntity?> cancel(AppointmentEntity appointment,
      {String? reason}) async {
    busyId.value = appointment.id;
    final result = await _cancel(CancelAppointmentParams(
        appointmentId: appointment.id, reason: reason));
    busyId.value = null;
    return result.fold(
      (failure) {
        AppointmentFeedback.showActionFailure(failure,
            title: 'No se canceló la cita');
        return null;
      },
      (cancelled) {
        AppSnackbar.success('Cita cancelada');
        return cancelled;
      },
    );
  }

  Future<AppointmentEntity?> complete(AppointmentEntity appointment) async {
    busyId.value = appointment.id;
    final result = await _complete(appointment.id);
    busyId.value = null;
    return result.fold(
      (failure) {
        AppointmentFeedback.showActionFailure(failure,
            title: 'No se completó la cita');
        return null;
      },
      (completed) {
        AppSnackbar.success(completed.isFullyPaid
            ? 'Cita completada'
            : 'Cita completada; el pago queda pendiente');
        return completed;
      },
    );
  }

  /// Lo que falta por pagar: sin consultar si la cita no tiene anticipos;
  /// con un anticipo (`PARTIAL`), a partir de sus pagos. `null` si no se
  /// pudo saber (ya avisado).
  Future<double?> balanceDue(AppointmentEntity appointment) async {
    final known = appointment.knownBalanceDue;
    if (known != null) return known;
    busyId.value = appointment.id;
    final result = await _getBalance(AppointmentBalanceParams(
        appointmentId: appointment.id, total: appointment.totalPrice));
    busyId.value = null;
    return result.fold(
      (failure) {
        AppSnackbar.error(failure.message,
            title: 'No se pudo consultar el saldo');
        return null;
      },
      (balance) => balance.outstanding,
    );
  }

  /// La cita tal como está ahora en el backend (tras un pago, que cambia su
  /// estado de pago y la confirma). `null` si no se pudo leer.
  Future<AppointmentEntity?> fetchLatest(String id) async {
    final result = await _getAppointment(id);
    return result.fold((_) => null, (fresh) => fresh);
  }

  /// Resumen de pagos para el detalle (12.07, solo Owner: el backend no da
  /// los pagos al Employee): lo pagado, el saldo y el historial. Sin pagos
  /// (`Sin pagar`) no se consulta. `null` si no aplica o no se pudo leer
  /// (el detalle simplemente no muestra la sección).
  Future<AppointmentBalance?> paymentSummaryOf(
      AppointmentEntity appointment) async {
    if (!AppointmentAccess.canPay()) return null;
    if (appointment.paymentStatus == AppointmentPaymentStatus.PENDING) {
      return AppointmentBalance(total: appointment.totalPrice, paid: 0);
    }
    final result = await _getBalance(AppointmentBalanceParams(
        appointmentId: appointment.id, total: appointment.totalPrice));
    return result.fold((_) => null, (balance) => balance);
  }

  /// Se ofrece el recordatorio manual de [appointment] en [now] (hora del
  /// negocio): hay con qué enviarlo y a la cita le falta.
  bool canSendReminder(AppointmentEntity appointment, DateTime now) =>
      _reminders != null && appointment.needsReminderAt(now);

  /// Abre WhatsApp con el recordatorio. `true` si se abrió (el detalle
  /// vuelve a leer la cita para reflejar el envío).
  Future<bool> sendReminder(AppointmentEntity appointment) async {
    final sender = _reminders;
    if (sender == null || busyId.value != null) return false;
    busyId.value = appointment.id;
    try {
      return await sender.send(appointment);
    } finally {
      busyId.value = null;
    }
  }
}
