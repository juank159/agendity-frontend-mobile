import 'package:get/route_manager.dart';
import 'package:login_signup/features/auth/presentation/bindings/login_binding.dart';
import 'package:login_signup/features/auth/presentation/screen/screen.dart';

class GetRoutes {
  static const String splas = '/splas';
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';

  static List<GetPage> routes = [
    GetPage(name: GetRoutes.splas, page: () => const SplashView()),
    GetPage(
        name: GetRoutes.login,
        page: () => const LoginView(),
        binding: LoginBinding()),
    GetPage(name: GetRoutes.register, page: () => const RegisterView()),
    GetPage(name: GetRoutes.home, page: () => const HomeCalendarView()),
  ];
}
