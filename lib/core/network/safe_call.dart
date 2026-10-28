import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/error_mapper.dart';
import 'package:login_signup/core/utils/app_logger.dart';

/// Convierte un failure genérico en uno de la feature (p. ej. `code ==
/// ApiErrorCode.slotUnavailable` → `SlotUnavailableFailure`).
typedef FailureRefiner = Failure Function(Failure failure);

/// Envuelve toda llamada de un repositorio: éxito → `Right`, cualquier error
/// (red, HTTP, `fromJson` que falla) → `Left(Failure)` vía `ErrorMapper`.
///
/// ```dart
/// Future<Either<Failure, Client>> getClient(String id) =>
///     safeCall(() async => (await _remote.getClient(id)).toEntity());
/// ```
Future<Either<Failure, T>> safeCall<T>(
  Future<T> Function() call, {
  FailureRefiner? refine,
}) async {
  try {
    return Right(await call());
  } catch (error, stackTrace) {
    final failure = ErrorMapper.fromObject(error);
    if (failure is ServerFailure && failure.statusCode == null) {
      // Errores de programación (TypeError en un fromJson, etc.): sin datos de la petición.
      AppLogger.error('[safeCall] ${error.runtimeType}', '$error\n$stackTrace');
    }
    return Left(refine == null ? failure : refine(failure));
  }
}
