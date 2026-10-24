import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/shared/controller/session_controller.dart';

/// Datos del usuario para la UI (drawer, permisos por rol).
///
/// Ya no decodifica el JWT: refleja [SessionController] y se actualiza solo
/// cuando cambia la sesión (login, logout, sesión vencida).
class UserInfoController extends GetxController {
  final SessionController _session;

  final userName = ''.obs;
  final userEmail = ''.obs;
  final userInitial = ''.obs;
  final userRoles = <String>[].obs;

  Worker? _sessionWorker;

  UserInfoController({SessionController? session})
      : _session = session ?? Get.find<SessionController>();

  @override
  void onInit() {
    super.onInit();
    _apply(_session.session.value);
    _sessionWorker = ever<Session?>(_session.session, _apply);
  }

  @override
  void onClose() {
    _sessionWorker?.dispose();
    super.onClose();
  }

  void _apply(Session? session) {
    final name = session?.name;
    userName.value = name ?? 'Usuario';
    userEmail.value = session?.email ?? '';
    userInitial.value =
        name != null && name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
    userRoles.assignAll(session?.roles ?? const []);
  }

  bool hasRole(String role) => userRoles.contains(role);

  /// Employee que no es Owner.
  bool isOnlyEmployee() => _session.isOnlyEmployee;

  bool isOwner() => _session.isOwner;

  /// Employee (incluye al Owner que también tiene ese rol).
  bool isEmployee() => hasRole(SessionRole.employee);

  String getStatisticsRoute() =>
      isOnlyEmployee() ? GetRoutes.employeeStats : GetRoutes.statistics;

  /// Compatibilidad: vuelve a leer la sesión vigente.
  Future<void> loadUserInfo() async => _session.reload();

  Future<void> refreshUserInfo() => loadUserInfo();

  /// Compatibilidad: el estado se limpia al cerrar la sesión en
  /// [SessionController]; aquí solo se refleja.
  void clearUserInfo() => _apply(null);
}
