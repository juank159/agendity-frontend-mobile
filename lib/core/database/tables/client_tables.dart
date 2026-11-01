import 'package:drift/drift.dart';

/// Clientes del negocio en local (feed `clients`). Fechas como texto: los
/// instantes en ISO UTC (`…Z`, ordenan como texto) y [birthday] como día
/// `yyyy-MM-dd`.
@DataClassName('LocalClientRow')
class LocalClients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get lastname => text().withDefault(const Constant(''))();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text()();
  TextColumn get image => text().nullable()();
  TextColumn get address => text().nullable()();
  BoolColumn get isFromDevice =>
      boolean().withDefault(const Constant(false))();
  TextColumn get deviceContactId => text().nullable()();
  TextColumn get lastVisit => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get birthday => text().nullable()();
  BoolColumn get showNotes => boolean().withDefault(const Constant(false))();

  /// Consentimiento de WhatsApp (Fase 11, esquema 3). `null` = aún no bajó.
  BoolColumn get whatsappOptIn => boolean().nullable()();
  TextColumn get whatsappOptInAt => text().nullable()();
  TextColumn get whatsappOptOutAt => text().nullable()();

  /// Origen del consentimiento (`APP`/`WEB`/`LINK`, 11.06, esquema 4).
  TextColumn get whatsappOptInSource => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
