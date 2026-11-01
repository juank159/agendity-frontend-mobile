import 'package:get/get.dart';
import 'package:login_signup/features/clients/domain/usecases/request_consent_link_usecase.dart';
import 'package:login_signup/features/clients/presentation/controllers/clients_controller.dart';
import 'package:login_signup/features/clients/presentation/controllers/device_contacts.dart';
import 'package:login_signup/features/clients/presentation/controllers/edit_client_controller.dart';
import 'package:login_signup/features/clients/presentation/controllers/new_client_controller.dart';
import 'package:login_signup/features/settings/domain/usecases/get_business_settings_usecase.dart';

/// Lista de clientes (`/clients`). Solo controllers: datasource, repositorio
/// y use cases los registra `ClientsDependencies`.
class ClientsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ClientsController(
          getClientsPageUseCase: Get.find(),
          importClientsUseCase: Get.find(),
          readDeviceContacts: readDeviceContacts,
        ));
  }
}

/// Alta de cliente (`/clients/new`).
class NewClientBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NewClientController(
          createClientUseCase: Get.find(),
          uploadClientImageUseCase: Get.find(),
        ));
  }
}

/// Edición de cliente (`/clients/edit`, id en `arguments['clientId']`).
class EditClientBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EditClientController(
          // 11.06: link de consentimiento y nombre del negocio para el texto.
          requestConsentLinkUseCase:
              Get.isRegistered<RequestConsentLinkUseCase>()
                  ? Get.find<RequestConsentLinkUseCase>()
                  : null,
          getBusinessSettingsUseCase:
              Get.isRegistered<GetBusinessSettingsUseCase>()
                  ? Get.find<GetBusinessSettingsUseCase>()
                  : null,
          getClientByIdUseCase: Get.find(),
          updateClientUseCase: Get.find(),
          deleteClientUseCase: Get.find(),
          uploadClientImageUseCase: Get.find(),
        ));
  }
}
