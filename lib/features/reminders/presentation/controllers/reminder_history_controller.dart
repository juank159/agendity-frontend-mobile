import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_delivery.dart';
import 'package:login_signup/features/reminders/domain/usecases/get_reminder_deliveries_usecase.dart';

/// Historial de envíos de recordatorios (solo Owner), con filtros por
/// estado y cliente, paginado.
class ReminderHistoryController extends GetxController {
  static const pageSize = 50;

  final GetReminderDeliveriesUseCase _getDeliveries;

  ReminderHistoryController(
      {required GetReminderDeliveriesUseCase getReminderDeliveriesUseCase})
      : _getDeliveries = getReminderDeliveriesUseCase;

  final deliveries = <ReminderDelivery>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final error = Rxn<Failure>();
  final statusFilter = Rxn<DeliveryStatus>();
  final clientFilter = Rxn<ClientEntity>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  DeliveriesQuery _query(int offset) => DeliveriesQuery(
      status: statusFilter.value,
      clientId: clientFilter.value?.id,
      limit: pageSize,
      offset: offset);

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    final result = await _getDeliveries(_query(0));
    isLoading.value = false;
    result.fold((failure) => error.value = failure, (page) {
      deliveries.assignAll(page);
      hasMore.value = page.length == pageSize;
    });
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value || isLoading.value) return;
    isLoadingMore.value = true;
    final result = await _getDeliveries(_query(deliveries.length));
    isLoadingMore.value = false;
    result.fold((_) {}, (page) {
      deliveries.addAll(page);
      hasMore.value = page.length == pageSize;
    });
  }

  void setStatus(DeliveryStatus? status) {
    if (statusFilter.value == status) return;
    statusFilter.value = status;
    load();
  }

  void setClient(ClientEntity? client) {
    clientFilter.value = client;
    load();
  }
}
