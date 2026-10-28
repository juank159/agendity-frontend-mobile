import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usecases/cancel_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/complete_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_available_slots_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_upcoming_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/mark_reminder_sent_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/prepare_reminder_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/update_appointment_usecase.dart';

/// Datasource, repositorio y use cases de citas (ARQUITECTURA §4). Los
/// controllers los registran los bindings.
abstract final class AppointmentsDependencies {
  static void init() {
    Get.lazyPut<AppointmentsRemoteDataSource>(
      () => AppointmentsRemoteDataSourceImpl(Get.find<Dio>(tag: apiClientTag)),
      fenix: true,
    );
    Get.lazyPut<AppointmentsRepository>(
      () => AppointmentsRepositoryImpl(Get.find<AppointmentsRemoteDataSource>()),
      fenix: true,
    );

    AppointmentsRepository repository() => Get.find<AppointmentsRepository>();
    Get.lazyPut(() => GetAppointmentsUseCase(repository()), fenix: true);
    Get.lazyPut(() => GetAppointmentUseCase(repository()), fenix: true);
    Get.lazyPut(() => CreateAppointmentUseCase(repository()), fenix: true);
    Get.lazyPut(() => UpdateAppointmentUseCase(repository()), fenix: true);
    Get.lazyPut(() => CancelAppointmentUseCase(repository()), fenix: true);
    Get.lazyPut(() => CompleteAppointmentUseCase(repository()), fenix: true);
    Get.lazyPut(() => GetAvailableSlotsUseCase(repository()), fenix: true);
    Get.lazyPut(() => GetUpcomingAppointmentsUseCase(repository()),
        fenix: true);
    Get.lazyPut(() => PrepareReminderUseCase(repository()), fenix: true);
    Get.lazyPut(() => MarkReminderSentUseCase(repository()), fenix: true);
  }
}
