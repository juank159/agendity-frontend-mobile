import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:get/route_manager.dart';
import 'package:login_signup/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/button_global_form.dart';
import 'package:login_signup/utils/global_colors.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Crear formKey con UniqueKey para evitar conflictos
    final formKey = UniqueKey();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restablecer contraseña'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (!controller.isLoading.value) {
              Get.back();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            child: Obx(() => Form(
                  key: formKey, // Usar UniqueKey en lugar de GlobalKey
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

                      // Título y correo
                      Text(
                        'Restablecer contraseña',
                        style: TextStyle(
                          color: GlobalColors.textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Hemos enviado un código de recuperación a:',
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

                      // Campo para el código sin utilizar TextEditingController
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: PinCodeTextField(
                          appContext: context,
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
                          onChanged: (value) {
                            // Actualizar el valor en el controlador
                            controller.code.value = value;
                          },
                          enabled: !controller.isLoading.value &&
                              !controller.isSuccess.value,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Temporizador - Similar al de EmailVerificationView
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
                      const SizedBox(height: 20),

                      // Campo de nueva contraseña con opción para mostrar/ocultar
                      Obx(() {
                        final isDisabled = controller.isLoading.value ||
                            controller.isSuccess.value;
                        return Column(
                          children: [
                            AbsorbPointer(
                              absorbing: isDisabled,
                              child: Container(
                                height: 55,
                                padding:
                                    const EdgeInsets.only(top: 3, left: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 7,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: controller.passwordController,
                                  keyboardType: TextInputType.text,
                                  obscureText:
                                      controller.isPasswordHidden.value,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: 'Nueva contraseña',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 16,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        controller.isPasswordHidden.value
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: GlobalColors.mainColor,
                                      ),
                                      onPressed:
                                          controller.togglePasswordVisibility,
                                    ),
                                    errorStyle: const TextStyle(height: 0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 15),

                      // Campo de confirmar contraseña con opción para mostrar/ocultar
                      Obx(() {
                        final isDisabled = controller.isLoading.value ||
                            controller.isSuccess.value;
                        return Column(
                          children: [
                            AbsorbPointer(
                              absorbing: isDisabled,
                              child: Container(
                                height: 55,
                                padding:
                                    const EdgeInsets.only(top: 3, left: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 7,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller:
                                      controller.confirmPasswordController,
                                  keyboardType: TextInputType.text,
                                  obscureText:
                                      controller.isConfirmPasswordHidden.value,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: 'Confirmar contraseña',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 16,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        controller.isConfirmPasswordHidden.value
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: GlobalColors.mainColor,
                                      ),
                                      onPressed: controller
                                          .toggleConfirmPasswordVisibility,
                                    ),
                                    errorStyle: const TextStyle(height: 0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 30),

                      // Botón de restablecer
                      controller.isLoading.value
                          ? const CircularProgressIndicator()
                          : ButtonGlobalForm(
                              textButton: 'Restablecer contraseña',
                              onPressed: controller.isSuccess.value
                                  ? null
                                  : () {
                                      // Asegurar que el foco se pierde antes de procesar
                                      FocusScope.of(context).unfocus();
                                      controller.resetPassword();
                                    },
                            ),
                      const SizedBox(height: 20),

                      // Opción para reenviar código - similar a EmailVerificationView
                      if (!controller.isSuccess.value)
                        TextButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.requestNewCode,
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
                )),
          ),
        ),
      ),
    );
  }
}
