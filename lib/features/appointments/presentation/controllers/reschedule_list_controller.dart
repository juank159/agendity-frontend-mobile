import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_to_reschedule_usecase.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';

/// "Citas por mover" (10.03): las guardadas con conflicto al sincronizar.
class RescheduleListController extends GetxController {
  final GetAppointmentsToRescheduleUseCase _getToReschedule;

  RescheduleListController(
      {required GetAppointmentsToRescheduleUseCase
          getAppointmentsToRescheduleUseCase})
      : _getToReschedule = getAppointmentsToRescheduleUseCase;

  final appointments = <AppointmentEntity>[].obs;
  final isLoading = false.obs;
  final error = Rxn<Failure>();
  Worker? _worker;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<SyncController>()) {
      _worker =
          Get.find<SyncController>().onDataChanged(() => load(silent: true));
    }
    load();
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }

  /// [silent] (recarga tras una sincronización, 7.05d): sin indicador de
  /// carga y, si falla con datos ya cargados, se conservan sin mostrar el
  /// error.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading.value = true;
      error.value = null;
    }
    final result = await _getToReschedule(NoParams());
    if (!silent) isLoading.value = false;
    result.fold((failure) {
      if (!silent || appointments.isEmpty) error.value = failure;
    }, (loaded) {
      error.value = null;
      appointments.assignAll(loaded);
    });
  }

  /// Deslizar para refrescar: sincroniza y vuelve a leer.
  Future<void> refreshFromServer() async {
    if (Get.isRegistered<SyncController>()) {
      await Get.find<SyncController>().syncNow();
    }
    await load();
  }
}
