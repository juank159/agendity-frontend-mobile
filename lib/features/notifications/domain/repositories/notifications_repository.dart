import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/notifications/domain/entities/app_notification.dart';

/// Avisos del usuario de la sesión (10.02b: llegan con la sincronización y se
/// leen sin conexión).
abstract class NotificationsRepository {
  /// Los más recientes primero.
  Future<Either<Failure, List<AppNotification>>> getNotifications();
}
