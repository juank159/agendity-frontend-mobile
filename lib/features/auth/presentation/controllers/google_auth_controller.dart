import 'package:get/get.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'auth_feedback.dart';
import 'auth_navigation.dart';

/// Botón "Continuar con Google" del login y del registro. Cancelar el
/// selector no muestra nada; si el backend lo rechaza o la cuenta no tiene
/// acceso, se avisa.
class GoogleAuthController extends GetxController {
  final GoogleSignInUseCase _signIn;

  GoogleAuthController({required GoogleSignInUseCase googleSignInUseCase})
      : _signIn = googleSignInUseCase;

  final isLoading = false.obs;

  Future<void> signInWithGoogle() async {
    if (isLoading.value) return;
    isLoading.value = true;
    final result = await _signIn(NoParams());
    if (isClosed) return;
    await result.fold(
      (failure) async {
        isLoading.value = false;
        await AuthFeedback.show(failure,
            title: 'No se pudo entrar con Google');
      },
      (_) async {
        await AuthNavigation.enterHome();
        if (!isClosed) isLoading.value = false;
      },
    );
  }
}
