import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'package:login_signup/features/appointments/presentation/bindings/appointments_binding.dart';
import 'package:login_signup/features/appointments/presentation/view/appointments_view.dart';

import 'package:login_signup/features/auth/presentation/bindings/login_binding.dart';
import 'package:login_signup/features/auth/presentation/screen/screen.dart';

import 'package:login_signup/features/clients/presentation/bindings/clients_binding.dart';
import 'package:login_signup/features/clients/presentation/screen/clients_screen.dart';
import 'package:login_signup/features/clients/presentation/screen/edit_client_screen.dart';

import 'package:login_signup/features/employees/presentation/bindings/employees_binding.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/employees/presentation/screens/create_employee_screen.dart';
import 'package:login_signup/features/employees/presentation/screens/employees_list_screen.dart';

import 'package:login_signup/features/services/presentation/bindings/categories_binding.dart';
import 'package:login_signup/features/services/presentation/bindings/edit_service_binding.dart';
import 'package:login_signup/features/services/presentation/bindings/new_category_binding.dart';
import 'package:login_signup/features/services/presentation/bindings/services_binding.dart';
import 'package:login_signup/features/services/presentation/bindings/new_service_binding.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';
import 'package:login_signup/features/services/presentation/screen/categories_screen.dart';
import 'package:login_signup/features/services/presentation/screen/edit_service_screen.dart';
import 'package:login_signup/features/services/presentation/screen/new_category_screen.dart';
import 'package:login_signup/features/services/presentation/screen/services_screen.dart';
import 'package:login_signup/features/services/presentation/screen/new_service_screen.dart';
import 'package:login_signup/features/statistics/presentation/bindings/statistics_binding.dart';
import 'package:login_signup/features/statistics/presentation/screens/statistics_dashboard_screen.dart';

class GetRoutes {
  // Auth Routes
  static const String splas = '/splas';
  static const String login = '/login';
  static const String register = '/register';

  // Main Routes
  static const String home = '/';

  // Service Routes
  static const String services = '/services';
  static const String addService = '/services/new';
  static const String editService = '/services/edit';

  // Categories Routes
  static const String categories = '/categories';
  static const String addCategory = '/categories/new';
  static const String editCategory = '/categories/edit/:id';

  //Clients Routes
  static const String clients = '/clients';
  static const String addClient = '/clients/new';
  static const String editClient = '/clients/edit/:id';

  //Calendar Routes
  static const String calendar = '/calendar';
  static const String calendarEvent = '/calendar/event';

  // employees Routes
  static const String employees = '/employees';
  static const String addEmployee = '/employees/new';
  static const String editEmployee = '/employees/edit/:id';

  // statistics Routes
  static const String statistics = '/statistics';

  static List<GetPage> routes = [
    // Auth Pages
    GetPage(
      name: splas,
      page: () => const SplashView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: login,
      page: () => const LoginView(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: register,
      page: () => const RegisterView(),
      transition: Transition.fadeIn,
    ),

    // Main Pages
    GetPage(
      name: home,
      page: () => AppointmentsView(),
      binding: AppointmentsBinding(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),

    // Service Pages
    GetPage(
      name: services,
      page: () => const ServicesScreen(),
      binding: ServicesBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: addService,
      page: () => const NewServiceScreen(),
      binding: NewServiceBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: editService,
      page: () => const EditServiceScreen(),
      binding: EditServiceBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
      middlewares: [AuthMiddleware()],
    ),

    // Categories Pages
    GetPage(
      name: categories,
      page: () => const CategoriesScreen(),
      binding: CategoriesBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
      fullscreenDialog: true,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: addCategory,
      page: () => const NewCategoryScreen(),
      binding: NewCategoryBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
      middlewares: [AuthMiddleware()],
    ),

    // Client Pages
    GetPage(
      name: clients,
      page: () => ClientsScreen(), // Removido el const
      binding: ClientsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: editClient,
      page: () => const EditClientScreen(),
      binding: ClientsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
      middlewares: [AuthMiddleware()],
    ),

    // employees Pages
    GetPage(
      name: employees,
      page: () => const EmployeesListScreen(),
      binding: EmployeesBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: addEmployee,
      page: () => const CreateEmployeeScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ServicesController>()) {
          Get.put(
            ServicesController(getServicesUseCase: Get.find()),
            permanent: true,
          );
        }
        Get.lazyPut(() => EmployeesController(
              getEmployeesUseCase: Get.find(),
              getEmployeeByIdUseCase: Get.find(),
              createEmployeeUseCase: Get.find(),
            ));
      }),
    ),

    // statistics Pages
    GetPage(
      name: statistics,
      page: () => const StatisticsDashboardScreen(),
      binding: StatisticsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
      middlewares: [AuthMiddleware()],
    ),
  ];
}

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Nota: eliminamos async/await y manejamos la promesa diferente
    try {
      final storage = Get.find<FlutterSecureStorage>();
      final token = storage.read(key: 'token');
      if (token == null) {
        return const RouteSettings(name: GetRoutes.login);
      }
      return null;
    } catch (e) {
      print('Error en middleware de autenticación: $e');
      return const RouteSettings(name: GetRoutes.login);
    }
  }
}
