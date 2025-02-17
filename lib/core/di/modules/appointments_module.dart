// appointments_module.dart
import 'package:get/get.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/features/appointments/domain/usescases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/delete_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_appointment_by_id_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/update_appointment_usecase.dart';
import 'package:login_signup/features/appointments/presentation/bindings/appointments_binding.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class AppointmentsModule {
  static Future<void> init() async {
    // Asegurarse de que localStorage esté disponible
    if (!Get.isRegistered<LocalStorage>()) {
      throw Exception('LocalStorage not initialized');
    }

    // Registrar dependencias base
    final remoteDataSource = AppointmentsRemoteDataSource(
      dio: Get.find(),
      localStorage: Get.find(),
    );
    final repository = AppointmentsRepositoryImpl(remoteDataSource);

    // Registrar casos de uso
    Get.put(GetAppointmentsUseCase(repository));
    Get.put(CreateAppointmentUseCase(repository));
    Get.put(UpdateAppointmentUseCase(repository));
    Get.put(DeleteAppointmentUseCase(repository));
    Get.put(GetAppointmentByIdUseCase(repository));

    // Registrar el Binding
    Get.lazyPut(() => AppointmentsBinding());
  }
}
