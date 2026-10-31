import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/sync/document_sync_handler.dart';

/// Profesionales, sus servicios y sus horarios: solo bajada (10.02b). Se
/// gestionan con conexión (`/auth/employee*`) y la app vuelve a sincronizar
/// después de cada cambio.
abstract final class EmployeesSync {
  static List<DocumentSyncHandler> handlers() => [
        DocumentSyncHandler(SharedDocs.users),
        DocumentSyncHandler(SharedDocs.userServices),
        DocumentSyncHandler(SharedDocs.schedules),
      ];
}
