import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/constants/app_colors.dart';
import 'package:login_signup/features/employees/presentation/controllers/verify_employee_email_controller.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyEmployeeEmailScreen extends GetView<VerifyEmployeeEmailController> {
  const VerifyEmployeeEmailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _confirmExit(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verificar Email del Empleado'),
          centerTitle: true,
          backgroundColor: AppColors.cardIndicator,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmExit(context)) {
                // Asegurarse de limpiar recursos antes de salir
                controller.disposeResources();
                Get.back(result: false);
              }
            },
          ),
        ),
        body: Obx(() {
          return controller.isLoading.value
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.cardIndicator),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardIndicator.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.email_outlined,
                            size: 60,
                            color: AppColors.cardIndicator,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Verificación de Email',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.black54,
                                ),
                            children: [
                              const TextSpan(
                                text: 'Estamos verificando el email de ',
                              ),
                              TextSpan(
                                text: controller.employeeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cardIndicator,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(() {
                          return controller.errorMessage.value != null
                              ? Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.red[300]!),
                                  ),
                                  child: Text(
                                    controller.errorMessage.value!,
                                    style: TextStyle(color: Colors.red[800]),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : const SizedBox.shrink();
                        }),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.blue[700]),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'La verificación del email es obligatoria',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      color: Colors.blue[700], fontSize: 14),
                                  children: [
                                    const TextSpan(
                                      text: 'Hemos enviado un código a ',
                                    ),
                                    TextSpan(
                                      text: controller.email.value,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const TextSpan(
                                      text: ' para verificar la cuenta.',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildPinCodeTextField(context),
                        ),
                        const SizedBox(height: 20),
                        Obx(() {
                          return controller.isTimerActive.value
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.timer, color: Colors.grey),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Código válido por: ${controller.formattedTime}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink();
                        }),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: Obx(() {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.cardIndicator,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: controller.isLoading.value
                                  ? null
                                  : () {
                                      print('Botón de verificación presionado');
                                      controller.verifyEmail();
                                    },
                              child: controller.isLoading.value
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text('VERIFICANDO...'),
                                      ],
                                    )
                                  : const Text('VERIFICAR EMAIL'),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                        Obx(() => TextButton.icon(
                              onPressed: controller.isLoading.value ||
                                      !controller.canResendCode.value
                                  ? null
                                  : () {
                                      print('Botón de reenvío presionado');
                                      controller.requestVerificationCode();
                                    },
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text(controller.canResendCode.value
                                  ? 'Reenviar código'
                                  : 'Espere ${controller.formattedResendTime} para reenviar'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.cardIndicator,
                              ),
                            )),
                        const SizedBox(height: 20),

                        // Botón para método alternativo
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: OutlinedButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.simulateVerificationAndNavigate,
                            icon: const Icon(Icons.verified_user),
                            label: const Text(
                              'Verificar y continuar (Método alternativo)',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              foregroundColor: AppColors.cardIndicator,
                              side: BorderSide(color: AppColors.cardIndicator),
                            ),
                          ),
                        ),

                        // Botón para desarrollo - modo fácil
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: OutlinedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : () {
                                    // Configurar código de prueba
                                    if (controller.codeController != null) {
                                      controller.codeController!.text =
                                          '123456';
                                      controller.verifyEmail();
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              side: BorderSide(color: Colors.grey[400]!),
                            ),
                            child: Text(
                              'Usar código de prueba (solo desarrollo)',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
        }),
      ),
    );
  }

  // Extraemos el PinCodeTextField a un método separado para mejorar la legibilidad
  Widget _buildPinCodeTextField(BuildContext context) {
    // Verificar que el controlador de texto exista
    if (controller.codeController == null) {
      return const Center(
        child: Text('Error: controlador de código no inicializado'),
      );
    }

    return PinCodeTextField(
      appContext: context,
      controller: controller.codeController!,
      length: 6,
      obscureText: false,
      animationType: AnimationType.fade,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(8),
        fieldHeight: 50,
        fieldWidth: 40,
        activeFillColor: Colors.white,
        inactiveFillColor: Colors.white,
        selectedFillColor: Colors.white,
        activeColor: AppColors.cardIndicator,
        inactiveColor: Colors.grey[300],
        selectedColor: AppColors.cardIndicator,
      ),
      keyboardType: TextInputType.number,
      boxShadows: const [
        BoxShadow(
          offset: Offset(0, 1),
          color: Colors.black12,
          blurRadius: 10,
        )
      ],
      onChanged: (value) {
        // Solo log para mostrar los cambios
        print('Código actual: $value');
      },
      onCompleted: (value) {
        if (!controller.isLoading.value) {
          print('Código completo: $value, enviando verificación');
          controller.verifyEmail();
        }
      },
    );
  }

  Future<bool> _confirmExit(BuildContext context) async {
    // Mostrar diálogo de confirmación
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verificación obligatoria'),
        content: const Text(
          'La verificación del email es obligatoria para crear el profesional. '
          '¿Está seguro que desea cancelar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar verificación'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      // Pequeño delay para asegurar que el diálogo se cierre completamente
      await Future.delayed(const Duration(milliseconds: 100));

      // Cuando el usuario decide salir, limpiamos recursos y navegamos de vuelta
      controller
          .disposeResources(); // Usar el método público para limpiar recursos
      return true; // Permitimos que WillPopScope ejecute el pop
    }

    return false; // No permitimos que WillPopScope ejecute el pop
  }
}
