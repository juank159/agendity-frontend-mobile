/// Filtros y orden de la lista paginada de clientes (`GET /clients`,
/// `PaginationDto` del backend). Sin parámetros = lo mismo que el backend por
/// defecto: página 1, más recientes primero.
class ClientsQuery {
  /// Tope del backend (`@Max(100)` en `limit`).
  static const maxLimit = 100;

  final int page;
  final int limit;

  /// Busca en nombre, apellido, email y teléfono. Vacío = sin búsqueda.
  final String? search;
  final ClientSortField sortBy;
  final SortDirection direction;
  final ClientStatusFilter status;
  final ClientSourceFilter source;

  const ClientsQuery({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.sortBy = ClientSortField.createdAt,
    this.direction = SortDirection.desc,
    this.status = ClientStatusFilter.all,
    this.source = ClientSourceFilter.all,
  });

  /// [search] sin espacios sobrantes; `null` si queda vacío.
  String? get normalizedSearch {
    final text = search?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientsQuery &&
          other.page == page &&
          other.limit == limit &&
          other.normalizedSearch == normalizedSearch &&
          other.sortBy == sortBy &&
          other.direction == direction &&
          other.status == status &&
          other.source == source;

  @override
  int get hashCode => Object.hash(
      page, limit, normalizedSearch, sortBy, direction, status, source);
}

/// Campo de orden (`sortBy`).
enum ClientSortField {
  name('name'),
  lastname('lastname'),
  email('email'),
  phone('phone'),
  createdAt('created_at');

  final String apiValue;
  const ClientSortField(this.apiValue);

  /// `null` si no se reconoce.
  static ClientSortField? fromApi(Object? value) {
    for (final field in values) {
      if (field.apiValue == value) return field;
    }
    return null;
  }
}

/// Sentido del orden (`sortOrder`).
enum SortDirection {
  asc('ASC'),
  desc('DESC');

  final String apiValue;
  const SortDirection(this.apiValue);

  /// `null` si no se reconoce (acepta minúsculas).
  static SortDirection? fromApi(Object? value) {
    final text = value?.toString().toUpperCase();
    for (final direction in values) {
      if (direction.apiValue == text) return direction;
    }
    return null;
  }
}

/// Filtro por estado (`status`): todos, activos o inactivos.
enum ClientStatusFilter {
  all,
  active,
  inactive;

  String get apiValue => name;

  static ClientStatusFilter? fromApi(Object? value) {
    for (final filter in values) {
      if (filter.name == value) return filter;
    }
    return null;
  }
}

/// Filtro por origen (`source`): todos, importados de los contactos o
/// creados a mano.
enum ClientSourceFilter {
  all,
  imported,
  manual;

  String get apiValue => name;

  static ClientSourceFilter? fromApi(Object? value) {
    for (final filter in values) {
      if (filter.name == value) return filter;
    }
    return null;
  }
}
