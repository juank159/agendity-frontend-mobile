import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';

/// Mensaje para el usuario de un error de estadísticas.
String statsMessageFor(Failure failure) {
  if (failure is ForbiddenFailure) {
    return 'Solo el propietario del negocio puede ver estas estadísticas.';
  }
  return failure.message;
}

/// Estado de un bloque de estadísticas que se carga por separado (resumen,
/// métodos de pago, profesionales…): datos, carga y error.
///
/// Si se pide otra carga antes de que termine la anterior (p. ej. al cambiar
/// de período), solo se aplica la respuesta de la última.
class StatsSection<T> {
  final data = Rxn<T>();
  final isLoading = false.obs;
  final error = RxnString();

  /// `true` si reintentar no arregla el error (sin permiso).
  final errorIsFinal = false.obs;

  int _request = 0;

  bool get hasData => data.value != null;

  /// Carga con [fetch]. Con un error se conservan los datos que hubiera (una
  /// recarga fallida no vacía la pantalla). Devuelve el failure, si hubo.
  Future<Failure?> load(Future<Either<Failure, T>> Function() fetch) async {
    final request = ++_request;
    isLoading.value = true;
    error.value = null;
    errorIsFinal.value = false;

    final result = await fetch();
    if (request != _request) return null;

    isLoading.value = false;
    return result.fold(
      (failure) {
        error.value = statsMessageFor(failure);
        errorIsFinal.value = failure is ForbiddenFailure;
        return failure;
      },
      (value) {
        data.value = value;
        return null;
      },
    );
  }

  /// Olvida los datos (otro período) y descarta la carga en curso.
  void reset() {
    _request++;
    data.value = null;
    isLoading.value = false;
    error.value = null;
    errorIsFinal.value = false;
  }

  /// Error que no depende de una petición (p. ej. el rol no lo permite).
  void fail(String message, {bool isFinal = true}) {
    _request++;
    isLoading.value = false;
    error.value = message;
    errorIsFinal.value = isFinal;
  }
}
