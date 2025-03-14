import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:get/route_manager.dart';
import 'package:login_signup/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/button_global_form.dart';
import 'package:login_signup/features/auth/presentation/widgets/input_global_form.dart';
import 'package:login_signup/utils/global_colors.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        centerTitle: true,
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

                  // Título y descripción
                  Text(
                    'Recuperar contraseña',
                    style: TextStyle(
                      color: GlobalColors.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Ingresa tu correo electrónico y te enviaremos un código para recuperar tu contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GlobalColors.textColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Campo de correo
                  InputGlobalForm(
                    controller: controller.emailController,
                    text: 'Correo electrónico',
                    obscureText: false,
                    textInputType: TextInputType.emailAddress,
                    suffixIcon: Icon(
                      Icons.email_outlined,
                      color: GlobalColors.mainColor,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botón de enviar
                  controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : ButtonGlobalForm(
                          textButton: 'Enviar código',
                          onPressed: controller.requestPasswordReset,
                        ),
                  const SizedBox(height: 20),

                  // Volver a login
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Volver a inicio de sesión',
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
