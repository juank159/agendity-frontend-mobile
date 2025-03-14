// lib/features/auth/presentation/views/email_verification_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/button_global_form.dart';
import 'package:login_signup/utils/global_colors.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class EmailVerificationView extends GetView<EmailVerificationController> {
  const EmailVerificationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de correo'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/login'),
        ),
      ),
      body: Obx(
        () => SingleChildScrollView(
          child: SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      height: 100,
                      colorFilter: ColorFilter.mode(
                        GlobalColors.mainColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Título y subtítulo
                  Text(
                    'Verificar tu correo',
                    style: TextStyle(
                      color: GlobalColors.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Hemos enviado un código de verificación a:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GlobalColors.textColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    controller.email.value,
                    style: TextStyle(
                      color: GlobalColors.mainColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Campos para el código
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: PinCodeTextField(
                      appContext: context,
                      controller: controller.codeController,
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
                        activeColor: GlobalColors.mainColor,
                        inactiveColor: Colors.grey[300],
                        selectedColor: GlobalColors.mainColor,
                      ),
                      keyboardType: TextInputType.number,
                      boxShadows: [
                        BoxShadow(
                          offset: const Offset(0, 1),
                          color: Colors.black12,
                          blurRadius: 10,
                        )
                      ],
                      onChanged: (value) {},
                      beforeTextPaste: (text) {
                        return true;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contador de tiempo
                  if (controller.isTimerActive.value)
                    Row(
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
                    ),
                  const SizedBox(height: 30),

                  // Botón de verificar
                  controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : ButtonGlobalForm(
                          textButton: 'Verificar código',
                          onPressed: controller.verifyEmail,
                        ),
                  const SizedBox(height: 20),

                  // Opción para reenviar código
                  TextButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.requestVerificationCode,
                    child: Text(
                      '¿No recibiste el código? Reenviar',
                      style: TextStyle(
                        color: GlobalColors.mainColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
