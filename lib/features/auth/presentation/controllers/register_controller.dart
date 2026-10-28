import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/auth/domain/entities/register_owner_input.dart';
import 'package:login_signup/features/auth/domain/failures/auth_failures.dart';
import 'package:login_signup/features/auth/domain/usecases/register_usecase.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'auth_feedback.dart';
import 'auth_navigation.dart';
import 'password_policy.dart';

/// Alta de un negocio (`/register`): crea el Owner con su trial e inicia su
/// sesión (lo hace el use case). Después pasa a verificar el email; el Owner
/// puede usar la app sin verificarlo.
class RegisterController extends GetxController {
  final RegisterUseCase _register;

  RegisterController({required RegisterUseCase registerUseCase})
      : _register = registerUseCase;

  static final _lettersOnly = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
  static final _phone = RegExp(r'^[0-9]{10}$');

  final nameController = TextEditingController();
  final lastnameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordHidden = true.obs;

  final nameError = ''.obs;
  final lastnameError = ''.obs;
  final phoneError = ''.obs;
  final emailError = ''.obs;
  final passwordError = ''.obs;

  /// Estado de cada requisito; vacío hasta que se escribe la contraseña.
  final passwordChecks = <PasswordRequirement, bool>{}.obs;

  @override
  void onClose() {
    nameController.dispose();
    lastnameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() => isPasswordHidden.toggle();

  /// Actualiza los requisitos mientras se escribe.
  void onPasswordChanged(String password) {
    passwordChecks.assignAll(PasswordPolicy.check(password));
    if (passwordError.value.isNotEmpty &&
        PasswordPolicy.validate(password) == null) {
      passwordError.value = '';
    }
  }

  static String _validateName(String value, String field) {
    if (value.isEmpty) return 'El $field es obligatorio';
    if (value.length < 2) return 'El $field debe tener al menos 2 caracteres';
    if (value.length > 50) return 'El $field no puede superar 50 caracteres';
    if (!_lettersOnly.hasMatch(value)) {
      return 'El $field solo puede contener letras y espacios';
    }
    return '';
  }

  bool validateAllFields() {
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    nameError.value = _validateName(nameController.text.trim(), 'nombre');
    lastnameError.value =
        _validateName(lastnameController.text.trim(), 'apellido');
    phoneError.value = phone.isEmpty
        ? 'El teléfono es obligatorio'
        : (_phone.hasMatch(phone)
            ? ''
            : 'El teléfono debe tener exactamente 10 dígitos');
    emailError.value = email.isEmpty
        ? 'El correo electrónico es obligatorio'
        : (GetUtils.isEmail(email) ? '' : 'Ingresa un correo válido');
    passwordChecks.assignAll(PasswordPolicy.check(password));
    passwordError.value = PasswordPolicy.validate(password) ?? '';

    return [nameError, lastnameError, phoneError, emailError, passwordError]
        .every((error) => error.value.isEmpty);
  }

  Future<void> registerUser() async {
    if (isLoading.value) return;
    if (!validateAllFields()) {
      AppSnackbar.warning('Corrige los campos marcados para continuar',
          title: 'Revisa los datos');
      return;
    }

    isLoading.value = true;
    final email = emailController.text.trim();
    final result = await _register(RegisterOwnerInput(
      name: nameController.text,
      lastname: lastnameController.text,
      email: email,
      phone: phoneController.text,
      password: passwordController.text,
    ));
    if (isClosed) return;
    isLoading.value = false;

    await result.fold(
      (failure) async {
        switch (failure) {
          case DuplicateEmailFailure():
            emailError.value = 'Este correo ya está registrado';
          case DuplicatePhoneFailure():
            phoneError.value = 'Este teléfono ya está registrado';
          case InvalidAuthDataFailure():
            emailError.value = failure.message;
          default:
            break;
        }
        await AuthFeedback.show(failure, title: 'No se pudo crear la cuenta');
      },
      (_) async {
        AppSnackbar.success('Te enviamos un código para verificar tu correo',
            title: 'Cuenta creada');
        Get.offAllNamed(GetRoutes.verifyEmail, arguments: {AuthNavigation.emailKey: email});
      },
    );
  }
}
