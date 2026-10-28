import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/features/auth/presentation/controllers/user_info_controller.dart';
import 'package:login_signup/features/theme/presentation/screens/theme_settings_screen.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/controllers/theme_controller.dart';
import 'package:login_signup/shared/custom_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/session/memory_token_store.dart';

void main() {
  const notImplemented = [
    'Buscar',
    'Mensajes',
    'Gastos',
    'Reserva Online',
    'Formularios',
    'Enviar opiniones',
  ];
  const ownerOnly = ['Personal', 'WhatsApp', 'Planes y suscripción'];
  const forEveryone = [
    'Servicios',
    'Clientela',
    'Informes',
    'Apariencia',
    'Cerrar sesión',
  ];

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> openDrawer(WidgetTester tester, String role,
      {ThemeData? theme}) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = MemoryTokenStore();
    final session = SessionController(SessionService(
      tokenStore: store,
      repository: SessionRepository(store),
    ));
    session.session.value = Session(
        token: 't-$role',
        userId: 'u1',
        name: 'Ana',
        email: 'ana@negocio.co',
        roles: [role]);
    Get.put<SessionController>(session, permanent: true);
    Get.put(UserInfoController(), permanent: true);
    Get.put(ThemeController(), permanent: true);

    await tester.pumpWidget(GetMaterialApp(
      theme: theme ?? ThemeConfig.lightTheme,
      getPages: [
        GetPage(
          name: GetRoutes.themeSettings,
          page: () => const ThemeSettingsScreen(),
        ),
      ],
      home: Scaffold(
        key: scaffoldKey,
        drawer: const CustomDrawer(),
        body: const SizedBox(),
      ),
    ));
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();
  }

  testWidgets('Owner: entradas reales, ninguna sin implementar',
      (tester) async {
    await openDrawer(tester, SessionRole.owner);

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('PROPIETARIO'), findsOneWidget);
    for (final title in [...forEveryone, ...ownerOnly]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    for (final title in notImplemented) {
      expect(find.text(title), findsNothing, reason: title);
    }
  });

  testWidgets('Employee: sin las entradas del Owner', (tester) async {
    await openDrawer(tester, SessionRole.employee);

    expect(find.text('EMPLEADO'), findsOneWidget);
    for (final title in forEveryone) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    for (final title in [...ownerOnly, ...notImplemented]) {
      expect(find.text(title), findsNothing, reason: title);
    }
  });

  testWidgets('Apariencia abre la pantalla de tema (también en oscuro)',
      (tester) async {
    await openDrawer(tester, SessionRole.employee,
        theme: ThemeConfig.darkTheme);

    await tester.tap(find.text('Apariencia'));
    await tester.pumpAndSettle();

    expect(find.byType(ThemeSettingsScreen), findsOneWidget);
    expect(find.text('Tema oscuro'), findsOneWidget);
    expect(find.text('Tema del sistema'), findsOneWidget);
  });
}
