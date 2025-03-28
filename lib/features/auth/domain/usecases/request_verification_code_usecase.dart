import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';

class RequestVerificationCodeUseCase {
  final AuthRepository repository;

  RequestVerificationCodeUseCase(this.repository);

  Future<Either<Failure, bool>> call({required String email}) {
    return repository.requestVerificationCode(email: email);
  }
}
