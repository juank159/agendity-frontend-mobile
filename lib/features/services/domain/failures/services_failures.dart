import 'package:login_signup/core/errors/failures.dart';

/// Ya existe un servicio con ese nombre en el negocio (409 `CONFLICT` al
/// crear o editar un servicio: es el único conflicto posible ahí).
class DuplicateServiceNameFailure extends ConflictFailure {
  static const defaultMessage =
      'Ya existe un servicio con ese nombre en tu negocio';

  const DuplicateServiceNameFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// Ya existe una categoría con ese nombre en el negocio (409 `CONFLICT` al
/// crear o renombrar una categoría).
class DuplicateCategoryNameFailure extends ConflictFailure {
  static const defaultMessage =
      'Ya tienes una categoría con ese nombre. Usa un nombre diferente.';

  const DuplicateCategoryNameFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// La categoría tiene servicios (activos o no) y no se puede borrar
/// (409 `CATEGORY_HAS_SERVICES`; o `CONFLICT` si la FK RESTRICT lo frena).
class CategoryHasServicesFailure extends ConflictFailure {
  static const defaultMessage =
      'No se puede eliminar la categoría porque tiene servicios. '
      'Muévelos a otra categoría o elimínalos primero.';

  const CategoryHasServicesFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// Datos de un servicio o una categoría fuera de las reglas del backend.
/// La producen los use cases antes de llamar al backend; [details] lista
/// todos los problemas y [message] los une.
class InvalidCatalogDataFailure extends ValidationFailure {
  const InvalidCatalogDataFailure({super.message, super.details});

  factory InvalidCatalogDataFailure.of(List<String> problems) =>
      InvalidCatalogDataFailure(
          message: problems.join('\n'), details: problems);
}
