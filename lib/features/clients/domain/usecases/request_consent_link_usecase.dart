import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/clients/domain/entities/consent_link.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';

/// Pide el link de consentimiento de un cliente (Owner y Employee, solo con
/// conexión; sin red, `NetworkFailure`).
class RequestConsentLinkUseCase extends UseCase<ConsentLink, String> {
  final ClientsRepository repository;

  RequestConsentLinkUseCase(this.repository);

  @override
  Future<Either<Failure, ConsentLink>> call(String clientId) =>
      repository.requestConsentLink(clientId);
}
