import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';

/// UseCase para solicitar código de recuperación de contraseña
///
/// Este UseCase maneja la lógica específica para solicitar códigos de recuperación
/// de contraseña para usuarios existentes que olvidaron su contraseña
class RequestPasswordResetUseCase {
  final AuthRepository repository;

  RequestPasswordResetUseCase(this.repository);

  /// Ejecuta la solicitud de código de recuperación de contraseña
  ///
  /// [email] - Email del usuario que solicita la recuperación
  ///
  /// Returns: Either<Failure, void> - Error o éxito de la operación
  Future<Either<Failure, void>> call({required String email}) async {
    // Validación básica del email
    if (email.isEmpty || !_isValidEmail(email)) {
      return Left(ValidationFailure(message: 'Email inválido'));
    }

    // Llamar al repositorio para solicitar el código de recuperación
    return await repository.requestPasswordReset(email: email);
  }

  /// Validación simple de formato de email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Excepción específica para errores de validación
class ValidationFailure extends Failure {
  ValidationFailure({required String message}) : super(message: message);
}
