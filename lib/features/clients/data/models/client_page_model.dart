import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/clients/data/models/client_model.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/paginated_list.dart';

/// Respuesta de `GET /clients` (`PaginationResult<Client>`):
/// `{data, total, page, limit, totalPages, hasNextPage, hasPrevPage}`.
class ClientPageModel {
  final List<ClientModel> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  const ClientPageModel({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory ClientPageModel.fromJson(Map<String, dynamic> json) {
    final data =
        JsonRead.asMapList(json['data']).map(ClientModel.fromJson).toList();
    final page = JsonRead.asInt(json['page'], fallback: 1);
    final totalPages = JsonRead.asInt(json['totalPages']);
    return ClientPageModel(
      data: data,
      total: JsonRead.asInt(json['total'], fallback: data.length),
      page: page,
      limit: JsonRead.asInt(json['limit'], fallback: data.length),
      totalPages: totalPages,
      hasNextPage:
          JsonRead.asBool(json['hasNextPage'], fallback: page < totalPages),
      hasPrevPage: JsonRead.asBool(json['hasPrevPage'], fallback: page > 1),
    );
  }

  PaginatedList<ClientEntity> toEntity() => PaginatedList(
        items: data.map((m) => m.toEntity()).toList(),
        total: total,
        page: page,
        limit: limit,
        totalPages: totalPages,
        hasNextPage: hasNextPage,
        hasPrevPage: hasPrevPage,
      );
}
