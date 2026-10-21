import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  /// Ejecuta el caso de uso de restablecer contraseña
  ///
  /// [email] - Email del usuario
  /// [code] - Código de verificación de 6 dígitos
  /// [newPassword] - Nueva contraseña que cumple los requisitos de seguridad
  ///
  /// Retorna [Right(true)] si la contraseña se restableció exitosamente
  /// Retorna [Left(Failure)] si hubo algún error
  Future<Either<Failure, bool>> call({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    return await repository.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }
}
