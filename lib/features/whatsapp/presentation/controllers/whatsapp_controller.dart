// // lib/features/whatsapp/presentation/controllers/whatsapp_controller.dart
// import 'package:get/get.dart';
// import 'package:login_signup/core/errors/failures.dart';
// import '../../domain/usecases/get_whatsapp_config_usecase.dart';
// import '../../domain/usecases/save_whatsapp_config_usecase.dart';
// import '../../domain/usecases/send_test_message_usecase.dart';
// import '../../domain/usecases/send_message_usecase.dart';
// import '../../../../core/usecases/usecase.dart';

// class WhatsappController extends GetxController {
//   final GetWhatsappConfigUseCase getWhatsappConfigUseCase;
//   final SaveWhatsappConfigUseCase saveWhatsappConfigUseCase;
//   final SendTestMessageUseCase sendTestMessageUseCase;
//   final SendMessageUseCase sendMessageUseCase;

//   WhatsappController({
//     required this.getWhatsappConfigUseCase,
//     required this.saveWhatsappConfigUseCase,
//     required this.sendTestMessageUseCase,
//     required this.sendMessageUseCase,
//   });

//   // Estados observables
//   final isLoading = false.obs;
//   final errorMessage = RxnString();
//   final successMessage = RxnString();

//   // Datos de la configuración
//   final phoneNumber = ''.obs;
//   final apiKey = ''.obs;
//   final isEnabled = true.obs;
//   final configId = RxnString();

//   @override
//   void onInit() {
//     super.onInit();
//     loadConfig();
//   }

//   Future<void> loadConfig() async {
//     isLoading.value = true;
//     errorMessage.value = null;

//     final result = await getWhatsappConfigUseCase(NoParams());

//     result.fold(
//       (failure) {
//         // Verificar si el fallo es porque no se encontró configuración
//         if (failure is ServerFailure && failure.message.contains('not found')) {
//           // Es normal, simplemente iniciamos con valores vacíos
//           print('No configuration found, starting with empty values');
//         } else {
//           // Otro tipo de error que sí debemos mostrar
//           errorMessage.value = failure.message;
//         }
//       },
//       (config) {
//         phoneNumber.value = config.phoneNumber;
//         apiKey.value = config.apiKey;
//         isEnabled.value = config.isEnabled;
//         configId.value = config.id;
//       },
//     );

//     isLoading.value = false;
//   }

//   Future<void> saveConfig() async {
//     if (phoneNumber.value.isEmpty || apiKey.value.isEmpty) {
//       errorMessage.value = 'Número de teléfono y API Key son obligatorios';
//       return;
//     }

//     isLoading.value = true;
//     errorMessage.value = null;
//     successMessage.value = null;

//     final params = SaveWhatsappConfigParams(
//       phoneNumber: phoneNumber.value,
//       apiKey: apiKey.value,
//       isEnabled: isEnabled.value,
//     );

//     final result = await saveWhatsappConfigUseCase(params);

//     result.fold(
//       (failure) {
//         errorMessage.value = failure.message;
//       },
//       (config) {
//         successMessage.value = 'Configuración guardada correctamente';
//         phoneNumber.value = config.phoneNumber;
//         apiKey.value = config.apiKey;
//         isEnabled.value = config.isEnabled;
//         configId.value = config.id;
//       },
//     );

//     isLoading.value = false;
//   }

//   Future<void> sendTestMessage() async {
//     // Verificar si ya hay configuración o si aún no se ha guardado
//     if (phoneNumber.value.isEmpty || apiKey.value.isEmpty) {
//       errorMessage.value = 'Por favor, guarda la configuración primero';
//       return;
//     }

//     isLoading.value = true;
//     errorMessage.value = null;
//     successMessage.value = null;

//     // Si tenemos valores en los campos pero aún no se ha guardado la configuración
//     if (configId.value == null) {
//       // Guardar la configuración primero
//       await saveConfig();
//       // Si hubo un error al guardar, no continuamos
//       if (errorMessage.value != null) {
//         isLoading.value = false;
//         return;
//       }
//     }

//     // Ahora enviamos el mensaje de prueba
//     final result = await sendTestMessageUseCase(NoParams());

//     result.fold(
//       (failure) {
//         errorMessage.value =
//             'Error al enviar mensaje de prueba: ${failure.message}';
//       },
//       (success) {
//         if (success) {
//           successMessage.value = 'Mensaje de prueba enviado correctamente';
//         } else {
//           errorMessage.value = 'No se pudo enviar el mensaje de prueba';
//         }
//       },
//     );

//     isLoading.value = false;
//   }

//   Future<bool> sendWhatsAppMessage(String phoneNumber, String message) async {
//     if (phoneNumber.isEmpty || message.isEmpty) {
//       errorMessage.value = 'Número de teléfono y mensaje son obligatorios';
//       return false;
//     }

//     isLoading.value = true;
//     errorMessage.value = null;

//     final params = SendMessageParams(
//       phoneNumber: phoneNumber,
//       message: message,
//     );

//     final result = await sendMessageUseCase(params);

//     bool success = false;
//     result.fold(
//       (failure) {
//         errorMessage.value = 'Error al enviar mensaje: ${failure.message}';
//       },
//       (sent) {
//         success = sent;
//         if (!sent) {
//           errorMessage.value = 'No se pudo enviar el mensaje';
//         }
//       },
//     );

//     isLoading.value = false;
//     return success;
//   }
// }

// lib/features/whatsapp/presentation/controllers/whatsapp_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/whatsapp_config.dart';
import '../../domain/usecases/get_whatsapp_config_usecase.dart';
import '../../domain/usecases/save_whatsapp_config_usecase.dart';
import '../../domain/usecases/send_test_message_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../../../core/usecases/usecase.dart';

class WhatsappController extends GetxController {
  final GetWhatsappConfigUseCase getWhatsappConfigUseCase;
  final SaveWhatsappConfigUseCase saveWhatsappConfigUseCase;
  final SendTestMessageUseCase sendTestMessageUseCase;
  final SendMessageUseCase sendMessageUseCase;

  WhatsappController({
    required this.getWhatsappConfigUseCase,
    required this.saveWhatsappConfigUseCase,
    required this.sendTestMessageUseCase,
    required this.sendMessageUseCase,
  });

  // Estados observables
  var isLoading = false.obs;
  var hasExistingConfig = false.obs;
  var isEditing = false.obs;

  // Datos de configuración
  var phoneNumber = ''.obs;
  var apiKey = ''.obs;
  var isEnabled = true.obs;
  var configId = ''.obs;

  // Mensajes
  var errorMessage = Rx<String?>(null);
  var successMessage = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchConfig();
  }

  // Cargar configuración existente
  Future<void> fetchConfig() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      successMessage.value = null;

      final result = await getWhatsappConfigUseCase(NoParams());

      result.fold(
        (failure) {
          errorMessage.value =
              'Error al cargar la configuración: ${failure.message}';
          hasExistingConfig.value = false;
        },
        (config) {
          if (config.id != null && config.id!.isNotEmpty) {
            // Configuración existente
            hasExistingConfig.value = true;
            configId.value = config.id!;

            // Extraer el número de teléfono sin el código de país (57)
            String fullPhone = config.phoneNumber;
            if (fullPhone.startsWith('57') && fullPhone.length > 2) {
              phoneNumber.value = fullPhone.substring(2);
            } else {
              phoneNumber.value = fullPhone;
            }

            apiKey.value = config.apiKey;
            isEnabled.value = config.isEnabled;
          } else {
            // No hay configuración guardada
            hasExistingConfig.value = false;
            phoneNumber.value = '';
            apiKey.value = '';
            isEnabled.value = true;
          }
        },
      );
    } catch (e) {
      errorMessage.value = 'Error: ${e.toString()}';
      hasExistingConfig.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // Habilitar modo edición
  void enableEditing() {
    isEditing.value = true;
  }

  // Cancelar edición
  void cancelEditing() {
    isEditing.value = false;
    fetchConfig(); // Recargar datos originales
  }

  // Guardar configuración
  Future<void> saveConfig() async {
    try {
      // Validación básica
      if (phoneNumber.value.isEmpty || apiKey.value.isEmpty) {
        errorMessage.value = 'Todos los campos son obligatorios';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;
      successMessage.value = null;

      // Formatear el número de teléfono para incluir el código de país (57)
      String formattedPhone = phoneNumber.value.trim();
      if (!formattedPhone.startsWith('57')) {
        formattedPhone =
            "57${formattedPhone.replaceAll(RegExp(r'[^0-9]'), '')}";
      }

      final params = SaveWhatsappConfigParams(
        phoneNumber: formattedPhone,
        apiKey: apiKey.value.trim(),
        isEnabled: isEnabled.value,
      );

      final result = await saveWhatsappConfigUseCase(params);

      result.fold(
        (failure) {
          errorMessage.value =
              'Error al guardar la configuración: ${failure.message}';
        },
        (config) {
          successMessage.value = 'Configuración guardada correctamente';
          hasExistingConfig.value = true;
          configId.value = config.id ?? '';
          isEditing.value = false;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Enviar mensaje de prueba
  Future<void> sendTestMessage() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      successMessage.value = null;

      final result = await sendTestMessageUseCase(NoParams());

      result.fold(
        (failure) {
          String displayMessage = failure.message;
          if (displayMessage.contains('not found for owner')) {
            displayMessage =
                'Debes guardar la configuración antes de enviar un mensaje de prueba';
          }
          errorMessage.value = displayMessage;
        },
        (success) {
          if (success) {
            successMessage.value = 'Mensaje de prueba enviado correctamente';
          } else {
            errorMessage.value = 'No se pudo enviar el mensaje de prueba';
          }
        },
      );
    } catch (e) {
      errorMessage.value = 'Error: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Enviar mensaje personalizado
  Future<void> sendMessage(String phoneNumber, String message) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final params = SendMessageParams(
        phoneNumber: phoneNumber,
        message: message,
      );

      final result = await sendMessageUseCase(params);

      result.fold(
        (failure) {
          errorMessage.value = 'Error al enviar mensaje: ${failure.message}';
        },
        (success) {
          if (success) {
            successMessage.value = 'Mensaje enviado correctamente';
          } else {
            errorMessage.value = 'No se pudo enviar el mensaje';
          }
        },
      );
    } catch (e) {
      errorMessage.value = 'Error: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
}
