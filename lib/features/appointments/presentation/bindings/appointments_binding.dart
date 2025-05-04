// lib/features/appointments/presentation/bindings/appointments_binding.dart
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:login_signup/core/network/network_info.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usescases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/delete_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_appointment_by_id_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_upcoming_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/update_appointment_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_reminder_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/services/data/datasources/services_remote_datasource.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class AppointmentsBinding implements Bindings {
  @override
  void dependencies() {
    // Registrar NetworkInfo si no existe
    if (!Get.isRegistered<NetworkInfo>()) {
      Get.put<NetworkInfo>(
        NetworkInfoImpl(connectionChecker: InternetConnectionChecker()),
      );
    }

    // Primero intentar registrar el EmployeesController si no existe
    _ensureEmployeesController();

    // Data Sources
    Get.lazyPut<AppointmentsRemoteDataSource>(
      () => AppointmentsRemoteDataSource(
        dio: Get.find(),
        localStorage: Get.find(),
      ),
    );

    Get.lazyPut<ServicesRemoteDataSource>(
      () => ServicesRemoteDataSource(
        dio: Get.find(),
        localStorage: Get.find(),
      ),
    );

    Get.lazyPut<ClientsRemoteDataSource>(
      () => ClientsRemoteDataSource(
        dio: Get.find(),
        localStorage: Get.find(),
      ),
    );

    // Repository
    Get.lazyPut<AppointmentsRepository>(
      () => AppointmentsRepositoryImpl(
        Get.find<AppointmentsRemoteDataSource>(),
        Get.find<NetworkInfo>(),
      ),
    );

    // Use Cases
    Get.lazyPut<GetAppointmentsUseCase>(
      () => GetAppointmentsUseCase(Get.find()),
    );
    Get.lazyPut<CreateAppointmentUseCase>(
      () => CreateAppointmentUseCase(Get.find()),
    );
    Get.lazyPut<UpdateAppointmentUseCase>(
      () => UpdateAppointmentUseCase(Get.find()),
    );
    Get.lazyPut<DeleteAppointmentUseCase>(
      () => DeleteAppointmentUseCase(Get.find()),
    );
    Get.lazyPut<GetAppointmentByIdUseCase>(
      () => GetAppointmentByIdUseCase(Get.find()),
    );

    // UseCase para citas próximas
    Get.lazyPut<GetUpcomingAppointmentsUseCase>(
      () => GetUpcomingAppointmentsUseCase(Get.find<AppointmentsRepository>()),
    );

    // Controller principal
    Get.lazyPut<AppointmentsController>(
      () => AppointmentsController(
        Get.find<GetAppointmentsUseCase>(),
        Get.find<CreateAppointmentUseCase>(),
        Get.find<UpdateAppointmentUseCase>(),
        Get.find<DeleteAppointmentUseCase>(),
        Get.find<ServicesRemoteDataSource>(),
        Get.find<ClientsRemoteDataSource>(),
        Get.find<LocalStorage>(),
        Get.find<AppointmentsRepository>(),
      ),
      fenix: true,
    );

    // Controlador para recordatorios si no existe
    if (!Get.isRegistered<AppointmentReminderController>()) {
      Get.lazyPut<AppointmentReminderController>(
        () => AppointmentReminderController(
          getUpcomingAppointmentsUseCase:
              Get.find<GetUpcomingAppointmentsUseCase>(),
          clientsRemoteDataSource: Get.find<ClientsRemoteDataSource>(),
        ),
      );
    }
  }

  void _ensureEmployeesController() {
    if (!Get.isRegistered<EmployeesController>()) {
      try {
        Get.put(EmployeesController(), permanent: false);
        print('EmployeesController registrado desde AppointmentsBinding');
      } catch (e) {
        print('Error al registrar EmployeesController: $e');
      }
    }
  }
}
