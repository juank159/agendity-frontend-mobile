import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/register_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/button_global_form.dart';
import 'package:login_signup/features/auth/presentation/widgets/input_global_form.dart';
import 'package:login_signup/features/auth/presentation/widgets/social_media.dart';
import 'package:login_signup/utils/global_colors.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Obx(
        () => SingleChildScrollView(
          child: SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 20),
                  Text(
                    'Crear una cuenta',
                    style: TextStyle(
                      color: GlobalColors.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  InputGlobalForm(
                    controller: controller.nameController,
                    text: 'Nombre',
                    obscureText: false,
                    textInputType: TextInputType.text,
                  ),
                  const SizedBox(height: 10),
                  InputGlobalForm(
                    controller: controller.lastnameController,
                    text: 'Apellidos',
                    obscureText: false,
                    textInputType: TextInputType.text,
                  ),
                  const SizedBox(height: 10),
                  InputGlobalForm(
                    controller: controller.phoneController,
                    text: 'Teléfono',
                    obscureText: false,
                    textInputType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  InputGlobalForm(
                    controller: controller.emailController,
                    text: 'Correo electrónico',
                    obscureText: false,
                    textInputType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  InputGlobalForm(
                    controller: controller.passwordController,
                    text: 'Contraseña',
                    obscureText: true,
                    textInputType: TextInputType.text,
                  ),
                  const SizedBox(height: 20),
                  controller.isLoading.value
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : ButtonGlobalForm(
                          textButton: 'Registrarse',
                          onPressed: controller.registerUser,
                        ),
                  const SizedBox(height: 30),
                  const SocialMedia(
                    text: '- O Regístrate Con -',
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
