import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/features/whatsapp/domain/entities/whatsapp_config.dart';
import 'package:login_signup/features/whatsapp/domain/repositories/whatsapp_repository.dart';
import 'package:login_signup/features/whatsapp/domain/usecases/get_whatsapp_config_usecase.dart';
import 'package:login_signup/features/whatsapp/domain/usecases/save_whatsapp_config_usecase.dart';
import 'package:login_signup/features/whatsapp/domain/usecases/send_test_message_usecase.dart';
import 'package:login_signup/features/whatsapp/presentation/controllers/whatsapp_controller.dart';
import 'package:login_signup/features/whatsapp/presentation/screens/whatsapp_config_screen.dart';

/// Repositorio falso: la pantalla y el controller son los reales.
class FakeWhatsappRepository implements WhatsappRepository {
  Completer<Either<Failure, WhatsappConfig?>>? pendingGet;
  Either<Failure, WhatsappConfig?> getResult = const Right(null);
  Either<Failure, bool> testResult = const Right(true);
  final saved = <WhatsappConfig>[];

  @override
  Future<Either<Failure, WhatsappConfig?>> getConfig() =>
      pendingGet?.future ?? Future.value(getResult);

  @override
  Future<Either<Failure, WhatsappConfig>> saveConfig(
      WhatsappConfig config) async {
    saved.add(config);
    return Right(config.copyWith(id: 'cfg-1'));
  }

  @override
  Future<Either<Failure, bool>> sendTestMessage() async => testResult;
}

const existing = WhatsappConfig(
  id: 'cfg-1',
  phoneNumber: '573001234567',
  apiKey: 'k-123',
  isEnabled: true,
);

void main() {
  late FakeWhatsappRepository repo;

  setUp(() {
    Get.testMode = true;
    repo = FakeWhatsappRepository();
  });
  tearDown(Get.reset);

  Future<void> pumpScreen(WidgetTester tester, {bool settle = true}) async {
    Get.put(WhatsappController(
      getWhatsappConfigUseCase: GetWhatsappConfigUseCase(repo),
      saveWhatsappConfigUseCase: SaveWhatsappConfigUseCase(repo),
      sendTestMessageUseCase: SendTestMessageUseCase(repo),
    ));
    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeConfig.lightTheme,
      home: const WhatsappConfigScreen(),
    ));
    if (settle) await tester.pumpAndSettle();
  }

  /// Desplaza hasta el botón (la pantalla de test mide 800×600) y lo pulsa.
  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> expireSnackbar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('cargando → LoadingState', (tester) async {
    repo.pendingGet = Completer();
    await pumpScreen(tester, settle: false);
    await tester.pump();
    expect(find.byType(LoadingState), findsOneWidget);
    repo.pendingGet!.complete(const Right(null));
    await tester.pumpAndSettle();
    expect(find.byType(LoadingState), findsNothing);
  });

  testWidgets('sin configuración → formulario vacío, no un error',
      (tester) async {
    await pumpScreen(tester);
    expect(find.byType(ErrorState), findsNothing);
    expect(find.text('Guardar configuración'), findsOneWidget);
    expect(find.text('Cómo conectar tu WhatsApp:'), findsOneWidget);
    final phone =
        tester.widget<TextField>(find.byKey(const Key('whatsapp-phone')));
    expect(phone.controller!.text, isEmpty);
    expect(find.text('Cancelar'), findsNothing);
  });

  testWidgets('sin configuración: guardar con +57 y pasar al resumen',
      (tester) async {
    await pumpScreen(tester);
    await tester.enterText(
        find.byKey(const Key('whatsapp-phone')), '300 123 4567');
    await tester.enterText(find.byKey(const Key('whatsapp-apikey')), ' k-9 ');
    await tapText(tester, 'Guardar configuración');

    expect(repo.saved.single,
        const WhatsappConfig(phoneNumber: '573001234567', apiKey: 'k-9'));
    expect(find.text('Configuración actual'), findsOneWidget);
    expect(find.text('Configuración guardada'), findsOneWidget);
    await expireSnackbar(tester);
  });

  testWidgets('número inválido: avisa y no guarda', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byKey(const Key('whatsapp-phone')), '300');
    await tester.enterText(find.byKey(const Key('whatsapp-apikey')), 'k');
    await tapText(tester, 'Guardar configuración');
    expect(repo.saved, isEmpty);
    expect(find.textContaining('celular de 10 dígitos'), findsOneWidget);
    await expireSnackbar(tester);
  });

  testWidgets('con configuración → resumen sin mostrar la API Key',
      (tester) async {
    repo.getResult = const Right(existing);
    await pumpScreen(tester);
    expect(find.text('+57 3001234567'), findsOneWidget);
    expect(find.text('Activado'), findsOneWidget);
    expect(find.text('k-123'), findsNothing);
    expect(find.text('Guardar configuración'), findsNothing);

    await tapText(tester, 'Editar');
    final phone =
        tester.widget<TextField>(find.byKey(const Key('whatsapp-phone')));
    expect(phone.controller!.text, '3001234567');
    await tapText(tester, 'Cancelar');
    expect(find.text('Configuración actual'), findsOneWidget);
  });

  testWidgets('con configuración: desactivar pide confirmación',
      (tester) async {
    repo.getResult = const Right(existing);
    await pumpScreen(tester);
    await tapText(tester, 'Desactivar avisos');
    expect(find.text('¿Desactivar avisos?'), findsOneWidget);
    await tapText(tester, 'Desactivar');
    expect(repo.saved.single.isEnabled, isFalse);
    expect(find.text('Desactivado'), findsOneWidget);
    await expireSnackbar(tester);
  });

  testWidgets('prueba rechazada por CallMeBot → aviso', (tester) async {
    repo.getResult = const Right(existing);
    repo.testResult = const Right(false);
    await pumpScreen(tester);
    await tapText(tester, 'Enviar prueba');
    expect(find.text('No se envió la prueba'), findsOneWidget);
    await expireSnackbar(tester);
  });

  testWidgets('error de red → ErrorState que reintenta', (tester) async {
    repo.getResult = const Left(NetworkFailure(message: 'Sin conexión a internet'));
    await pumpScreen(tester);
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Sin conexión a internet'), findsOneWidget);

    repo.getResult = const Right(existing);
    await tapText(tester, 'Reintentar');
    expect(find.text('Configuración actual'), findsOneWidget);
  });

  testWidgets('Forbidden (Employee) → mensaje claro y sin reintento',
      (tester) async {
    repo.getResult = const Left(ForbiddenFailure(message: 'Forbidden resource'));
    await pumpScreen(tester);
    expect(find.text('Sin acceso'), findsOneWidget);
    expect(find.textContaining('Solo el propietario'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  test('números: nacional ↔ formato de CallMeBot', () {
    expect(WhatsappController.fullPhoneNumber('300-123-4567'), '573001234567');
    expect(WhatsappController.fullPhoneNumber('+57 300 123 4567'),
        '573001234567');
    expect(WhatsappController.fullPhoneNumber('12345'), isNull);
    expect(WhatsappController.nationalPhoneNumber('573001234567'),
        '3001234567');
    expect(WhatsappController.nationalPhoneNumber('3001234567'), '3001234567');
  });
}
