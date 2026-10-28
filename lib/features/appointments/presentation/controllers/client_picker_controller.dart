import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/clients/domain/usecases/get_clients_page_usecase.dart';

/// Búsqueda de clientes del selector de la cita: paginada en el servidor y
/// con espera al teclear. Efímero: lo crea y lo borra `ClientSearchSelector`.
class ClientPickerController extends GetxController {
  static const pageSize = 20;
  static const searchDelay = Duration(milliseconds: 400);

  final GetClientsPageUseCase _getPage;

  ClientPickerController({required GetClientsPageUseCase getClientsPageUseCase})
      : _getPage = getClientsPageUseCase;

  factory ClientPickerController.fromDependencies() =>
      ClientPickerController(getClientsPageUseCase: Get.find());

  final query = ''.obs;
  final clients = <ClientEntity>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = false.obs;
  final error = Rxn<Failure>();

  int _page = 1;
  int _request = 0;
  Worker? _debounce;

  @override
  void onInit() {
    super.onInit();
    _debounce = debounce<String>(query, (_) => search(), time: searchDelay);
    search();
  }

  /// Primera página con el texto actual.
  Future<void> search() async {
    final request = ++_request;
    isLoading.value = true;
    error.value = null;
    final result = await _getPage(
        ClientsQuery(page: 1, limit: pageSize, search: query.value));
    if (request != _request) return;
    isLoading.value = false;
    result.fold(
      (failure) => error.value = failure,
      (page) {
        _page = 1;
        hasMore.value = page.hasNextPage;
        clients.assignAll(page.items.where((c) => c.id != null));
      },
    );
  }

  /// Siguiente página (al llegar al final de la lista).
  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    final request = _request;
    isLoadingMore.value = true;
    final result = await _getPage(
        ClientsQuery(page: _page + 1, limit: pageSize, search: query.value));
    isLoadingMore.value = false;
    if (request != _request) return;
    result.fold(
      (_) => hasMore.value = false,
      (page) {
        _page = page.page;
        hasMore.value = page.hasNextPage;
        clients.addAll(page.items.where((c) => c.id != null));
      },
    );
  }

  void clear() => query.value = '';

  @override
  void onClose() {
    _debounce?.dispose();
    super.onClose();
  }
}
