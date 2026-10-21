// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
// import 'package:get/get_state_manager/src/simple/get_view.dart';
// import 'package:get/route_manager.dart';
// import 'package:login_signup/features/auth/presentation/controllers/forgot_password_controller.dart';
// import 'package:login_signup/features/auth/presentation/widgets/button_global_form.dart';
// import 'package:login_signup/features/auth/presentation/widgets/input_global_form.dart';
// import 'package:login_signup/utils/global_colors.dart';

// class ForgotPasswordView extends GetView<ForgotPasswordController> {
//   const ForgotPasswordView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Recuperar contraseña'),
//         centerTitle: true,
//       ),
//       body: Obx(
//         () => SingleChildScrollView(
//           child: SafeArea(
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   // Logo
//                   Container(
//                     alignment: Alignment.center,
//                     child: SvgPicture.asset(
//                       'assets/images/logo.svg',
//                       height: 100,
//                       colorFilter: ColorFilter.mode(
//                         GlobalColors.mainColor,
//                         BlendMode.srcIn,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 30),

//                   // Título y descripción
//                   Text(
//                     'Recuperar contraseña',
//                     style: TextStyle(
//                       color: GlobalColors.textColor,
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                   Text(
//                     'Ingresa tu correo electrónico y te enviaremos un código para recuperar tu contraseña',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: GlobalColors.textColor,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 40),

//                   // Campo de correo
//                   InputGlobalForm(
//                     controller: controller.emailController,
//                     text: 'Correo electrónico',
//                     obscureText: false,
//                     textInputType: TextInputType.emailAddress,
//                     suffixIcon: Icon(
//                       Icons.email_outlined,
//                       color: GlobalColors.mainColor,
//                     ),
//                   ),
//                   const SizedBox(height: 30),

//                   // Botón de enviar
//                   controller.isLoading.value
//                       ? const CircularProgressIndicator()
//                       : ButtonGlobalForm(
//                           textButton: 'Enviar código',
//                           onPressed: controller.requestPasswordReset,
//                         ),
//                   const SizedBox(height: 20),

//                   // Volver a login
//                   TextButton(
//                     onPressed: () => Get.back(),
//                     child: Text(
//                       'Volver a inicio de sesión',
//                       style: TextStyle(
//                         color: GlobalColors.mainColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:login_signup/utils/global_colors.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildBackButton(),
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 30),
                _buildTitle(),
                const SizedBox(height: 40),
                _buildEmailField(),
                const SizedBox(height: 30),
                _buildSendButton(),
                const SizedBox(height: 20),
                _buildBackToLoginButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Decoración del fondo (igual que login/register)
  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          GlobalColors.mainColor.withOpacity(0.1),
          Colors.white,
          Colors.white,
        ],
      ),
    );
  }

  // Botón de regresar
  Widget _buildBackButton() {
    return Row(
      children: [
        InkWell(
          onTap: () => Get.back(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            // decoration: BoxDecoration(
            //   color: Colors.white,
            //   borderRadius: BorderRadius.circular(12),
            //   boxShadow: [
            //     BoxShadow(
            //       color: GlobalColors.mainColor.withOpacity(0.1),
            //       spreadRadius: 0,
            //       blurRadius: 10,
            //       offset: const Offset(0, 4),
            //     ),
            //   ],
            // ),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: GlobalColors.mainColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // Header con logo (igual que register)
  Widget _buildHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        // decoration: BoxDecoration(
        //   color: Colors.white,
        //   borderRadius: BorderRadius.circular(20),
        //   boxShadow: [
        //     BoxShadow(
        //       color: GlobalColors.mainColor.withOpacity(0.1),
        //       spreadRadius: 0,
        //       blurRadius: 20,
        //       offset: const Offset(0, 10),
        //     ),
        //   ],
        // ),
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 80,
          colorFilter: ColorFilter.mode(
            GlobalColors.mainColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  // Título y descripción
  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recuperar contraseña 🔑',
          style: TextStyle(
            color: GlobalColors.textColor,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa tu correo electrónico y te enviaremos un código para recuperar tu contraseña',
          style: TextStyle(
            color: GlobalColors.textColor.withOpacity(0.6),
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // Campo de email (estilo consistente)
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          style: _buildInputTextStyle(),
          decoration: InputDecoration(
            labelText: 'Correo electrónico',
            labelStyle: TextStyle(
              color: GlobalColors.textColor.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelStyle: TextStyle(
              color: GlobalColors.mainColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            hintText: 'tu@email.com',
            hintStyle: TextStyle(
              color: GlobalColors.textColor.withOpacity(0.5),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: GlobalColors.mainColor,
              size: 22,
            ),
            filled: true,
            fillColor: GlobalColors.mainColor.withOpacity(0.05),
            border:
                _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
            enabledBorder:
                _buildInputBorder(GlobalColors.mainColor.withOpacity(0.2), 1),
            focusedBorder: _buildInputBorder(GlobalColors.mainColor, 2),
            errorBorder: _buildInputBorder(Colors.red.withOpacity(0.5), 1),
            focusedErrorBorder: _buildInputBorder(Colors.red, 2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
          ),
        ),
        // Aquí podrías agregar validación de errores si la tienes en el controlador
        // _buildErrorMessage(controller.emailError),
      ],
    );
  }

  // Estilo de texto para inputs
  TextStyle _buildInputTextStyle() {
    return TextStyle(
      color: GlobalColors.textColor,
      fontSize: 16,
    );
  }

  // Borde para inputs
  OutlineInputBorder _buildInputBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // Botón de enviar (estilo igual que login/register)
  Widget _buildSendButton() {
    return Obx(() => Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                GlobalColors.mainColor,
                GlobalColors.mainColor.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: GlobalColors.mainColor.withOpacity(0.3),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: controller.isLoading.value
                ? null
                : () {
                    debugPrint('📧 Enviando código de recuperación');
                    controller.requestPasswordReset();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Enviar código',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ));
  }

  // Botón para volver al login
  Widget _buildBackToLoginButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Recordaste tu contraseña? ',
          style: TextStyle(
            color: GlobalColors.textColor.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        GestureDetector(
          onTap: () => Get.back(),
          child: Text(
            'Inicia sesión',
            style: TextStyle(
              color: GlobalColors.mainColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
