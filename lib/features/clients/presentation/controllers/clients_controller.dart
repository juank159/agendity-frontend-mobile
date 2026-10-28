import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/client_import_result.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/clients/domain/usecases/get_clients_page_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/import_clients_usecase.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'client_access.dart';

/// Lee los contactos del dispositivo como clientes sin `id`. `null` si el
/// usuario no dio permiso.
typedef DeviceContactsReader = Future<List<ClientEntity>?> Function();

/// Orden de la lista que ofrece la UI.
enum ClientSortOption {
  newest(
      'Más recientes primero', ClientSortField.createdAt, SortDirection.desc),
  oldest('Más antiguos primero', ClientSortField.createdAt, SortDirection.asc),
  nameAsc('Nombre (A-Z)', ClientSortField.name, SortDirection.asc),
  nameDesc('Nombre (Z-A)', ClientSortField.name, SortDirection.desc);

  final String label;
  final ClientSortField field;
  final SortDirection direction;

  const ClientSortOption(this.label, this.field, this.direction);
}

/// Lista paginada de clientes del negocio (Owner y Employee) con búsqueda,
/// filtros e importación de contactos.
class ClientsController extends GetxController {
  static const pageSize = 20;
  static const defaultSort = ClientSortOption.nameAsc;

  final GetClientsPageUseCase _getPage;
  final ImportClientsUseCase _importClients;
  final DeviceContactsReader _readContacts;

  ClientsController({
    required GetClientsPageUseCase getClientsPageUseCase,
    required ImportClientsUseCase importClientsUseCase,
    required DeviceContactsReader readDeviceContacts,
  })  : _getPage = getClientsPageUseCase,
        _importClients = importClientsUseCase,
        _readContacts = readDeviceContacts;

  final clients = <ClientEntity>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();

  final totalRecords = 0.obs;
  final hasNextPage = false.obs;
  int _page = 1;
  int _request = 0;

  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final statusFilter = ClientStatusFilter.all.obs;
  final sourceFilter = ClientSourceFilter.all.obs;
  final sort = defaultSort.obs;

  final isImporting = false.obs;

  final scrollController = ScrollController();

  bool get hasActiveFilters =>
      searchQuery.value.trim().isNotEmpty ||
      statusFilter.value != ClientStatusFilter.all ||
      sourceFilter.value != ClientSourceFilter.all ||
      sort.value != defaultSort;

  @override
  void onInit() {
    super.onInit();
    debounce(searchQuery, (_) => loadClients(),
        time: const Duration(milliseconds: 500));
    scrollController.addListener(_onScroll);
    loadClients();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void _onScroll() {
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) loadMoreClients();
  }

  ClientsQuery _query(int page) => ClientsQuery(
        page: page,
        limit: pageSize,
        search: searchQuery.value,
        sortBy: sort.value.field,
        direction: sort.value.direction,
        status: statusFilter.value,
        source: sourceFilter.value,
      );

  /// Primera página con los filtros actuales. Si falla con clientes ya
  /// cargados, se conservan y se avisa.
  Future<void> loadClients() async {
    final request = ++_request;
    isLoading.value = true;
    error.value = null;
    final result = await _getPage(_query(1));
    if (request != _request) return;
    isLoading.value = false;
    result.fold(
      (failure) {
        final message = ClientAccess.messageFor(failure);
        if (clients.isEmpty) {
          error.value = message;
        } else {
          AppSnackbar.error(message);
        }
      },
      (page) {
        _page = 1;
        clients.assignAll(page.items);
        totalRecords.value = page.total;
        hasNextPage.value = page.hasNextPage;
      },
    );
  }

  /// Siguiente página (scroll infinito).
  Future<void> loadMoreClients() async {
    if (!hasNextPage.value || isLoadingMore.value || isLoading.value) return;
    final request = _request;
    isLoadingMore.value = true;
    final result = await _getPage(_query(_page + 1));
    isLoadingMore.value = false;
    if (request != _request) return;
    result.fold(
      (failure) => AppSnackbar.error(ClientAccess.messageFor(failure)),
      (page) {
        _page = page.page;
        clients.addAll(page.items);
        totalRecords.value = page.total;
        hasNextPage.value = page.hasNextPage;
      },
    );
  }

  void applyStatusFilter(ClientStatusFilter value) {
    if (statusFilter.value == value) return;
    statusFilter.value = value;
    loadClients();
  }

  void applySourceFilter(ClientSourceFilter value) {
    if (sourceFilter.value == value) return;
    sourceFilter.value = value;
    loadClients();
  }

  void applySort(ClientSortOption value) {
    if (sort.value == value) return;
    sort.value = value;
    loadClients();
  }

  /// Quita búsqueda y filtros. La búsqueda recarga por su `debounce`; los
  /// filtros, aquí.
  void clearAllFilters() {
    searchController.clear();
    searchQuery.value = '';
    statusFilter.value = ClientStatusFilter.all;
    sourceFilter.value = ClientSourceFilter.all;
    sort.value = defaultSort;
    loadClients();
  }

  Future<void> openNewClient() => _openForm(GetRoutes.addClient);

  Future<void> openClient(ClientEntity client) =>
      _openForm(GetRoutes.editClient, arguments: {'clientId': client.id});

  Future<void> _openForm(String route, {Object? arguments}) async {
    final changed = await Get.toNamed(route, arguments: arguments);
    if (changed == true && !isClosed) await loadClients();
  }

  /// Lee los contactos del dispositivo y los importa. Devuelve el resumen, o
  /// `null` si no se importó nada (ya avisado).
  Future<ClientImportResult?> importContacts() async {
    if (isImporting.value) return null;
    isImporting.value = true;
    try {
      final List<ClientEntity>? contacts;
      try {
        contacts = await _readContacts();
      } catch (_) {
        AppSnackbar.error('No se pudieron leer los contactos del teléfono.');
        return null;
      }
      if (contacts == null) {
        AppSnackbar.warning(
            'Permite el acceso a tus contactos para importarlos.',
            title: 'Sin permiso');
        return null;
      }
      final result = await _importClients(contacts);
      return await result.fold(
        (failure) async {
          await ClientAccess.show(failure);
          return null;
        },
        (summary) async {
          if (summary.imported > 0) await loadClients();
          return summary;
        },
      );
    } finally {
      isImporting.value = false;
    }
  }
}
