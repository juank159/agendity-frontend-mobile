import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/features/statistics/data/local/local_stats.dart';

/// Carga de la base local lo que necesitan las estadísticas (10.02c).
class StatisticsLocalDataSource {
  const StatisticsLocalDataSource();

  Future<LocalStats> load(AppDatabase db) async {
    final clients = await db.select(db.localClients).get();
    return LocalStats(LocalStatsData(
      payments: await DocumentStore.list(db, 'payments'),
      appointments: {
        for (final a
            in await DocumentStore.list(db, SharedDocs.appointments.entity))
          a['id'] as String: a,
      },
      clients: {
        for (final c in clients) c.id: (name: c.name, lastname: c.lastname),
      },
      users: {
        for (final u in await DocumentStore.list(db, SharedDocs.users.entity))
          u['id'] as String: u,
      },
      customMethods: {
        for (final m in await DocumentStore.list(db, 'custom_payment_methods'))
          m['id'] as String: m,
      },
      userServices:
          await DocumentStore.list(db, SharedDocs.userServices.entity),
    ));
  }

  /// ¿El usuario de la sesión es el Owner? Solo el Owner recibe los pagos
  /// en la sincronización: sin ellos, las cifras de ingresos no se pueden
  /// calcular en local.
  Future<bool> isOwner(AppDatabase db, String? userId) async {
    if (userId == null) return false;
    final user = await DocumentStore.get(db, SharedDocs.users.entity, userId);
    return user != null && SharedDocs.isOwner(user);
  }
}
