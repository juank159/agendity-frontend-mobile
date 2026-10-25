import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';

/// UseCase para solicitar código de verificación por email
///
/// Este UseCase maneja la lógica de negocio para solicitar códigos de verificación
/// Puede ser usado tanto para nuevos usuarios (registro) como para usuarios existentes
class RequestVerificationCodeUseCase {
  final AuthRepository repository;

  RequestVerificationCodeUseCase(this.repository);

  /// Ejecuta la solicitud de código de verificación
  ///
  /// [email] - Email al que se enviará el código
  /// [isNewUser] - Indica si es un nuevo usuario (true) o existente (false)
  ///
  /// Returns: Either<Failure, void> - Error o éxito de la operación
  Future<Either<Failure, void>> call({
    required String email,
    bool isNewUser = false,
  }) async {
    // Validación básica del email
    if (email.isEmpty || !_isValidEmail(email)) {
      return Left(ValidationFailure(message: 'Email inválido'));
    }

    // Llamar al repositorio para solicitar el código
    return await repository.requestVerificationCode(
      email: email,
      isNewUser: isNewUser,
    );
  }

  /// Validación simple de formato de email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Excepción específica para errores de validación
class ValidationFailure extends Failure {
  ValidationFailure({required super.message});
}
