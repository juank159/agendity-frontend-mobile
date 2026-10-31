import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/utils/json_read.dart';

/// Tipos de registro locales que leen varias features (10.02b): los
/// profesionales (`users`), sus servicios (`user_services`) y sus horarios
/// (`schedules`) los usan empleados, catálogo y citas (horas libres). Los
/// baja y guarda el handler de empleados.
abstract final class SharedDocs {
  static const users = DocumentKind('users');

  static final userServices = DocumentKind('user_services',
      ref1: (d) => JsonRead.asOptionalString(d['userId']),
      ref2: (d) => JsonRead.asOptionalString(d['serviceId']));

  /// `user` llega como id (`loadRelationIds`).
  static final schedules = DocumentKind('schedules',
      ref1: (d) => JsonRead.asOptionalString(
          d['user'] is Map ? (d['user'] as Map)['id'] : d['user']));

  static const businessSettings = DocumentKind('business_settings');

  /// Citas: profesional, cliente e inicio. Las escriben citas y pagos (el
  /// primer pago confirma la cita y cambia su estado de pago).
  static final appointments = DocumentKind('appointments',
      ref1: (d) => JsonRead.asOptionalString(d['professionalId']),
      ref2: (d) => JsonRead.asOptionalString(
          d['client'] is Map ? (d['client'] as Map)['id'] : d['clientId']),
      at: (d) => d['date']);

  /// ¿El usuario (registro de `users`) es el Owner?
  static bool isOwner(Map<String, dynamic> user) => [
        for (final role in JsonRead.asMapList(user['roles'])) role['name'],
      ].contains('Owner');
}
