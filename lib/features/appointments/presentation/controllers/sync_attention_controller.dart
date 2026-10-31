import 'package:get/get.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_to_reschedule_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_payments_in_review_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';

/// Contadores de lo que dejó la sincronización para resolver a mano (10.03):
/// citas por mover (Owner y empleada) y pagos por revisar (solo Owner). Los
/// pinta el aviso de la agenda y se recalculan al terminar cada
/// sincronización.
class SyncAttentionController extends GetxController {
  final GetAppointmentsToRescheduleUseCase _toReschedule;
  final GetPaymentsInReviewUseCase? _inReview;
  final SessionController _session;

  SyncAttentionController({
    required GetAppointmentsToRescheduleUseCase getAppointmentsToRescheduleUseCase,
    GetPaymentsInReviewUseCase? getPaymentsInReviewUseCase,
    required SessionController session,
  })  : _toReschedule = getAppointmentsToRescheduleUseCase,
        _inReview = getPaymentsInReviewUseCase,
        _session = session;

  final toRescheduleCount = 0.obs;
  final inReviewCount = 0.obs;
  Worker? _worker;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<SyncController>()) {
      _worker = Get.find<SyncController>().onDataChanged(load);
    }
    load();
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }

  Future<void> load() async {
    final reschedule = await _toReschedule(NoParams());
    toRescheduleCount.value = reschedule.fold((_) => 0, (list) => list.length);
    final review = _inReview;
    if (review == null || !_session.isOwner) {
      inReviewCount.value = 0;
      return;
    }
    final payments = await review(NoParams());
    inReviewCount.value = payments.fold((_) => 0, (list) => list.length);
  }
}
