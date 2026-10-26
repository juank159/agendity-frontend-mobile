import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/failures/services_failures.dart';

/// Reglas del backend para servicios y categorías (`CreateServiceDto`,
/// `CreateCategoryDto`), comprobadas antes de llamar al backend.
abstract final class CatalogRules {
  static const maxNameLength = 100;
  static final _hexColor = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');

  /// `null` si el servicio cumple las reglas.
  static InvalidCatalogDataFailure? checkService(ServiceEntity service) {
    final problems = <String>[
      ..._nameProblems(service.name, 'del servicio'),
      if (service.price.isNaN || service.price < 0)
        'El precio no puede ser negativo',
      if (service.duration < 1) 'La duración debe ser de al menos 1 minuto',
      if (service.categoryId.trim().isEmpty) 'Selecciona una categoría',
      if (!_hexColor.hasMatch(service.color))
        'El color debe ser hexadecimal (#RRGGBB)',
      if (service.deposit < 0) 'El abono no puede ser negativo',
    ];
    return problems.isEmpty ? null : InvalidCatalogDataFailure.of(problems);
  }

  /// `null` si el nombre de la categoría cumple las reglas.
  static InvalidCatalogDataFailure? checkCategoryName(String name) {
    final problems = _nameProblems(name, 'de la categoría');
    return problems.isEmpty ? null : InvalidCatalogDataFailure.of(problems);
  }

  static List<String> _nameProblems(String name, String of) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return ['El nombre $of es obligatorio'];
    if (trimmed.length > maxNameLength) {
      return ['El nombre $of admite como máximo $maxNameLength caracteres'];
    }
    return const [];
  }
}
