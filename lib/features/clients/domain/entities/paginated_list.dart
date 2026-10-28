/// Una página de resultados del backend (`PaginationResult` de
/// `backend/src/clients/dto/pagination.dto.ts`).
class PaginatedList<T> {
  final List<T> items;

  /// Total de elementos en el servidor con los filtros aplicados.
  final int total;

  /// Página actual, desde 1.
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  const PaginatedList({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  /// La misma página con otros elementos (p. ej. de DTO a entidad).
  PaginatedList<R> map<R>(R Function(T item) convert) => PaginatedList<R>(
        items: items.map(convert).toList(),
        total: total,
        page: page,
        limit: limit,
        totalPages: totalPages,
        hasNextPage: hasNextPage,
        hasPrevPage: hasPrevPage,
      );

  @override
  String toString() =>
      'PaginatedList(page $page/$totalPages, ${items.length} de $total)';
}
