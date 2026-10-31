import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/notifications/domain/entities/app_notification.dart';
import 'package:login_signup/features/notifications/domain/repositories/notifications_repository.dart';

/// Avisos del usuario, los más recientes primero.
class GetNotificationsUseCase
    extends UseCase<List<AppNotification>, NoParams> {
  final NotificationsRepository repository;

  GetNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AppNotification>>> call(NoParams params) =>
      repository.getNotifications();
}
