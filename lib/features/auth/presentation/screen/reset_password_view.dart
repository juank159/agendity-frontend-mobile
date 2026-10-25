import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:login_signup/utils/global_colors.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

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
                const SizedBox(height: 30),
                _buildPinCodeField(context),
                const SizedBox(height: 20),
                _buildTimer(),
                const SizedBox(height: 20),
                _buildConfirmPasswordField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 30),
                _buildResetButton(context),
                const SizedBox(height: 20),
                _buildResendCodeButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Decoración del fondo (consistente)
  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          GlobalColors.mainColor.withValues(alpha: 0.1),
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
        Obx(() => InkWell(
              onTap: controller.isLoading.value ? null : () => Get.back(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: controller.isLoading.value
                      ? Colors.grey
                      : GlobalColors.mainColor,
                  size: 20,
                ),
              ),
            )),
      ],
    );
  }

  // Header con logo
  Widget _buildHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 70,
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
          'Restablecer contraseña 🔐',
          style: TextStyle(
            color: GlobalColors.textColor,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hemos enviado un código de recuperación a:',
          style: TextStyle(
            color: GlobalColors.textColor.withValues(alpha: 0.6),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Obx(() => Text(
              controller.email.value,
              style: TextStyle(
                color: GlobalColors.mainColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )),
      ],
    );
  }

  // Campo PIN con estilo mejorado
  Widget _buildPinCodeField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() => PinCodeTextField(
            appContext: context,
            length: 6,
            obscureText: false,
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: 56,
              fieldWidth: 45,
              activeFillColor: GlobalColors.mainColor.withValues(alpha: 0.05),
              inactiveFillColor: GlobalColors.mainColor.withValues(alpha: 0.05),
              selectedFillColor: GlobalColors.mainColor.withValues(alpha: 0.1),
              activeColor: GlobalColors.mainColor,
              inactiveColor: GlobalColors.mainColor.withValues(alpha: 0.2),
              selectedColor: GlobalColors.mainColor,
              borderWidth: 2,
            ),
            textStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: GlobalColors.textColor,
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              controller.code.value = value;
            },
            enabled: !controller.isLoading.value && !controller.isSuccess.value,
          )),
    );
  }

  // Timer (si existe)
  Widget _buildTimer() {
    return Obx(() => controller.isTimerActive.value
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: Colors.orange[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Código válido por: ${controller.formattedTime}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink());
  }

  // Campo de nueva contraseña
  Widget _buildPasswordField() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AbsorbPointer(
              absorbing:
                  controller.isLoading.value || controller.isSuccess.value,
              child: TextField(
                controller: controller.passwordController,
                obscureText: controller.isPasswordHidden.value,
                style: _buildInputTextStyle(),
                onChanged: (value) => controller.validatePassword(),
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  labelStyle: TextStyle(
                    color: GlobalColors.textColor.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: GlobalColors.mainColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: 'Mínimo 8 caracteres',
                  hintStyle: TextStyle(
                    color: GlobalColors.textColor.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: GlobalColors.mainColor,
                    size: 22,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordHidden.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: GlobalColors.mainColor,
                      size: 22,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                  filled: true,
                  fillColor: GlobalColors.mainColor.withValues(alpha: 0.05),
                  border: _buildInputBorder(
                      GlobalColors.mainColor.withValues(alpha: 0.2), 1),
                  enabledBorder: _buildInputBorder(
                      GlobalColors.mainColor.withValues(alpha: 0.2), 1),
                  focusedBorder: _buildInputBorder(GlobalColors.mainColor, 2),
                  disabledBorder:
                      _buildInputBorder(Colors.grey.withValues(alpha: 0.3), 1),
                  errorBorder:
                      _buildInputBorder(Colors.red.withValues(alpha: 0.5), 1),
                  focusedErrorBorder: _buildInputBorder(Colors.red, 2),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                ),
                enabled:
                    !controller.isLoading.value && !controller.isSuccess.value,
              ),
            ),
            _buildPasswordError(),
            _buildPasswordValidationIndicators(),
          ],
        ));
  }

  // Campo de confirmar contraseña
  Widget _buildConfirmPasswordField() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AbsorbPointer(
              absorbing:
                  controller.isLoading.value || controller.isSuccess.value,
              child: TextField(
                controller: controller.confirmPasswordController,
                obscureText: controller.isConfirmPasswordHidden.value,
                style: _buildInputTextStyle(),
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  labelStyle: TextStyle(
                    color: GlobalColors.textColor.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: GlobalColors.mainColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: 'Confirma tu nueva contraseña',
                  hintStyle: TextStyle(
                    color: GlobalColors.textColor.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: GlobalColors.mainColor,
                    size: 22,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isConfirmPasswordHidden.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: GlobalColors.mainColor,
                      size: 22,
                    ),
                    onPressed: controller.toggleConfirmPasswordVisibility,
                  ),
                  filled: true,
                  fillColor: GlobalColors.mainColor.withValues(alpha: 0.05),
                  border: _buildInputBorder(
                      GlobalColors.mainColor.withValues(alpha: 0.2), 1),
                  enabledBorder: _buildInputBorder(
                      GlobalColors.mainColor.withValues(alpha: 0.2), 1),
                  focusedBorder: _buildInputBorder(GlobalColors.mainColor, 2),
                  disabledBorder:
                      _buildInputBorder(Colors.grey.withValues(alpha: 0.3), 1),
                  errorBorder:
                      _buildInputBorder(Colors.red.withValues(alpha: 0.5), 1),
                  focusedErrorBorder: _buildInputBorder(Colors.red, 2),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                ),
                enabled:
                    !controller.isLoading.value && !controller.isSuccess.value,
              ),
            ),
            _buildConfirmPasswordError(),
          ],
        ));
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

  // Botón de restablecer
  Widget _buildResetButton(BuildContext context) {
    return Obx(() => Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                GlobalColors.mainColor,
                GlobalColors.mainColor.withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: GlobalColors.mainColor.withValues(alpha: 0.3),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed:
                (controller.isLoading.value || controller.isSuccess.value)
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        debugPrint('🔐 Restableciendo contraseña');
                        controller.resetPassword();
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
                    'Restablecer contraseña',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ));
  }

  // Botón para reenviar código
  Widget _buildResendCodeButton() {
    return Obx(() => !controller.isSuccess.value
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿No recibiste el código? ',
                style: TextStyle(
                  color: GlobalColors.textColor.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: controller.canResendCode
                    ? () {
                        debugPrint('📧 Reenviando código');
                        controller.requestNewCode();
                      }
                    : null,
                child: Text(
                  'Reenviar',
                  style: TextStyle(
                    color: controller.canResendCode
                        ? GlobalColors.mainColor
                        : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          )
        : const SizedBox.shrink());
  }

  // Error de contraseña
  Widget _buildPasswordError() {
    return Obx(() => controller.passwordError.value.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    controller.passwordError.value,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink());
  }

  // Error de confirmación de contraseña
  Widget _buildConfirmPasswordError() {
    return Obx(() => controller.confirmPasswordError.value.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    controller.confirmPasswordError.value,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink());
  }

  // Indicadores de validación de contraseña
  Widget _buildPasswordValidationIndicators() {
    return Obx(() {
      if (controller.passwordValidations.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GlobalColors.mainColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: GlobalColors.mainColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Requisitos de contraseña:',
              style: TextStyle(
                color: GlobalColors.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildValidationItem('Al menos 8 caracteres', 'length'),
            _buildValidationItem('Una letra mayúscula', 'uppercase'),
            _buildValidationItem('Una letra minúscula', 'lowercase'),
            _buildValidationItem('Un número', 'number'),
            _buildValidationItem('Un carácter especial (@\$!%*?&)', 'special'),
          ],
        ),
      );
    });
  }

  // Item de validación individual
  Widget _buildValidationItem(String text, String key) {
    return Obx(() {
      final isValid = controller.passwordValidations[key] ?? false;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              controller.getValidationIcon(isValid),
              size: 14,
              color: controller.getValidationColor(isValid),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  color: controller.getValidationColor(isValid),
                  fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
