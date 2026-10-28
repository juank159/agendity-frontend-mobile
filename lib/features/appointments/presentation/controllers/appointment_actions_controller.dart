import 'package:get/get.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/usecases/cancel_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/complete_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointment_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_feedback.dart';
import 'package:login_signup/features/payments/domain/usecases/get_appointment_balance_usecase.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Acciones sobre una cita desde su detalle: cancelar, completar, saldo
/// pendiente para pagar y refresco tras un pago. Cada acción devuelve la cita
/// tal como quedó (para reflejarla en la agenda) o `null` si falló, después
/// de avisar. Lo registra `AppointmentsBinding`.
class AppointmentActionsController extends GetxController {
  final CancelAppointmentUseCase _cancel;
  final CompleteAppointmentUseCase _complete;
  final GetAppointmentUseCase _getAppointment;
  final GetAppointmentBalanceUseCase _getBalance;

  AppointmentActionsController({
    required CancelAppointmentUseCase cancelAppointmentUseCase,
    required CompleteAppointmentUseCase completeAppointmentUseCase,
    required GetAppointmentUseCase getAppointmentUseCase,
    required GetAppointmentBalanceUseCase getAppointmentBalanceUseCase,
  })  : _cancel = cancelAppointmentUseCase,
        _complete = completeAppointmentUseCase,
        _getAppointment = getAppointmentUseCase,
        _getBalance = getAppointmentBalanceUseCase;

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
}
