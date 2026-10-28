import 'package:login_signup/features/clients/domain/usecases/create_client_usecase.dart';
import 'client_form_controller.dart';

/// Alta de un cliente (Owner y Employee).
class NewClientController extends ClientFormController {
  final CreateClientUseCase _createClient;

  NewClientController({
    required CreateClientUseCase createClientUseCase,
    required super.uploadClientImageUseCase,
    super.imagePicker,
  }) : _createClient = createClientUseCase;

  @override
  Future<bool> submit() => runSave(
        () async =>
            (await _createClient(formData())).fold((f) => f, (_) => null),
        successMessage: 'Cliente creado',
      );
}
