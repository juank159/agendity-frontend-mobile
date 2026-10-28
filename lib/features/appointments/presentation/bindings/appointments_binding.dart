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
import 'package:login_signup/features/clients/domain/usecases/get_all_clients_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/get_clients_page_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';
import 'package:login_signup/features/payments/domain/usecases/create_payment_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_active_custom_payment_methods_usecase.dart';
import 'package:login_signup/features/payments/presentation/controllers/payment_controller.dart';

class AppointmentsBinding implements Bindings {
  @override
  void dependencies() {
    // Registrar NetworkInfo si no existe
    if (!Get.isRegistered<NetworkInfo>()) {
      Get.put<NetworkInfo>(
        NetworkInfoImpl(connectionChecker: InternetConnectionChecker()),
      );
    }

    // Data Sources
    Get.lazyPut<AppointmentsRemoteDataSource>(
      () => AppointmentsRemoteDataSource(
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
    // Diálogo "Registrar pago" (se abre desde el detalle de la cita).
    Get.lazyPut<PaymentController>(
      () => PaymentController(
        createPaymentUseCase: Get.find<CreatePaymentUseCase>(),
        getActiveCustomPaymentMethodsUseCase:
            Get.find<GetActiveCustomPaymentMethodsUseCase>(),
      ),
      fenix: true,
    );
    Get.lazyPut<AppointmentsController>(
      () => AppointmentsController(
        Get.find<GetAppointmentsUseCase>(),
        Get.find<CreateAppointmentUseCase>(),
        Get.find<UpdateAppointmentUseCase>(),
        Get.find<DeleteAppointmentUseCase>(),
        Get.find<GetServicesUseCase>(),
        Get.find<GetClientsPageUseCase>(),
        Get.find<LocalStorage>(),
        Get.find<AppointmentsRepository>(),
        getProfessionalsUseCase: Get.find<GetEmployeesUseCase>(),
        getProfessionalByIdUseCase: Get.find<GetEmployeeByIdUseCase>(),
      ),
      fenix: true,
    );

    // Controlador para recordatorios si no existe
    if (!Get.isRegistered<AppointmentReminderController>()) {
      Get.lazyPut<AppointmentReminderController>(
        () => AppointmentReminderController(
          getUpcomingAppointmentsUseCase:
              Get.find<GetUpcomingAppointmentsUseCase>(),
          getAllClientsUseCase: Get.find<GetAllClientsUseCase>(),
        ),
      );
    }
  }
}
