import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/middlewares/auth_middleware.dart';
import 'package:login_signup/core/routes/middlewares/role_middleware.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/features/appointments/presentation/bindings/appointment_reminder_binding.dart';

import 'package:login_signup/features/appointments/presentation/bindings/appointments_binding.dart';
import 'package:login_signup/features/appointments/presentation/bindings/reschedule_list_binding.dart';
import 'package:login_signup/features/appointments/presentation/screens/appointments_view.dart';
import 'package:login_signup/features/appointments/presentation/screens/reschedule_list_screen.dart';
import 'package:login_signup/features/appointments/presentation/screens/upcoming_appointments_screen.dart';

import 'package:login_signup/features/auth/presentation/bindings/email_verification_binding.dart';
import 'package:login_signup/features/auth/presentation/bindings/forgot_password_binding.dart';

import 'package:login_signup/features/auth/presentation/bindings/login_binding.dart';
import 'package:login_signup/features/auth/presentation/bindings/register_binding.dart';
import 'package:login_signup/features/auth/presentation/bindings/reset_password_binding.dart';

import 'package:login_signup/features/auth/presentation/screens/email_verification_view.dart';
import 'package:login_signup/features/auth/presentation/screens/forgot_password_view.dart';
import 'package:login_signup/features/auth/presentation/screens/reset_password_view.dart';
import 'package:login_signup/features/auth/presentation/screens/screen.dart';

import 'package:login_signup/features/clients/presentation/bindings/clients_binding.dart';
import 'package:login_signup/features/clients/presentation/screens/clients_screen.dart';
import 'package:login_signup/features/clients/presentation/screens/edit_client_screen.dart';
import 'package:login_signup/features/clients/presentation/screens/new_client_screen.dart';

import 'package:login_signup/features/employees/presentation/bindings/employees_binding.dart';
import 'package:login_signup/features/employees/presentation/bindings/verify_employee_email_binding.dart';
import 'package:login_signup/features/employees/presentation/screens/create_employee_screen.dart';
import 'package:login_signup/features/employees/presentation/screens/edit_employee_screen.dart';
import 'package:login_signup/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:login_signup/features/employees/presentation/screens/employees_list_screen.dart';
import 'package:login_signup/features/employees/presentation/screens/verify_employee_email_screen.dart';

import 'package:login_signup/features/payments/presentation/bindings/payments_review_binding.dart';
import 'package:login_signup/features/payments/presentation/screens/payments_review_screen.dart';
import 'package:login_signup/features/services/presentation/bindings/categories_binding.dart';
import 'package:login_signup/features/services/presentation/bindings/edit_service_binding.dart';
import 'package:login_signup/features/services/presentation/bindings/new_category_binding.dart';
import 'package:login_signup/features/services/presentation/bindings/services_binding.dart';
import 'package:login_signup/features/services/presentation/bindings/new_service_binding.dart';
import 'package:login_signup/features/services/presentation/screens/categories_screen.dart';
import 'package:login_signup/features/services/presentation/screens/edit_service_screen.dart';
import 'package:login_signup/features/services/presentation/screens/new_category_screen.dart';
import 'package:login_signup/features/services/presentation/screens/services_screen.dart';
import 'package:login_signup/features/services/presentation/screens/new_service_screen.dart';
import 'package:login_signup/features/settings/presentation/bindings/business_settings_binding.dart';
import 'package:login_signup/features/settings/presentation/screens/business_settings_screen.dart';
import 'package:login_signup/features/statistics/presentation/bindings/statistics_binding.dart';
import 'package:login_signup/features/statistics/presentation/screens/commissions_screen.dart';
import 'package:login_signup/features/statistics/presentation/screens/employee_stats_screen.dart';
import 'package:login_signup/features/statistics/presentation/screens/statistics_dashboard_screen.dart';
import 'package:login_signup/features/subscriptions/presentation/bindings/subscription_binding.dart';
import 'package:login_signup/features/subscriptions/presentation/screens/payment_success_screen.dart';
import 'package:login_signup/features/subscriptions/presentation/screens/payment_webview_screen.dart';
import 'package:login_signup/features/subscriptions/presentation/screens/subscription_plans_screen.dart';
import 'package:login_signup/features/theme/presentation/screens/theme_settings_screen.dart';
import 'package:login_signup/features/whatsapp/presentation/bindings/whatsapp_binding.dart';
import 'package:login_signup/features/whatsapp/presentation/screens/whatsapp_config_screen.dart';
import 'package:login_signup/shared/screens/sync_pending_screen.dart';

class GetRoutes {
  // Auth Routes
  static const String splas = '/splas';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Main Routes
  static const String home = '/';

  // Service Routes
  static const String services = '/services';
  static const String addService = '/services/new';
  static const String editService = '/services/edit';

  // Categories Routes
  static const String categories = '/categories';
  static const String addCategory = '/categories/new';

  //Clients Routes
  static const String clients = '/clients';
  static const String addClient = '/clients/new';
  static const String editClient = '/clients/edit';

  // employees Routes
  static const String employees = '/employees';
  static const String addEmployee = '/employees/new';
  static const String verifyEmployeeEmail = '/verify-employee-email';
  static const String employeeDetails = '/employee-details';

  /// Edición; el id va en `arguments['employeeId']` (como `editClient`).
  static const String employeeEdit = '/employees/edit';

  // statistics Routes
  static const String statistics = '/statistics';
  static const String employeeStats = '/employee-statistics';

  /// Liquidación de comisiones (Owner: el equipo; Employee: lo suyo).
  static const String commissions = '/commissions';

  // config whatsapp Routes
  static const String configWhatsapp = '/whatsapp-config';

  // notifications Routes
  static const String notifications = '/notifications';

  // theme Routes
  static const String themeSettings = '/theme-settings';

  // Configuración del negocio (zona horaria, D-15). Solo Owner.
  static const String businessSettings = '/business-settings';

  // subscription Routes
  static const String subscriptionPlans = '/subscription-plans';
  static const String paymentWebview = '/payment-webview';
  static const String paymentSuccess = '/payment-success';

  /// Citas guardadas con conflicto al sincronizar (10.03).
  static const String appointmentsToReschedule = '/appointments/to-reschedule';

  /// Pagos en revisión tras sincronizar (10.03, solo Owner).
  static const String paymentsReview = '/payments/review';

  /// Cambios sin enviar y los que esperan al usuario (10.03).
  static const String syncPending = '/sync-pending';

  // Ruta desconocida (GetMaterialApp.unknownRoute)
  static const String notFound = '/not-found';

  static final GetPage unknownRoute = GetPage(
    name: notFound,
    page: () => Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: ErrorState(
        title: 'Página no encontrada',
        message: 'La pantalla que buscas no existe o ya no está disponible.',
        icon: Icons.explore_off_outlined,
        actionLabel: 'Volver al inicio',
        actionIcon: Icons.home_outlined,
        onRetry: () => Get.offAllNamed(home),
      ),
    ),
  );

  static List<GetPage> routes = [
    // Auth Pages
    GetPage(
        name: splas,
        page: () => const SplashView(),
        transition: Transition.noTransition),
    GetPage(
      name: login,
      page: () => const LoginView(),
      binding: LoginBinding(),
      //preventDuplicates: true, // Agregar esto
      transition: Transition.noTransition, // Cambiar a noTransition
    ),
    GetPage(
      name: register,
      page: () => const RegisterView(),
      binding: RegisterBinding(), // Añadido el binding
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: verifyEmail,
      page: () => const EmailVerificationView(),
      binding: EmailVerificationBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: resetPassword,
      page: () => const ResetPasswordView(),
      binding: ResetPasswordBinding(),
      transition: Transition.fadeIn,
    ),

    // Theme Settings Page
    GetPage(
      name: themeSettings,
      page: () => const ThemeSettingsScreen(),
      transition: Transition.rightToLeft,
    ),

    // Main Pages
    GetPage(
      name: home,
      middlewares: [AuthMiddleware()],
      page: () => const AppointmentsView(),
      binding: AppointmentsBinding(),
      transition: Transition.fadeIn,
    ),

    // Service Pages
    GetPage(
      name: services,
      middlewares: [AuthMiddleware()],
      page: () => const ServicesScreen(),
      binding: ServicesBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),
    GetPage(
      name: addService,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const NewServiceScreen(),
      binding: NewServiceBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),
    GetPage(
      name: editService,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const EditServiceScreen(),
      binding: EditServiceBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),

    // Categories Pages
    GetPage(
      name: categories,
      middlewares: [AuthMiddleware()],
      page: () => const CategoriesScreen(),
      binding: CategoriesBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
      fullscreenDialog: true,
    ),
    GetPage(
      name: addCategory,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const NewCategoryScreen(),
      binding: NewCategoryBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),

    // Client Pages
    GetPage(
      name: clients,
      middlewares: [AuthMiddleware()],
      page: () => const ClientsScreen(),
      binding: ClientsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),
    GetPage(
      name: editClient,
      middlewares: [AuthMiddleware()],
      page: () => const EditClientScreen(),
      binding: EditClientBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),
    GetPage(
      name: addClient,
      middlewares: [AuthMiddleware()],
      page: () => const NewClientScreen(),
      binding: NewClientBinding(),
    ),

    // employees Pages

    GetPage(
      name: employees,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const EmployeesListScreen(),
      binding: EmployeesBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: addEmployee,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const CreateEmployeeScreen(),
      binding: NewEmployeeBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: verifyEmployeeEmail,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const VerifyEmployeeEmailScreen(),
      binding: VerifyEmployeeEmailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: employeeDetails,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const EmployeeDetailsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: employeeEdit,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const EditEmployeeScreen(),
      binding: EditEmployeeBinding(),
      transition: Transition.rightToLeft,
    ),

    // statistics Pages
    GetPage(
      name: statistics,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const StatisticsDashboardScreen(),
      binding: StatisticsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),
    GetPage(
      name: commissions,
      middlewares: [AuthMiddleware()],
      page: () => const CommissionsScreen(),
      binding: CommissionsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),
    GetPage(
      name: employeeStats,
      middlewares: [AuthMiddleware()],
      page: () => const EmployeeStatsScreen(),
      binding: EmployeeStatsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),

    // Config Whatsapp Pages
    GetPage(
      name: configWhatsapp,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const WhatsappConfigScreen(),
      binding: WhatsappBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),

    // Business Settings Page
    GetPage(
      name: businessSettings,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const BusinessSettingsScreen(),
      binding: BusinessSettingsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),

    GetPage(
      name: appointmentsToReschedule,
      middlewares: [AuthMiddleware()],
      page: () => const RescheduleListScreen(),
      binding: RescheduleListBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
    ),
    GetPage(
      name: paymentsReview,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const PaymentsReviewScreen(),
      binding: PaymentsReviewBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
    ),
    GetPage(
      name: syncPending,
      middlewares: [AuthMiddleware()],
      page: () => const SyncPendingScreen(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
    ),

    // Notifications Pages
    GetPage(
      name: notifications,
      middlewares: [AuthMiddleware()],
      page: () => const UpcomingAppointmentsScreen(),
      binding: AppointmentReminderBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),

    // Subscription Pages
    GetPage(
      name: subscriptionPlans,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const SubscriptionPlansScreen(),
      binding: SubscriptionBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),
    GetPage(
      name: paymentWebview,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const PaymentWebViewScreen(),
      binding: SubscriptionBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      preventDuplicates: true,
    ),
    GetPage(
      name: paymentSuccess,
      middlewares: RoleMiddleware.ownerOnly(),
      page: () => const PaymentSuccessScreen(),
      transition: Transition.fadeIn,
    ),
  ];
}
