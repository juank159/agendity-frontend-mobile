import 'package:get/get.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/usecases/delete_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/get_client_by_id_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/update_client_usecase.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'client_access.dart';
import 'client_form_controller.dart';

/// Estado de la carga del cliente a editar.
enum EditClientStatus { loading, ready, error }

/// Edición de un cliente (Owner y Employee) y borrado (solo Owner,
/// `ClientAccess.canDelete`). El id llega en `arguments['clientId']`.
class EditClientController extends ClientFormController {
  final GetClientByIdUseCase _getClient;
  final UpdateClientUseCase _updateClient;
  final DeleteClientUseCase _deleteClient;

  EditClientController({
    required GetClientByIdUseCase getClientByIdUseCase,
    required UpdateClientUseCase updateClientUseCase,
    required DeleteClientUseCase deleteClientUseCase,
    required super.uploadClientImageUseCase,
    super.imagePicker,
    String? clientId,
  })  : _getClient = getClientByIdUseCase,
        _updateClient = updateClientUseCase,
        _deleteClient = deleteClientUseCase,
        clientId = clientId ?? _clientIdFromArguments();

  final String clientId;

  final status = EditClientStatus.loading.obs;
  final loadError = RxnString();
  final client = Rxn<ClientEntity>();
  final isDeleting = false.obs;

  bool get canDelete => ClientAccess.canDelete();

  static String _clientIdFromArguments() {
    final args = Get.arguments;
    return args is Map ? (args['clientId']?.toString() ?? '') : '';
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status.value = EditClientStatus.loading;
    loadError.value = null;
    final result = await _getClient(clientId);
    result.fold(
      (failure) {
        loadError.value = ClientAccess.messageFor(failure);
        status.value = EditClientStatus.error;
      },
      (loaded) {
        client.value = loaded;
        fill(loaded);
        status.value = EditClientStatus.ready;
      },
    );
  }

  @override
  Future<bool> submit() => runSave(
        () async => (await _updateClient(formData(base: client.value)))
            .fold((f) => f, (_) => null),
        successMessage: 'Cliente actualizado',
      );

  /// Pide confirmación y borra. Solo el Owner (el botón no se muestra al
  /// Employee).
  Future<bool> delete() async {
    if (!canDelete || isDeleting.value) return false;
    final confirmed = await AppDialogs.confirm(
      title: 'Eliminar cliente',
      message: '¿Eliminar a ${client.value?.fullName ?? 'este cliente'}? '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return false;

    isDeleting.value = true;
    final result = await _deleteClient(clientId);
    isDeleting.value = false;
    return result.fold(
      (failure) async {
        await ClientAccess.show(failure);
        return false;
      },
      (_) {
        Get.back(result: true);
        AppSnackbar.success('Cliente eliminado');
        return true;
      },
    );
  }
}
