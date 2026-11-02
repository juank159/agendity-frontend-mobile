import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_delivery.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_settings.dart';
import 'package:login_signup/features/reminders/domain/repositories/reminders_repository.dart';
import 'package:login_signup/features/reminders/domain/usecases/delete_reminder_rule_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/get_reminder_deliveries_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/get_reminder_rules_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/get_reminder_settings_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/preview_reminder_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/save_reminder_rule_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/update_reminder_settings_usecase.dart';
import 'package:login_signup/features/reminders/presentation/controllers/reminder_history_controller.dart';
import 'package:login_signup/features/reminders/presentation/controllers/reminders_controller.dart';
import 'package:login_signup/features/reminders/presentation/screens/reminder_history_screen.dart';
import 'package:login_signup/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:login_signup/features/reminders/presentation/widgets/reminder_ui.dart';

/// Repositorio falso: pantalla, controllers y use cases son los reales.
class FakeRemindersRepository implements RemindersRepository {
  ReminderSettings settings = const ReminderSettings(
      enabled: true,
      quota: MessageQuota(limit: 10, used: 3, period: '2026-10'));
  List<ReminderRule> rules = const [
    ReminderRule(
        id: 'r1', kind: ReminderKind.beforeAppointment, minutesBefore: 1440),
  ];
  Failure? getFailure;
  final savedRules = <ReminderRule>[];
  final deleted = <String>[];
  final previews = <(ReminderKind, String)>[];
  final queries = <DeliveriesQuery>[];
  List<ReminderDelivery> deliveries = const [];

  @override
  Future<Either<Failure, ReminderSettings>> getSettings() async =>
      getFailure != null ? Left(getFailure!) : Right(settings);

  @override
  Future<Either<Failure, ReminderSettings>> updateSettings(
      ReminderSettings next) async {
    settings = next;
    return Right(next);
  }

  @override
  Future<Either<Failure, List<ReminderRule>>> getRules() async => Right(rules);

  @override
  Future<Either<Failure, ReminderRule>> saveRule(ReminderRule rule) async {
    savedRules.add(rule);
    return Right(rule.id == null
        ? ReminderRule(
            id: 'new-${savedRules.length}',
            kind: rule.kind,
            minutesBefore: rule.minutesBefore,
            daysWithoutVisit: rule.daysWithoutVisit,
            sendTime: rule.sendTime,
            template: rule.template)
        : rule);
  }

  @override
  Future<Either<Failure, Unit>> deleteRule(String id) async {
    deleted.add(id);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, String>> preview(
      ReminderKind kind, String template) async {
    previews.add((kind, template));
    return const Right('Hola Ana, te esperamos mañana a las 10:00 a. m.');
  }

  @override
  Future<Either<Failure, List<ReminderDelivery>>> getDeliveries(
      DeliveriesQuery query) async {
    queries.add(query);
    return Right([
      for (final d in deliveries)
        if (query.status == null || d.status == query.status) d,
    ]);
  }
}

void main() {
  late FakeRemindersRepository repo;

  setUpAll(() => initializeDateFormatting('es'));
  setUp(() {
    Get.testMode = true;
    repo = FakeRemindersRepository();
  });
  tearDown(Get.reset);

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        GetMaterialApp(theme: ThemeConfig.lightTheme, home: home));
    await tester.pumpAndSettle();
  }

  RemindersController putController() => Get.put(RemindersController(
        getReminderSettingsUseCase: GetReminderSettingsUseCase(repo),
        updateReminderSettingsUseCase: UpdateReminderSettingsUseCase(repo),
        getReminderRulesUseCase: GetReminderRulesUseCase(repo),
        saveReminderRuleUseCase: SaveReminderRuleUseCase(repo),
        deleteReminderRuleUseCase: DeleteReminderRuleUseCase(repo),
        previewReminderUseCase: PreviewReminderUseCase(repo),
      ));

  Future<void> expireSnackbar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  group('Recordatorios', () {
    testWidgets('modo prueba, cupo y reglas por tipo', (tester) async {
      putController();
      await pump(tester, const RemindersScreen());

      expect(find.byKey(const Key('reminders-simulated')), findsOneWidget);
      expect(find.textContaining('Modo prueba'), findsOneWidget);
      expect(find.text('3 de 10 usados'), findsOneWidget);
      expect(find.byKey(const Key('reminders-quota-exhausted')), findsNothing);
      for (final kind in ReminderKind.values) {
        expect(find.text(kind.label), findsOneWidget);
      }
      expect(find.text('1 día antes'), findsOneWidget);
      expect(find.textContaining('mensaje aprobado de Agendity'), findsOneWidget);
    });

    testWidgets('cupo agotado: aviso', (tester) async {
      repo.settings = const ReminderSettings(
          channel: 'whatsapp_cloud',
          quota: MessageQuota(limit: 10, used: 10, period: '2026-10'));
      putController();
      await pump(tester, const RemindersScreen());
      expect(find.byKey(const Key('reminders-simulated')), findsNothing);
      expect(find.byKey(const Key('reminders-quota-exhausted')), findsOneWidget);
    });

    testWidgets('apagar los recordatorios', (tester) async {
      putController();
      await pump(tester, const RemindersScreen());
      await tester.tap(find.byKey(const Key('reminders-enabled')));
      await tester.pumpAndSettle();
      expect(repo.settings.enabled, isFalse);
      expect(find.text('Recordatorios apagados'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('nuevo "antes de la cita": 2 horas, vista previa y guardar',
        (tester) async {
      final c = putController();
      await pump(tester, const RemindersScreen());
      await tester.tap(find.byKey(const Key('reminder-add-before_appointment')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('reminder-amount')), '2');
      await tester.tap(find.text('días').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('horas').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('{cliente}'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('reminder-preview')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reminder-preview-text')), findsOneWidget);
      expect(repo.previews.single.$2, '{cliente}');

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final saved = repo.savedRules.single;
      expect(saved.minutesBefore, 120);
      expect(saved.template, '{cliente}');
      expect(c.rulesOf(ReminderKind.beforeAppointment), hasLength(2));
      expect(find.text('2 h antes'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('plantilla con una variable desconocida: aviso, no se guarda',
        (tester) async {
      putController();
      await pump(tester, const RemindersScreen());
      await tester.tap(find.byKey(const Key('reminder-add-birthday')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('reminder-template')), 'Hola {nombre}');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(repo.savedRules, isEmpty);
      expect(find.textContaining('Variables desconocidas'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('borrar pide confirmación', (tester) async {
      putController();
      await pump(tester, const RemindersScreen());
      await tester.tap(find.byTooltip('Borrar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Borrar este recordatorio?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repo.deleted, isEmpty);

      await tester.tap(find.byTooltip('Borrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
      await tester.pumpAndSettle();
      expect(repo.deleted, ['r1']);
      expect(find.text('1 día antes'), findsNothing);
      await expireSnackbar(tester);
    });

    testWidgets('12.05: hora de envío en 12 h y regla como tarjeta con estado',
        (tester) async {
      repo.rules = [
        ...repo.rules,
        const ReminderRule(
            id: 'b1',
            kind: ReminderKind.birthday,
            sendTime: '15:30',
            isActive: false),
      ];
      putController();
      await pump(tester, const RemindersScreen());
      // D-23: "A las 3:30 p. m.", nunca "15:30".
      expect(find.text('A las ${formatHhmm('15:30')}'), findsOneWidget);
      expect(find.textContaining('15:30'), findsNothing);
      expect(find.byKey(const Key('reminder-rule-b1')), findsOneWidget);
      expect(find.text('Desactivado'), findsOneWidget);
      expect(find.byIcon(Icons.alarm_off_rounded), findsOneWidget);
    });

    testWidgets('sin permiso (Employee): sin reintento', (tester) async {
      repo.getFailure = const ForbiddenFailure(message: 'Sin permiso');
      putController();
      await pump(tester, const RemindersScreen());
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    });
  });

  testWidgets('Historial: estado y motivo en lenguaje humano; filtro',
      (tester) async {
    repo.deliveries = [
      ReminderDelivery(
        id: 'd1',
        kind: ReminderKind.beforeAppointment,
        status: DeliveryStatus.skipped,
        reason: DeliveryReason.noConsent,
        phone: '+573001234567',
        createdAt: DateTime(2026, 10, 31, 9),
      ),
      ReminderDelivery(
        id: 'd2',
        kind: ReminderKind.birthday,
        status: DeliveryStatus.delivered,
        phone: '+573009998877',
        sentAt: DateTime(2026, 10, 31, 10),
      ),
    ];
    Get.put(ReminderHistoryController(
        getReminderDeliveriesUseCase: GetReminderDeliveriesUseCase(repo)));
    await pump(tester, const ReminderHistoryScreen());

    expect(find.text('No se envió'), findsWidgets);
    expect(find.text('El cliente no ha aceptado recibir mensajes por WhatsApp.'),
        findsOneWidget);
    expect(find.text('Entregado'), findsWidgets);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Entregado'));
    await tester.pumpAndSettle();
    expect(repo.queries.last.status, DeliveryStatus.delivered);
    expect(find.textContaining('no ha aceptado'), findsNothing);
  });

  test('textos de motivo y minutos', () {
    expect(deliveryReasonLabel(DeliveryReason.quota),
        contains('Se agotaron los mensajes'));
    expect(deliveryReasonLabel(DeliveryReason.tooLate), contains('horario'));
    expect(minutesBeforeLabel(30), '30 min antes');
    expect(minutesBeforeLabel(90), '1 h 30 min antes');
    expect(minutesBeforeLabel(2880), '2 días antes');
  });
}
