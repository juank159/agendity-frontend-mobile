import 'package:get/get.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usescases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/delete_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_appointment_by_id_usecase.dart';

import 'package:login_signup/features/appointments/domain/usescases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/update_appointment_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/services/data/datasources/services_remote_datasource.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

// appointments_binding.dart
class AppointmentsBinding implements Bindings {
  @override
  void dependencies() {
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
      () => AppointmentsRepositoryImpl(Get.find()),
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

    // Controller
    Get.lazyPut<AppointmentsController>(
      () => AppointmentsController(
        Get.find<GetAppointmentsUseCase>(),
        Get.find<CreateAppointmentUseCase>(),
        Get.find<UpdateAppointmentUseCase>(),
        Get.find<DeleteAppointmentUseCase>(),
        Get.find<ServicesRemoteDataSource>(),
        Get.find<ClientsRemoteDataSource>(),
        Get.find<LocalStorage>(),
      ),
    );
  }
}
