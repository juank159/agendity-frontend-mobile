import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:login_signup/core/database/app_database.dart';

/// Un tipo de registro en [LocalDocuments]: su entidad del feed y cómo se
/// sacan sus columnas de búsqueda de los datos (forma de la API).
class DocumentKind {
  final String entity;
  final String? Function(Map<String, dynamic> data)? ref1;
  final String? Function(Map<String, dynamic> data)? ref2;

  /// Instante (cualquier ISO con offset); se guarda en UTC.
  final Object? Function(Map<String, dynamic> data)? at;

  const DocumentKind(this.entity, {this.ref1, this.ref2, this.at});
}

/// Lectura y escritura de [LocalDocuments] (10.02b).
abstract final class DocumentStore {
  static Future<void> put(AppDatabase db, DocumentKind kind, String id,
      Map<String, dynamic> data) {
    final stored = {...data, 'id': data['id'] ?? id};
    return db.into(db.localDocuments).insertOnConflictUpdate(
          LocalDocumentsCompanion.insert(
            entity: kind.entity,
            id: id,
            data: jsonEncode(stored),
            ref1: Value(kind.ref1?.call(stored)),
            ref2: Value(kind.ref2?.call(stored)),
            at: Value(instant(kind.at?.call(stored))),
          ),
        );
  }

  /// Mezcla [changes] (primer nivel) sobre lo guardado; si no existe, lo crea.
  static Future<Map<String, dynamic>> merge(AppDatabase db, DocumentKind kind,
      String id, Map<String, dynamic> changes) async {
    final merged = {...?await get(db, kind.entity, id), ...changes};
    await put(db, kind, id, merged);
    return merged;
  }

  static Future<Map<String, dynamic>?> get(
      AppDatabase db, String entity, String id) async {
    final row = await (db.select(db.localDocuments)
          ..where((d) => d.entity.equals(entity) & d.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _decode(row.data);
  }

  /// Registros de [entity], filtrados por referencias o por un rango
  /// [from, to) de [LocalDocuments.at], ordenados por `at` y luego por id.
  static Future<List<Map<String, dynamic>>> list(
    AppDatabase db,
    String entity, {
    String? ref1,
    String? ref2,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = db.select(db.localDocuments)
      ..where((d) => d.entity.equals(entity));
    if (ref1 != null) query.where((d) => d.ref1.equals(ref1));
    if (ref2 != null) query.where((d) => d.ref2.equals(ref2));
    if (from != null) {
      query.where((d) => d.at.isBiggerOrEqualValue(instant(from)!));
    }
    if (to != null) query.where((d) => d.at.isSmallerThanValue(instant(to)!));
    query.orderBy([(d) => OrderingTerm.asc(d.at), (d) => OrderingTerm.asc(d.id)]);
    return [for (final row in await query.get()) _decode(row.data)];
  }

  static Future<void> delete(AppDatabase db, String entity, String id) =>
      (db.delete(db.localDocuments)
            ..where((d) => d.entity.equals(entity) & d.id.equals(id)))
          .go();

  // ------------------------------------------------- Copia del servidor

  static String _shadow(String entity) => '@$entity';
  static const _absent = '__absent';

  /// Antes de una escritura local: guarda la versión del servidor (si aún
  /// no hay copia) para poder deshacerla si el servidor la rechaza.
  static Future<void> keepServerCopy(
      AppDatabase db, String entity, String id) async {
    if (await get(db, _shadow(entity), id) != null) return;
    final current = await get(db, entity, id);
    await put(db, DocumentKind(_shadow(entity)), id,
        current ?? {_absent: true});
  }

  /// Llegó la versión del servidor: la copia ya no hace falta.
  static Future<void> dropServerCopy(
          AppDatabase db, String entity, String id) =>
      delete(db, _shadow(entity), id);

  /// Deshace lo local: vuelve a la copia del servidor (o quita lo creado sin
  /// conexión). Sin copia, no hace nada.
  static Future<void> restoreServerCopy(
      AppDatabase db, DocumentKind kind, String id) async {
    final copy = await get(db, _shadow(kind.entity), id);
    if (copy == null) return;
    if (copy[_absent] == true) {
      await delete(db, kind.entity, id);
    } else {
      await put(db, kind, id, copy);
    }
    await dropServerCopy(db, kind.entity, id);
  }

  /// ISO UTC de un instante (texto con offset o `DateTime`); `null` si no lo es.
  static String? instant(Object? value) {
    final parsed = switch (value) {
      DateTime() => value,
      String() => DateTime.tryParse(value.trim()),
      _ => null,
    };
    return parsed?.toUtc().toIso8601String();
  }

  static Map<String, dynamic> _decode(String data) =>
      Map<String, dynamic>.from(jsonDecode(data) as Map);
}
