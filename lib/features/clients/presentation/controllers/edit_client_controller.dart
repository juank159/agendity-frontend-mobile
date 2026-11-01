import 'package:get/get.dart';
import 'package:login_signup/core/config/env_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/public_url.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/usecases/delete_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/get_client_by_id_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/request_consent_link_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/update_client_usecase.dart';
import 'package:login_signup/features/settings/domain/usecases/get_business_settings_usecase.dart';
import 'package:login_signup/shared/utils/external_link.dart';
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
  final ExternalLinkOpener _openLink;
  final RequestConsentLinkUseCase? _requestConsentLink;
  final GetBusinessSettingsUseCase? _getBusinessSettings;
  final String Function() _apiUrl;

  EditClientController({
    RequestConsentLinkUseCase? requestConsentLinkUseCase,
    GetBusinessSettingsUseCase? getBusinessSettingsUseCase,
    String Function()? apiUrl,
    required GetClientByIdUseCase getClientByIdUseCase,
    required UpdateClientUseCase updateClientUseCase,
    required DeleteClientUseCase deleteClientUseCase,
    required super.uploadClientImageUseCase,
    super.imagePicker,
    String? clientId,
    ExternalLinkOpener? openLink,
  })  : _openLink = openLink ?? openExternalLink,
        _requestConsentLink = requestConsentLinkUseCase,
        _getBusinessSettings = getBusinessSettingsUseCase,
        _apiUrl = apiUrl ?? (() => EnvConfig.apiUrl),
        _getClient = getClientByIdUseCase,
        _updateClient = updateClientUseCase,
        _deleteClient = deleteClientUseCase,
        clientId = clientId ?? _clientIdFromArguments();

  final String clientId;

  final status = EditClientStatus.loading.obs;
  final loadError = RxnString();
  final client = Rxn<ClientEntity>();
  final isDeleting = false.obs;

  bool get canDelete => ClientAccess.canDelete();

  /// Teléfono guardado del cliente (no el que se está editando); vacío =
  /// sin "Llamar" ni "WhatsApp".
  String get savedPhone => client.value?.phone.trim() ?? '';

  /// Abre el marcador con el teléfono del cliente.
  Future<void> callClient() =>
      _open(phoneCallUri(savedPhone), 'No se pudo abrir el teléfono');

  /// Abre el chat de WhatsApp con el cliente.
  Future<void> writeOnWhatsapp() =>
      _open(whatsappUri(savedPhone), 'No se pudo abrir WhatsApp');

  final isRequestingConsent = false.obs;

  /// Se puede pedir el consentimiento por WhatsApp (11.06): tiene teléfono
  /// y aún no aceptó. Si se dio de baja también se puede volver a pedir:
  /// decide el cliente.
  bool get canRequestConsent =>
      _requestConsentLink != null &&
      savedPhone.isNotEmpty &&
      savedWhatsappOptIn.value != true;

  /// Texto que se prellena en `wa.me`.
  static String consentMessage(
          {required String clientName,
          required String businessName,
          required String link}) =>
      'Hola $clientName, $businessName quiere enviarte recordatorios de tus '
      'citas por WhatsApp. Si estás de acuerdo, acepta aquí: $link';

  /// Pide el link de consentimiento y abre WhatsApp con el mensaje
  /// prellenado. Necesita conexión.
  Future<void> requestConsent() async {
    final useCase = _requestConsentLink;
    final current = client.value;
    if (useCase == null || current?.id == null || isRequestingConsent.value) {
      return;
    }
    isRequestingConsent.value = true;
    final result = await useCase(current!.id!);
    isRequestingConsent.value = false;
    await result.fold((failure) async {
      if (failure is NetworkFailure) {
        AppSnackbar.warning(
            'Para pedir el consentimiento hace falta internet. Conéctate e '
            'inténtalo de nuevo.',
            title: 'Sin conexión');
      } else {
        AppSnackbar.error(ClientAccess.messageFor(failure),
            title: 'No se pudo crear el link');
      }
    }, (link) async {
      if (link.alreadyOptedIn) {
        savedWhatsappOptIn.value = true;
        whatsappOptIn.value = true;
        AppSnackbar.info('${current.fullName} ya aceptó los recordatorios.',
            title: 'Ya aceptó');
        return;
      }
      final url = link.url ?? publicWebUrl(_apiUrl(), link.path);
      final text = consentMessage(
        clientName: current.name,
        businessName: await _businessName(),
        link: url,
      );
      await _open(whatsappUri(savedPhone, text: text),
          'No se pudo abrir WhatsApp');
    });
  }

  Future<String> _businessName() async {
    final useCase = _getBusinessSettings;
    if (useCase != null) {
      final name = (await useCase(NoParams()))
          .fold((_) => null, (settings) => settings.name);
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    return 'Tu negocio';
  }

  Future<void> _open(Uri? uri, String errorMessage) async {
    if (uri == null || !await _openLink(uri)) AppSnackbar.error(errorMessage);
  }

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
