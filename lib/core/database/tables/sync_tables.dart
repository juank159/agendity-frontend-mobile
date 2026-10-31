import 'package:drift/drift.dart';

/// Bandeja de salida (10.02, D-18): una fila por operación hecha en el
/// dispositivo, en el orden en que se hizo ([seq]). Solo sale de aquí con un
/// resultado del servidor (`SyncEngine`).
@DataClassName('OutboxRow')
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();

  /// UUID v7: idempotencia en el servidor (`sync_mutations`).
  TextColumn get mutationId => text().unique()();

  /// Operación de negocio (`client.create`, `appointment.cancel`…).
  TextColumn get type => text()();

  /// Entidad del feed (`clients`, `appointments`…) y su id.
  TextColumn get entity => text()();
  TextColumn get entityId => text().nullable()();

  /// JSON con los campos de la ruta online de esa operación.
  TextColumn get payload => text().withDefault(const Constant('{}'))();

  /// Instante en que se hizo (ISO UTC): el servidor decide "solo a futuro"
  /// con él.
  TextColumn get clientTime => text()();

  /// `pending` (se envía), `rejected` o `conflict` (esperan al usuario).
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get code => text().nullable()();
  TextColumn get message => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}

/// Clave → valor del motor: cursor de la bajada, id del dispositivo, versión
/// del esquema de sincronización.
@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Ids locales que el servidor fusionó con otro (`merged`): para seguir
/// encontrando el registro por el id viejo.
@DataClassName('IdRemapRow')
class IdRemaps extends Table {
  TextColumn get entity => text()();
  TextColumn get fromId => text()();
  TextColumn get toId => text()();

  @override
  Set<Column> get primaryKey => {entity, fromId};
}
