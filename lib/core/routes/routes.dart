import 'package:get/route_manager.dart';
import 'package:login_signup/features/auth/presentation/bindings/login_binding.dart';
import 'package:login_signup/features/auth/presentation/screen/screen.dart';
import 'package:login_signup/features/services/presentation/bindings/services_binding.dart';
import 'package:login_signup/features/services/presentation/bindings/new_service_binding.dart';
import 'package:login_signup/features/services/presentation/screen/services_screen.dart';
import 'package:login_signup/features/services/presentation/screen/new_service_screen.dart';

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
  static const String categories = '/categories';

  static List<GetPage> routes = [
    // Auth Pages
    GetPage(name: splas, page: () => const SplashView()),
    GetPage(
      name: login,
      page: () => const LoginView(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(name: register, page: () => const RegisterView()),

    // Main Pages
    GetPage(name: home, page: () => const HomeCalendarView()),

    // Service Pages
    GetPage(
      name: services,
      page: () => const ServicesScreen(),
      binding: ServicesBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: addService,
      page: () => const NewServiceScreen(),
      binding: NewServiceBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
  ];
}
