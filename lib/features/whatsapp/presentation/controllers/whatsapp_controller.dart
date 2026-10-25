import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import '../../domain/entities/whatsapp_config.dart';
import '../../domain/usecases/get_whatsapp_config_usecase.dart';
import '../../domain/usecases/save_whatsapp_config_usecase.dart';
import '../../domain/usecases/send_test_message_usecase.dart';

/// Estado de la carga inicial de la pantalla.
enum WhatsappLoadStatus { loading, ready, error }

/// Configuración de CallMeBot del negocio (solo Owner: la ruta lleva
/// `RoleMiddleware.ownerOnly()`).
///
/// Referencia de la Fase 4 (ARQUITECTURA §4): solo habla con use cases y
/// resuelve cada `Either` con `fold`; la carga se pinta con los estados de
/// `core/widgets` y las acciones avisan con `AppSnackbar`/`AppDialogs`.
class WhatsappController extends GetxController {
  final GetWhatsappConfigUseCase _getConfig;
  final SaveWhatsappConfigUseCase _saveConfig;
  final SendTestMessageUseCase _sendTestMessage;

  WhatsappController({
    required GetWhatsappConfigUseCase getWhatsappConfigUseCase,
    required SaveWhatsappConfigUseCase saveWhatsappConfigUseCase,
    required SendTestMessageUseCase sendTestMessageUseCase,
  })  : _getConfig = getWhatsappConfigUseCase,
        _saveConfig = saveWhatsappConfigUseCase,
        _sendTestMessage = sendTestMessageUseCase;

  /// Indicativo de Colombia que se antepone al número nacional.
  static const countryCode = '57';

  final status = WhatsappLoadStatus.loading.obs;
  final loadError = RxnString();

  /// `true` si el error de carga no se arregla reintentando (sin permiso).
  final loadErrorIsFinal = false.obs;

  /// `null` = el negocio aún no configuró WhatsApp (se muestra el formulario).
  final config = Rxn<WhatsappConfig>();

  final isEditing = false.obs;
  final isSaving = false.obs;
  final isSendingTest = false.obs;

  /// Formulario. `formEnabled` es el interruptor del formulario.
  final phoneController = TextEditingController();
  final apiKeyController = TextEditingController();
  final formEnabled = true.obs;

  bool get hasConfig => config.value != null;
  bool get showForm => !hasConfig || isEditing.value;
  bool get isBusy => isSaving.value || isSendingTest.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    phoneController.dispose();
    apiKeyController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    status.value = WhatsappLoadStatus.loading;
    loadError.value = null;
    loadErrorIsFinal.value = false;

    final result = await _getConfig(NoParams());
    result.fold(
      (failure) {
        loadError.value = _messageFor(failure);
        loadErrorIsFinal.value = failure is ForbiddenFailure;
        status.value = WhatsappLoadStatus.error;
      },
      (current) {
        config.value = current;
        isEditing.value = false;
        _fillForm(current);
        status.value = WhatsappLoadStatus.ready;
      },
    );
  }

  void startEditing() {
    _fillForm(config.value);
    isEditing.value = true;
  }

  void cancelEditing() {
    _fillForm(config.value);
    isEditing.value = false;
  }

  /// Guarda el formulario. Devuelve `true` si se guardó.
  Future<bool> saveForm() async {
    final phone = fullPhoneNumber(phoneController.text);
    final apiKey = apiKeyController.text.trim();
    if (phone == null) {
      AppSnackbar.warning(
          'Escribe un número de celular de 10 dígitos, sin el +57.');
      return false;
    }
    if (apiKey.isEmpty) {
      AppSnackbar.warning('Escribe la API Key que te envió CallMeBot.');
      return false;
    }
    return _save(
      SaveWhatsappConfigParams(
        phoneNumber: phone,
        apiKey: apiKey,
        isEnabled: formEnabled.value,
      ),
      successMessage: 'Configuración guardada',
    );
  }

  /// Activa o desactiva los avisos con la configuración guardada. Desactivar
  /// pide confirmación.
  Future<void> toggleEnabled() async {
    final current = config.value;
    if (current == null || isBusy) return;
    final enable = !current.isEnabled;
    if (!enable) {
      final confirmed = await AppDialogs.confirm(
        title: '¿Desactivar avisos?',
        message: 'Dejarás de recibir en tu WhatsApp los avisos de las citas.',
        confirmLabel: 'Desactivar',
        destructive: true,
        icon: Icons.notifications_off_outlined,
      );
      if (!confirmed) return;
    }
    await _save(
      SaveWhatsappConfigParams(
        phoneNumber: current.phoneNumber,
        apiKey: current.apiKey,
        isEnabled: enable,
      ),
      successMessage: enable ? 'Avisos activados' : 'Avisos desactivados',
    );
  }

  Future<void> sendTestMessage() async {
    if (!hasConfig || isBusy) return;
    isSendingTest.value = true;
    final result = await _sendTestMessage(NoParams());
    isSendingTest.value = false;
    result.fold(
      (failure) => AppSnackbar.error(_messageFor(failure)),
      (sent) => sent
          ? AppSnackbar.success('Revisa tu WhatsApp: te enviamos un mensaje.',
              title: 'Prueba enviada')
          : AppSnackbar.warning(
              'CallMeBot no aceptó el mensaje. Revisa el número y la API Key.',
              title: 'No se envió la prueba'),
    );
  }

  Future<bool> _save(SaveWhatsappConfigParams params,
      {required String successMessage}) async {
    if (isBusy) return false;
    isSaving.value = true;
    final result = await _saveConfig(params);
    isSaving.value = false;
    return result.fold(
      (failure) {
        AppSnackbar.error(_messageFor(failure));
        return false;
      },
      (saved) {
        config.value = saved;
        isEditing.value = false;
        _fillForm(saved);
        AppSnackbar.success(successMessage);
        return true;
      },
    );
  }

  void _fillForm(WhatsappConfig? source) {
    phoneController.text = nationalPhoneNumber(source?.phoneNumber ?? '');
    apiKeyController.text = source?.apiKey ?? '';
    formEnabled.value = source?.isEnabled ?? true;
  }

  static String _messageFor(Failure failure) {
    if (failure is ForbiddenFailure) {
      return 'Solo el propietario del negocio puede configurar WhatsApp.';
    }
    if (failure is NotFoundFailure) {
      return 'Guarda la configuración antes de enviar una prueba.';
    }
    return failure.message;
  }

  /// `573001234567` → `3001234567` (lo que el Owner escribe y ve).
  static String nationalPhoneNumber(String full) {
    final digits = full.replaceAll(RegExp(r'\D'), '');
    return digits.length == 12 && digits.startsWith(countryCode)
        ? digits.substring(2)
        : digits;
  }

  /// Número del formulario → formato de CallMeBot (`57` + 10 dígitos).
  /// `null` si no es un celular colombiano válido.
  static String? fullPhoneNumber(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '$countryCode$digits';
    if (digits.length == 12 && digits.startsWith(countryCode)) return digits;
    return null;
  }
}
