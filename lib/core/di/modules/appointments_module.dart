import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_appointments_usecase.dart';
import '../../../features/appointments/data/datasources/appointments_remote_datasource.dart';
import '../../../features/appointments/data/repositories/appointments_repository_impl.dart';
import '../../../features/appointments/presentation/controllers/calendar_controller.dart';
import '../../../shared/local_storage/local_storage.dart';

class AppointmentsModule {
  static Future<void> init() async {
    final dio = Get.find<Dio>();
    final localStorage = Get.find<LocalStorage>();

    // Register dependencies
    final remoteDataSource = AppointmentsRemoteDataSource(
      dio: dio,
      localStorage: localStorage,
    );

    final repository = AppointmentsRepositoryImpl(remoteDataSource);
    final getAppointmentsUseCase = GetAppointmentsUseCase(repository);

    // Register the controller with its dependencies
    Get.lazyPut<CalendarController>(
      () => CalendarController(getAppointmentsUseCase),
      fenix: true,
    );
  }
}
