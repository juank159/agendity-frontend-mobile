import 'package:drift/drift.dart';

/// Registros del feed guardados con la **misma forma que la API** (10.02b):
/// citas, pagos, servicios, categorías, profesionales, asignaciones,
/// horarios, bloqueos, métodos de pago, configuración y notificaciones. Así
/// los leen los mismos modelos (`fromJson`) que antes leían la respuesta
/// HTTP: una sola conversión, con y sin conexión.
///
/// Columnas de búsqueda (las pone cada `DocumentKind`): [ref1]/[ref2] para
/// referencias (profesional, cliente, cita…) y [at] para un instante en ISO
/// UTC (ordenar y filtrar por fecha).
@DataClassName('LocalDocumentRow')
@TableIndex(name: 'idx_documents_ref1', columns: {#entity, #ref1})
@TableIndex(name: 'idx_documents_ref2', columns: {#entity, #ref2})
@TableIndex(name: 'idx_documents_at', columns: {#entity, #at})
class LocalDocuments extends Table {
  TextColumn get entity => text()();
  TextColumn get id => text()();
  TextColumn get data => text()();
  TextColumn get ref1 => text().nullable()();
  TextColumn get ref2 => text().nullable()();
  TextColumn get at => text().nullable()();

  @override
  Set<Column> get primaryKey => {entity, id};
}
