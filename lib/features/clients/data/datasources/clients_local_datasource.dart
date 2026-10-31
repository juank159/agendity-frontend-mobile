import 'package:drift/drift.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/clients/domain/entities/paginated_list.dart';

/// Clientes en la base local (10.02): lecturas con los mismos filtros, orden
/// y paginación que `GET /clients`, y escrituras de filas. Sin red.
class ClientsLocalDataSource {
  const ClientsLocalDataSource();

  // ---------------------------------------------------------------- Lecturas

  Future<PaginatedList<ClientEntity>> page(
      AppDatabase db, ClientsQuery query) async {
    final t = db.localClients;
    Expression<bool> where = const Constant(true);
    final search = query.normalizedSearch?.toLowerCase();
    if (search != null) {
      final pattern = '%${_escape(search)}%';
      Expression<bool> like(GeneratedColumn<String> column) =>
          column.lower().like(pattern, escapeChar: r'\');
      where = where &
          (like(t.name) |
              like(t.lastname) |
              like(t.email) |
              like(t.phone) |
              (t.name + const Constant(' ') + t.lastname)
                  .lower()
                  .like(pattern, escapeChar: r'\'));
    }
    switch (query.status) {
      case ClientStatusFilter.active:
        where = where & t.isActive.equals(true);
      case ClientStatusFilter.inactive:
        where = where & t.isActive.equals(false);
      case ClientStatusFilter.all:
        break;
    }
    switch (query.source) {
      case ClientSourceFilter.imported:
        where = where & t.isFromDevice.equals(true);
      case ClientSourceFilter.manual:
        where = where & t.isFromDevice.equals(false);
      case ClientSourceFilter.all:
        break;
    }

    final count = t.id.count();
    final total = await (db.selectOnly(t)
          ..addColumns([count])
          ..where(where))
        .map((row) => row.read(count) ?? 0)
        .getSingle();

    final limit = query.limit.clamp(1, ClientsQuery.maxLimit);
    final page = query.page < 1 ? 1 : query.page;
    final mode = query.direction == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;
    final rows = await (db.select(t)
          ..where((_) => where)
          ..orderBy([
            (c) => OrderingTerm(expression: _sortColumn(c, query.sortBy), mode: mode),
            (c) => OrderingTerm(expression: c.id, mode: mode),
          ])
          ..limit(limit, offset: (page - 1) * limit))
        .get();

    final totalPages = total == 0 ? 0 : (total + limit - 1) ~/ limit;
    return PaginatedList(
      items: rows.map(toEntity).toList(),
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
      hasNextPage: page < totalPages,
      hasPrevPage: page > 1,
    );
  }

  static Expression<Object> _sortColumn(
          $LocalClientsTable c, ClientSortField field) =>
      switch (field) {
        ClientSortField.name => c.name.lower(),
        ClientSortField.lastname => c.lastname.lower(),
        ClientSortField.email => c.email.lower(),
        ClientSortField.phone => c.phone,
        ClientSortField.createdAt => c.createdAt,
      };

  static String _escape(String text) => text
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  Future<ClientEntity?> byId(AppDatabase db, String id) async {
    final row = await _row(db, id) ?? await _row(db, await _remapped(db, id));
    return row == null ? null : toEntity(row);
  }

  Future<LocalClientRow?> _row(AppDatabase db, String? id) async => id == null
      ? null
      : (db.select(db.localClients)..where((c) => c.id.equals(id)))
          .getSingleOrNull();

  /// Id con el que el servidor fusionó [id] (`merged`), si lo hubo.
  Future<String?> _remapped(AppDatabase db, String id) async =>
      (await (db.select(db.idRemaps)
                ..where((r) => r.entity.equals('clients') & r.fromId.equals(id)))
              .getSingleOrNull())
          ?.toId;

  /// Otro cliente (no [exceptId]) con ese teléfono.
  Future<bool> phoneTaken(AppDatabase db, String phone, {String? exceptId}) =>
      _taken(db, db.localClients.phone.equals(phone), exceptId);

  /// Otro cliente con ese email (sin distinguir mayúsculas).
  Future<bool> emailTaken(AppDatabase db, String email, {String? exceptId}) =>
      _taken(db, db.localClients.email.lower().equals(email.toLowerCase()),
          exceptId);

  Future<bool> _taken(
      AppDatabase db, Expression<bool> condition, String? exceptId) async {
    final query = db.select(db.localClients)..where((_) => condition);
    if (exceptId != null) query.where((c) => c.id.equals(exceptId).not());
    return (await (query..limit(1)).get()).isNotEmpty;
  }

  // ------------------------------------------------------------- Escrituras

  /// Inserta o reemplaza con los campos presentes en [fields] (forma de la
  /// API: los del feed `clients` o los de un payload de `client.*`).
  Future<void> upsertFields(
      AppDatabase db, String id, Map<String, dynamic> fields) async {
    final companion = fieldsToCompanion(fields);
    final existing = await _row(db, id);
    if (existing == null) {
      await db.into(db.localClients).insertOnConflictUpdate(companion.copyWith(
            id: Value(id),
            name: companion.name.present ? companion.name : const Value(''),
            phone: companion.phone.present ? companion.phone : const Value(''),
          ));
    } else {
      await (db.update(db.localClients)..where((c) => c.id.equals(id)))
          .write(companion);
    }
  }

  Future<void> delete(AppDatabase db, String id) =>
      (db.delete(db.localClients)..where((c) => c.id.equals(id))).go();

  /// El registro [fromId] pasó a llamarse [toId] (fusión en el servidor).
  Future<void> remap(AppDatabase db, String fromId, String toId) async {
    if (await _row(db, toId) != null) {
      await delete(db, fromId);
    } else {
      await (db.update(db.localClients)..where((c) => c.id.equals(fromId)))
          .write(LocalClientsCompanion(id: Value(toId)));
    }
  }

  // ---------------------------------------------------------------- Mapeo

  /// Campos de la API → columnas (solo los presentes). `email` vacío =
  /// sin email; instantes en ISO UTC; `birthday` como día.
  static LocalClientsCompanion fieldsToCompanion(Map<String, dynamic> f) {
    Value<String?> optional(String key) => f.containsKey(key)
        ? Value(JsonRead.asOptionalString(f[key]))
        : const Value.absent();
    Value<String?> instant(String key) => f.containsKey(key)
        ? Value(_instant(f[key]))
        : const Value.absent();
    Value<String> text(String key) => f.containsKey(key)
        ? Value(JsonRead.asString(f[key]))
        : const Value.absent();
    Value<bool> flag(String key, bool fallback) => f.containsKey(key)
        ? Value(JsonRead.asBool(f[key], fallback: fallback))
        : const Value.absent();

    return LocalClientsCompanion(
      name: text('name'),
      lastname: text('lastname'),
      email: optional('email'),
      phone: text('phone'),
      image: optional('image'),
      address: optional('address'),
      isFromDevice: flag('isFromDevice', false),
      deviceContactId: optional('deviceContactId'),
      lastVisit: instant('lastVisit'),
      isActive: flag('isActive', true),
      createdAt: instant('created_at'),
      updatedAt: instant('updated_at'),
      notes: optional('notes'),
      birthday: f.containsKey('birthday')
          ? Value(_day(f['birthday']))
          : const Value.absent(),
      showNotes: flag('showNotes', false),
    );
  }

  static String? _instant(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim())?.toUtc().toIso8601String();
  }

  static String? _day(Object? value) {
    final day = DateCodec.tryDecodeDay(value);
    return day == null ? null : DateCodec.encodeDay(day);
  }

  static ClientEntity toEntity(LocalClientRow row) => ClientEntity(
        id: row.id,
        name: row.name,
        lastname: row.lastname,
        email: row.email,
        phone: row.phone,
        image: row.image,
        address: row.address,
        isFromDevice: row.isFromDevice,
        deviceContactId: row.deviceContactId,
        lastVisit: DateCodec.tryDecode(row.lastVisit),
        isActive: row.isActive,
        createdAt: DateCodec.tryDecode(row.createdAt),
        updatedAt: DateCodec.tryDecode(row.updatedAt),
        notes: row.notes,
        birthday: DateCodec.tryDecodeDay(row.birthday),
        showNotes: row.showNotes,
      );
}
