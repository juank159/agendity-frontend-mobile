// lib/features/appointments/presentation/bindings/appointment_reminder_binding.dart
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_upcoming_appointments_usecase.dart';
import '../controllers/appointment_reminder_controller.dart';

import '../../data/datasources/appointments_remote_datasource.dart';
import '../../data/repositories/appointments_repository_impl.dart';
import '../../../../core/network/network_info.dart';
import '../../../clients/data/datasources/clients_remote_datasource.dart';

class AppointmentReminderBinding implements Bindings {
  @override
  void dependencies() {
    // Asegurarse de que NetworkInfo esté registrado
    if (!Get.isRegistered<NetworkInfo>()) {
      Get.put<NetworkInfo>(
        NetworkInfoImpl(connectionChecker: InternetConnectionChecker()),
      );
    }

    // Asegurarse de que las dependencias básicas estén registradas
    if (!Get.isRegistered<AppointmentsRemoteDataSource>()) {
      Get.lazyPut<AppointmentsRemoteDataSource>(
        () => AppointmentsRemoteDataSource(
          dio: Get.find(),
          localStorage: Get.find(),
        ),
      );
    }

    // Repository
    Get.lazyPut<AppointmentsRepository>(
      () => AppointmentsRepositoryImpl(
        Get.find<AppointmentsRemoteDataSource>(),
        Get.find<NetworkInfo>(),
      ),
    );

    // UseCase
    Get.lazyPut<GetUpcomingAppointmentsUseCase>(
      () => GetUpcomingAppointmentsUseCase(Get.find<AppointmentsRepository>()),
    );

    // Controller
    Get.lazyPut<AppointmentReminderController>(
      () => AppointmentReminderController(
        getUpcomingAppointmentsUseCase:
            Get.find<GetUpcomingAppointmentsUseCase>(),
        clientsRemoteDataSource: Get.find<ClientsRemoteDataSource>(),
      ),
    );
  }
}
