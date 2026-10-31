import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/services/notification_service.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_changes.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/entities/manual_reminder.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usecases/cancel_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/complete_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_to_reschedule_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_available_slots_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_upcoming_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/mark_reminder_sent_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/prepare_reminder_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/update_appointment_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_actions_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_reminder_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/features/appointments/presentation/controllers/reschedule_list_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/sync_attention_controller.dart';
import 'package:login_signup/features/appointments/presentation/screens/appointments_view.dart';
import 'package:login_signup/features/appointments/presentation/screens/reschedule_list_screen.dart';
import 'package:login_signup/features/appointments/presentation/screens/upcoming_appointments_screen.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_calendar_data_source.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_detail_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_form_dialog.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/clients/domain/entities/paginated_list.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';
import 'package:login_signup/features/clients/domain/usecases/get_clients_page_usecase.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/notifications/domain/entities/app_notification.dart';
import 'package:login_signup/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:login_signup/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:login_signup/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:login_signup/features/payments/domain/entities/custom_payment_method.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/entities/payment_review_item.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';
import 'package:login_signup/features/payments/domain/usecases/create_payment_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_active_custom_payment_methods_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_appointment_balance_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_payments_in_review_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/refund_payment_usecase.dart';
import 'package:login_signup/features/payments/presentation/controllers/payment_controller.dart';
import 'package:login_signup/features/payments/presentation/controllers/payments_review_controller.dart';
import 'package:login_signup/features/payments/presentation/screens/payments_review_screen.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_offered_by_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_limits.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_limits_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../core/session/memory_token_store.dart';

// --- Repositorios falsos (pantallas, controllers y use cases son reales) ---

class FakeAppointmentsRepository implements AppointmentsRepository {

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  List<AppointmentEntity> agenda = [];
  List<AppointmentEntity> toReschedule = [];
  Failure? listFailure;

  @override
  Future<Either<Failure, List<AppointmentEntity>>>
      getAppointmentsToReschedule() async => Right(toReschedule);
  List<DateTime> freeSlots = [];
  Failure? saveFailure;
  Failure? cancelFailure;

  final created = <NewAppointment>[];
  final updates = <(String, AppointmentChanges)>[];
  final cancels = <(String, String?)>[];
  final completes = <String>[];
  final slotQueries = <AvailableSlotsQuery>[];
  final reads = <String>[];
  final prepared = <String>[];
  final marked = <String>[];

  AppointmentEntity _find(String id) => agenda.firstWhere((a) => a.id == id);

  void _replace(AppointmentEntity a) =>
      agenda = [for (final x in agenda) x.id == a.id ? a : x];

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getAppointments(
          AppointmentsRange range) async =>
      listFailure != null ? Left(listFailure!) : Right(List.of(agenda));

  @override
  Future<Either<Failure, AppointmentEntity>> getAppointment(String id) async {
    reads.add(id);
    return Right(_find(id));
  }

  @override
  Future<Either<Failure, AppointmentEntity>> createAppointment(
      NewAppointment appointment) async {
    created.add(appointment);
    if (saveFailure != null) return Left(saveFailure!);
    final saved = AppointmentEntity(
      id: 'new-${created.length}',
      client: const AppointmentClient(id: 'c1', name: 'Carla', lastname: 'Díaz'),
      professionalId: appointment.professionalId,
      services: const [
        AppointmentServiceLine(serviceId: 's1', name: 'Corte', price: 20000),
      ],
      startTime: appointment.start,
      endTime: appointment.start.add(const Duration(minutes: 30)),
      totalPrice: 20000,
    );
    agenda.add(saved);
    return Right(saved);
  }

  @override
  Future<Either<Failure, AppointmentEntity>> updateAppointment(
      String id, AppointmentChanges changes) async {
    updates.add((id, changes));
    if (saveFailure != null) return Left(saveFailure!);
    final updated = _find(id).copyWith(notes: changes.notes);
    _replace(updated);
    return Right(updated);
  }

  @override
  Future<Either<Failure, AppointmentEntity>> cancelAppointment(String id,
      {String? reason}) async {
    cancels.add((id, reason));
    if (cancelFailure != null) return Left(cancelFailure!);
    final cancelled = _find(id).copyWith(
        status: AppointmentStatus.CANCELLED, cancellationReason: reason);
    _replace(cancelled);
    return Right(cancelled);
  }

  @override
  Future<Either<Failure, AppointmentEntity>> completeAppointment(
      String id) async {
    completes.add(id);
    final done = _find(id).copyWith(status: AppointmentStatus.COMPLETED);
    _replace(done);
    return Right(done);
  }

  @override
  Future<Either<Failure, List<DateTime>>> getAvailableSlots(
      AvailableSlotsQuery query) async {
    slotQueries.add(query);
    return Right(List.of(freeSlots));
  }

  @override
  Future<Either<Failure, ManualReminder>> prepareReminder(String id) async {
    prepared.add(id);
    return Right(ManualReminder(
      appointmentId: id,
      clientId: 'c1',
      phone: '573001234567',
      message: 'Hola',
      whatsappUrl: 'https://wa.me/573001234567?text=Hola',
    ));
  }

  @override
  Future<Either<Failure, DateTime>> markReminderSent(String id) async {
    marked.add(id);
    return Right(DateTime(2030));
  }
}

class FakeServicesRepository implements ServicesRepository {
  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices() async =>
      const Right([corte, tinte]);

  /// Lo que hace cada profesional (`GetServicesOfferedByUseCase`).
  Map<String, List<ServiceEntity>> offered = {};

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServicesOfferedBy(
          String professionalId) async =>
      Right(offered[professionalId] ?? const [corte, tinte]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeEmployeesRepository implements EmployeesRepository {
  int calls = 0;

  @override
  Future<Either<Failure, List<EmployeeEntity>>> getEmployees() async {
    calls++;
    return const Right([ana, bea]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeClientsRepository implements ClientsRepository {
  @override
  Future<Either<Failure, PaginatedList<ClientEntity>>> getClients(
          ClientsQuery query) async =>
      const Right(PaginatedList(
        items: [carla],
        total: 1,
        page: 1,
        limit: 20,
        totalPages: 1,
        hasNextPage: false,
        hasPrevPage: false,
      ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSubscriptionRepository implements SubscriptionRepository {
  SubscriptionLimits limits =
      const SubscriptionLimits(canCreateAppointment: true);

  @override
  Future<Either<Failure, SubscriptionLimits>> checkLimits() async =>
      Right(limits);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePaymentRepository implements PaymentRepository {

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  List<PaymentEntity> previous = [];
  final sent = <PaymentEntity>[];
  List<PaymentReviewItem> inReview = [];
  final refunds = <(String, double, String)>[];

  @override
  Future<Either<Failure, List<PaymentReviewItem>>> getPaymentsInReview() async =>
      Right(inReview);

  @override
  Future<Either<Failure, PaymentEntity>> refundPayment(String paymentId,
      {required double amount, required String reason}) async {
    refunds.add((paymentId, amount, reason));
    final item = inReview.firstWhere((i) => i.payment.id == paymentId);
    inReview = [for (final i in inReview) if (i.payment.id != paymentId) i];
    return Right(item.payment.copyWith(refundAmount: amount));
  }

  @override
  Future<Either<Failure, PaymentEntity>> createPayment(
      PaymentEntity payment) async {
    sent.add(payment);
    return Right(payment.copyWith(id: 'pay-${sent.length}'));
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getAppointmentPayments(
          String appointmentId) async =>
      Right(previous);

  @override
  Future<Either<Failure, List<CustomPaymentMethod>>>
      getActiveCustomPaymentMethods() async => const Right([]);
}

/// Avisos locales sin el plugin (no hay plataforma en los tests).
class FakeNotifications implements NotificationService {
  final scheduled = <int>[];
  final cancelled = <int>[];

  @override
  Future<void> scheduleAppointmentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async =>
      scheduled.add(id);

  @override
  Future<void> cancelNotification(int id) async => cancelled.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- Datos -----------------------------------------------------------------

const corte = ServiceEntity(
    id: 's1', name: 'Corte', price: 20000, duration: 30, categoryId: 'k');
const tinte = ServiceEntity(
    id: 's2', name: 'Tinte', price: 50000, duration: 60, categoryId: 'k');
const ana = EmployeeEntity(
  id: 'e1',
  name: 'Ana',
  lastname: 'Pérez',
  email: 'ana@mail.com',
  isActive: true,
  isEmailVerified: true,
  // Hace los dos servicios (el formulario filtra por offersService).
  serviceAssignments: {
    's1': ServiceAssignment(serviceId: 's1'),
    's2': ServiceAssignment(serviceId: 's2'),
  },
);
/// Solo hace "Corte".
const bea = EmployeeEntity(
  id: 'e3',
  name: 'Bea',
  lastname: 'Soto',
  email: 'bea@mail.com',
  isActive: true,
  isEmailVerified: true,
  serviceAssignments: {'s1': ServiceAssignment(serviceId: 's1')},
);
const carla =
    ClientEntity(id: 'c1', name: 'Carla', lastname: 'Díaz', phone: '3001234567');

final nineAm = DateTime(2030, 1, 7, 9);
final tenAm = DateTime(2030, 1, 7, 10);

AppointmentEntity appointment({
  String id = 'a1',
  AppointmentStatus status = AppointmentStatus.PENDING,
  AppointmentPaymentStatus payment = AppointmentPaymentStatus.PENDING,
  double total = 50000,
  String? notes,
}) =>
    AppointmentEntity(
      id: id,
      client: const AppointmentClient(id: 'c1', name: 'Carla', lastname: 'Díaz'),
      professionalId: 'e1',
      professionalName: 'Ana Pérez',
      services: [
        AppointmentServiceLine(
            serviceId: 's2',
            name: 'Tinte',
            durationMinutes: 60,
            price: total,
            currentPrice: 55000),
      ],
      startTime: tenAm,
      endTime: tenAm.add(const Duration(hours: 1)),
      status: status,
      paymentStatus: payment,
      totalPrice: total,
      notes: notes,
    );

void main() {
  late FakeAppointmentsRepository appts;
  late FakeEmployeesRepository employees;
  late FakeSubscriptionRepository subscription;
  late FakePaymentRepository payments;
  late FakeNotifications notifications;
  late List<Uri> openedLinks;
  late bool linkOpens;
  Object? dialogResult;

  setUpAll(() => initializeDateFormatting('es'));

  void signInAs(String role, {String userId = 'o1', String name = 'Olga'}) {
    final store = MemoryTokenStore();
    final session = SessionController(SessionService(
      tokenStore: store,
      repository: SessionRepository(store),
    ));
    session.session.value =
        Session(token: 't', userId: userId, name: name, roles: [role]);
    Get.put<SessionController>(session, permanent: true);
  }

  setUp(() {
    Get.testMode = true;
    appts = FakeAppointmentsRepository()..freeSlots = [nineAm, tenAm];
    employees = FakeEmployeesRepository();
    subscription = FakeSubscriptionRepository();
    payments = FakePaymentRepository();
    notifications = FakeNotifications();
    openedLinks = [];
    linkOpens = true;
    dialogResult = null;

    // Como los `<feature>_dependencies`, sobre los repositorios falsos.
    Get.put(CreateAppointmentUseCase(appts));
    Get.put(UpdateAppointmentUseCase(appts));
    Get.put(GetAvailableSlotsUseCase(appts));
    Get.put(GetServicesUseCase(FakeServicesRepository()));
    Get.put(GetEmployeesUseCase(employees));
    Get.put(GetClientsPageUseCase(FakeClientsRepository()));
    // Como AppointmentsBinding.
    Get.put(AppointmentsController(
      getAppointmentsUseCase: GetAppointmentsUseCase(appts),
      checkSubscriptionLimitsUseCase:
          CheckSubscriptionLimitsUseCase(subscription),
    ));
    Get.put(AppointmentActionsController(
      cancelAppointmentUseCase: CancelAppointmentUseCase(appts),
      completeAppointmentUseCase: CompleteAppointmentUseCase(appts),
      getAppointmentUseCase: GetAppointmentUseCase(appts),
      getAppointmentBalanceUseCase: GetAppointmentBalanceUseCase(payments),
    ));
    Get.put(PaymentController(
      createPaymentUseCase: CreatePaymentUseCase(payments),
      getActiveCustomPaymentMethodsUseCase:
          GetActiveCustomPaymentMethodsUseCase(payments),
    ));
  });
  tearDown(Get.reset);

  /// Una pantalla con un botón que ejecuta [open] (el diálogo bajo prueba).
  Future<void> pumpLauncher(
      WidgetTester tester, Future<Object?> Function() open) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeConfig.lightTheme,
      home: Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async => dialogResult = await open(),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  /// Deja que el snackbar se cierre (si no, el test termina con timers).
  Future<void> expireSnackbar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  /// Rellena el formulario de cita nueva (Owner): profesional, servicio y
  /// cliente; la hora tocada (9:00) se elige sola si está libre.
  Future<void> fillNewAppointment(WidgetTester tester,
      {bool pickProfessional = true}) async {
    if (pickProfessional) {
      await tapKey(tester, 'appointment-professional');
      await tapText(tester, 'Ana Pérez');
    }
    await tapKey(tester, 'appointment-services');
    await tapText(tester, 'Corte');
    await tapText(tester, 'Listo');
    await tapKey(tester, 'appointment-client');
    await tapText(tester, 'Carla Díaz');
  }

  group('Crear cita', () {
    testWidgets('Owner: elige profesional, servicios, cliente y hora libre',
        (tester) async {
      signInAs('Owner');
      await pumpLauncher(
          tester, () => AppointmentFormDialog.create(initialStart: nineAm));
      expect(find.text('Elige el profesional y los servicios para ver las '
          'horas libres.'), findsOneWidget);

      await fillNewAppointment(tester);

      final query = appts.slotQueries.last;
      expect(query.professionalId, 'e1');
      expect(query.serviceIds, ['s1']);
      expect(query.day, DateTime(2030, 1, 7));
      expect(find.text('Corte\n\$ 20.000 · 30 min'), findsOneWidget);

      await tapText(tester, 'Agendar');

      final sent = appts.created.single;
      expect(sent.professionalId, 'e1');
      expect(sent.clientId, 'c1');
      expect(sent.serviceIds, ['s1']);
      expect(sent.start, nineAm);
      expect(dialogResult, isA<AppointmentEntity>());
      expect(find.text('Nueva cita'), findsNothing);
      expect(find.text('Cita agendada'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('el catálogo solo ofrece lo que hace el profesional (7.04-5)',
        (tester) async {
      signInAs('Owner');
      await pumpLauncher(
          tester, () => AppointmentFormDialog.create(initialStart: nineAm));
      await tapKey(tester, 'appointment-professional');
      await tapText(tester, 'Ana Pérez');
      await tapKey(tester, 'appointment-services');
      await tapText(tester, 'Tinte');
      await tapText(tester, 'Listo');

      // Bea no hace Tinte: se quita y se avisa.
      await tapKey(tester, 'appointment-professional');
      await tapText(tester, 'Bea Soto');
      expect(find.text('Servicios ajustados'), findsOneWidget);
      await expireSnackbar(tester);

      await tapKey(tester, 'appointment-services');
      expect(find.text('Corte'), findsWidgets);
      expect(find.text('Tinte'), findsNothing);
    });

    testWidgets('Employee: el profesional es él mismo y no se puede cambiar',
        (tester) async {
      signInAs('Employee', userId: 'e7', name: 'Eva Ruiz');
      await pumpLauncher(
          tester, () => AppointmentFormDialog.create(initialStart: nineAm));

      expect(find.text('Eva Ruiz'), findsOneWidget);
      final tile = tester.widget<ListTile>(find.descendant(
          of: find.byKey(const Key('appointment-professional')),
          matching: find.byType(ListTile)));
      expect(tile.onTap, isNull);
      expect(employees.calls, 0); // no lista profesionales

      await fillNewAppointment(tester, pickProfessional: false);
      expect(appts.slotQueries.last.professionalId, 'e7');
      await tapText(tester, 'Agendar');

      expect(appts.created.single.professionalId, 'e7');
      await expireSnackbar(tester);
    });

    testWidgets('hora no disponible: avisa, recarga las horas y sigue abierto',
        (tester) async {
      signInAs('Owner');
      appts.saveFailure = const SlotUnavailableFailure();
      await pumpLauncher(
          tester, () => AppointmentFormDialog.create(initialStart: nineAm));
      await fillNewAppointment(tester);
      final queriesBefore = appts.slotQueries.length;

      await tapText(tester, 'Agendar');

      expect(find.text('Horario no disponible'), findsOneWidget);
      expect(appts.slotQueries.length, queriesBefore + 1);
      await tapText(tester, 'Entendido');
      expect(find.text('Nueva cita'), findsOneWidget);
      expect(dialogResult, isNull);
    });

    testWidgets('hora pasada: aviso y horas recargadas', (tester) async {
      signInAs('Owner');
      appts.saveFailure = const AppointmentInPastFailure();
      await pumpLauncher(
          tester, () => AppointmentFormDialog.create(initialStart: nineAm));
      await fillNewAppointment(tester);
      final queriesBefore = appts.slotQueries.length;

      await tapText(tester, 'Agendar');

      expect(find.text('Hora pasada'), findsOneWidget);
      expect(find.text(AppointmentInPastFailure.defaultMessage), findsOneWidget);
      expect(appts.slotQueries.length, queriesBefore + 1);
      expect(find.text('Nueva cita'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('límite del trial al guardar: diálogo único de suscripción',
        (tester) async {
      signInAs('Owner');
      appts.saveFailure = const TrialLimitReachedFailure();
      await pumpLauncher(
          tester, () => AppointmentFormDialog.create(initialStart: nineAm));
      await fillNewAppointment(tester);

      await tapText(tester, 'Agendar');

      expect(find.text('Plan de prueba finalizado'), findsOneWidget);
      expect(find.text('Ver planes disponibles'), findsOneWidget);
    });

    testWidgets('límite del trial antes de abrir: no abre el formulario',
        (tester) async {
      signInAs('Owner');
      subscription.limits = const SubscriptionLimits(
        canCreateAppointment: false,
        block: SubscriptionBlock.trialLimitReached,
      );
      await pumpLauncher(tester, () async {
        await startNewAppointment(Get.find<AppointmentsController>());
        return null;
      });

      expect(find.text('Plan de prueba finalizado'), findsOneWidget);
      expect(find.text('Nueva cita'), findsNothing);
    });
  });

  group('Agenda (home)', () {
    Future<void> pumpHome(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(GetMaterialApp(
        theme: ThemeConfig.lightTheme,
        home: const AppointmentsView(),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('Owner ve la agenda del negocio y puede agendar',
        (tester) async {
      signInAs('Owner');
      await pumpHome(tester);
      expect(find.text('Agenda · Día'), findsOneWidget);
      expect(find.byTooltip('Nueva cita'), findsOneWidget);
    });

    testWidgets('Employee ve "Mis citas" y también puede agendar',
        (tester) async {
      signInAs('Employee', userId: 'e1');
      await pumpHome(tester);
      expect(find.text('Mis citas · Día'), findsOneWidget);

      await tester.tap(find.byTooltip('Nueva cita'));
      await tester.pumpAndSettle();
      expect(find.text('Nueva cita'), findsWidgets);
      expect(find.text('Olga'), findsOneWidget); // profesional fijado
    });

    testWidgets('un error al cargar se muestra con reintento', (tester) async {
      signInAs('Owner');
      appts.listFailure = const NetworkFailure(message: 'Sin conexión');
      await Get.find<AppointmentsController>().reload();
      await pumpHome(tester);

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Sin conexión'), findsOneWidget);
      appts.listFailure = null;
      await tapText(tester, 'Reintentar');
      expect(find.byType(ErrorState), findsNothing);
    });
  });

  group('Editar cita', () {
    testWidgets('cambiar solo las notas envía solo las notas', (tester) async {
      signInAs('Owner');
      final original = appointment(notes: 'Antes');
      appts.agenda = [original];
      appts.freeSlots = [nineAm]; // las 10:00 las ocupa la propia cita
      await pumpLauncher(tester, () => AppointmentFormDialog.edit(original));

      expect(find.text('Editar cita'), findsOneWidget);
      expect(find.textContaining('(actual)'), findsOneWidget);
      // Precio guardado de la cita, no el actual del catálogo.
      expect(find.textContaining('\$ 50.000'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('appointment-notes')), 'Trae foto');
      await tapText(tester, 'Guardar cambios');

      final (id, changes) = appts.updates.single;
      expect(id, 'a1');
      expect(changes, const AppointmentChanges(notes: 'Trae foto'));
      expect(changes.touchesSlot, isFalse);
      expect(find.text('Cita actualizada'), findsOneWidget);
      await expireSnackbar(tester);
    });
  });

  group('Detalle', () {
    Future<void> openDetail(WidgetTester tester, AppointmentEntity a) async {
      appts.agenda = [a];
      await Get.find<AppointmentsController>().showDay(a.startTime);
      await pumpLauncher(tester, () async {
        await AppointmentDetailsDialog.show(a);
        return null;
      });
    }

    testWidgets('muestra estados con su texto y el precio guardado',
        (tester) async {
      signInAs('Owner');
      await openDetail(
          tester,
          appointment(
              status: AppointmentStatus.CONFIRMED,
              payment: AppointmentPaymentStatus.PARTIAL));

      expect(find.text('Confirmada'), findsOneWidget);
      expect(find.text('Anticipo'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('\$ 50.000'), findsNWidgets(2)); // línea y total
      expect(find.textContaining('hoy cuesta \$ 55.000'), findsOneWidget);
      expect(find.text('Cobrar saldo'), findsOneWidget);
    });

    testWidgets('cancelar sin pagos, con motivo', (tester) async {
      signInAs('Owner');
      await openDetail(tester, appointment());

      await tapText(tester, 'Cancelar cita');
      await tester.enterText(
          find.byKey(const Key('cancel-reason')), 'Se enfermó');
      await tester.tap(find.widgetWithText(FilledButton, 'Cancelar cita'));
      await tester.pumpAndSettle();

      expect(appts.cancels.single, ('a1', 'Se enfermó'));
      expect(find.text('Cita cancelada'), findsOneWidget);
      expect(Get.find<AppointmentsController>().appointments.single.isCancelled,
          isTrue);
      await expireSnackbar(tester);
    });

    testWidgets('con anticipo no se ofrece cancelar: pide reembolsar',
        (tester) async {
      signInAs('Owner');
      await openDetail(
          tester, appointment(payment: AppointmentPaymentStatus.PARTIAL));

      expect(find.text('Cancelar cita'), findsNothing);
      expect(find.textContaining('reembólsalos antes de cancelar'),
          findsOneWidget);
    });

    testWidgets('si el backend dice que tiene pagos, avisa de reembolsar',
        (tester) async {
      signInAs('Owner');
      appts.cancelFailure = const AppointmentPaidFailure();
      await openDetail(tester, appointment());

      await tapText(tester, 'Cancelar cita');
      await tester.tap(find.widgetWithText(FilledButton, 'Cancelar cita'));
      await tester.pumpAndSettle();

      expect(find.text('La cita tiene pagos'), findsOneWidget);
      expect(find.text('Reembolsa los pagos antes de cancelar la cita.'),
          findsOneWidget);
      expect(Get.find<AppointmentsController>().appointments.single.isCancelled,
          isFalse);
    });

    testWidgets('completar sin pagar: confirma y deja el pago pendiente',
        (tester) async {
      signInAs('Employee', userId: 'e1');
      // 10:30 del negocio: la cita de las 10:00 ya empezó (7.03).
      BusinessTimeZone.clock =
          () => BusinessTimeZone.toInstant(DateTime(2030, 1, 7, 10, 30));
      addTearDown(() => BusinessTimeZone.clock = DateTime.now);
      await openDetail(tester, appointment());

      // El Employee no paga ni edita, pero sí completa y cancela.
      expect(find.text('Registrar pago'), findsNothing);
      expect(find.text('Editar'), findsNothing);

      await tapText(tester, 'Completar');
      expect(find.textContaining('aún no está pagada'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Completar'));
      await tester.pumpAndSettle();

      expect(appts.completes.single, 'a1');
      expect(find.text('Cita completada; el pago queda pendiente'),
          findsOneWidget);
      expect(
          Get.find<AppointmentsController>().appointments.single.isCompleted,
          isTrue);
      await expireSnackbar(tester);
    });

    testWidgets('una cita que aún no empieza no se puede completar',
        (tester) async {
      signInAs('Owner');
      BusinessTimeZone.clock =
          () => BusinessTimeZone.toInstant(DateTime(2030, 1, 7, 9));
      addTearDown(() => BusinessTimeZone.clock = DateTime.now);
      await openDetail(tester, appointment());
      final button = tester.widget<OutlinedButton>(find.ancestor(
          of: find.text('Completar (cuando empiece)'),
          matching: find.byWidgetPredicate((w) => w is OutlinedButton)));
      expect(button.onPressed, isNull);
    });

    testWidgets('reserva web: marca en el detalle', (tester) async {
      signInAs('Owner');
      await openDetail(
          tester, appointment().copyWith(source: AppointmentSource.WEB));
      expect(find.text('Reserva web'), findsOneWidget);
    });

    testWidgets('pago parcial: propone el saldo y refresca la cita',
        (tester) async {
      signInAs('Owner');
      payments.previous = const [
        PaymentEntity(
          appointmentId: 'a1',
          amount: 20000,
          paymentMethod: PaymentMethod.CASH,
          status: PaymentStatus.COMPLETED,
        ),
      ];
      await openDetail(
          tester, appointment(payment: AppointmentPaymentStatus.PARTIAL));

      await tapText(tester, 'Cobrar saldo');

      expect(find.text('Saldo pendiente'), findsOneWidget);
      expect(find.text('\$ 30.000'), findsOneWidget);
      final amount =
          tester.widget<TextField>(find.byKey(const Key('payment-amount')));
      expect(amount.controller!.text, '30000');

      await tester.enterText(find.byKey(const Key('payment-amount')), '40000');
      await tapText(tester, 'Confirmar pago');
      expect(find.textContaining('no puede superar el saldo pendiente'),
          findsOneWidget);
      expect(payments.sent, isEmpty);

      await tester.enterText(find.byKey(const Key('payment-amount')), '30000');
      await tapText(tester, 'Confirmar pago');

      expect(payments.sent.single.amount, 30000);
      expect(appts.reads, ['a1']); // la cita se vuelve a leer
      await expireSnackbar(tester);
    });
  });

  group('Recordatorios', () {
    Future<void> pumpReminders(WidgetTester tester) async {
      Get.put(AppointmentReminderController(
        getUpcomingAppointmentsUseCase: GetUpcomingAppointmentsUseCase(appts),
        prepareReminderUseCase: PrepareReminderUseCase(appts),
        markReminderSentUseCase: MarkReminderSentUseCase(appts),
        notifications: () => notifications,
        openLink: (uri) async {
          openedLinks.add(uri);
          return linkOpens;
        },
      ));
      await tester.pumpWidget(GetMaterialApp(
        theme: ThemeConfig.lightTheme,
        home: const UpcomingAppointmentsScreen(),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('sin canceladas; enviar abre wa.me y marca enviado',
        (tester) async {
      signInAs('Owner');
      appts.agenda = [
        appointment(),
        appointment(id: 'a2', status: AppointmentStatus.CANCELLED),
      ];
      await pumpReminders(tester);

      expect(find.text('Enviar recordatorio'), findsOneWidget);
      expect(notifications.scheduled, ['a1'.hashCode]);

      await tapText(tester, 'Enviar recordatorio');

      expect(appts.prepared, ['a1']);
      expect(openedLinks.single.toString(),
          'https://wa.me/573001234567?text=Hola');
      expect(appts.marked, ['a1']);
      expect(notifications.cancelled, ['a1'.hashCode]);
      expect(find.text('Enviar recordatorio'), findsNothing);
      await expireSnackbar(tester);
    });

    testWidgets('si WhatsApp no abre, no se marca enviado', (tester) async {
      signInAs('Employee', userId: 'e1');
      linkOpens = false;
      appts.agenda = [appointment()];
      await pumpReminders(tester);

      await tapText(tester, 'Enviar recordatorio');

      expect(find.text('No se pudo abrir WhatsApp'), findsOneWidget);
      expect(appts.marked, isEmpty);
      expect(find.text('Enviar recordatorio'), findsOneWidget);
      await expireSnackbar(tester);
    });
  });

  group('AppointmentsController', () {
    test('rango por vista: día, semana de lunes a domingo y 6 semanas del mes',
        () {
      final wed = DateTime(2030, 1, 9, 15);
      expect(AppointmentsController.rangeFor(CalendarView.day, wed),
          AppointmentsRange.day(wed));
      expect(
          AppointmentsController.rangeFor(CalendarView.week, wed),
          AppointmentsRange(
              start: DateTime(2030, 1, 7), end: DateTime(2030, 1, 14)));
      final month = AppointmentsController.rangeFor(CalendarView.month, wed);
      expect(month.start, DateTime(2029, 12, 31)); // lunes antes del día 1
      expect(month.end, DateTime(2030, 2, 11));
    });

    test('applyChange sustituye, añade en rango y quita lo que sale del rango',
        () async {
      signInAs('Owner');
      final agenda = Get.find<AppointmentsController>();
      appts.agenda = [appointment()];
      await agenda.showDay(tenAm);
      expect(agenda.appointments, hasLength(1));

      agenda.applyChange(appointment(status: AppointmentStatus.CONFIRMED));
      expect(agenda.appointments.single.isConfirmed, isTrue);

      agenda.applyChange(appointment(id: 'a2'));
      expect(agenda.appointments, hasLength(2));

      final moved = appointment().copyWith(
          startTime: DateTime(2030, 1, 8, 10),
          endTime: DateTime(2030, 1, 8, 11));
      agenda.applyChange(moved);
      expect(agenda.appointments.map((a) => a.id), ['a2']);
    });

    test('bloques del calendario: id de la cita y servicio', () {
      expect(AppointmentCalendarDataSource.blockOf('abc-1_2'),
          (appointmentId: 'abc-1', serviceIndex: 2));
      expect(AppointmentCalendarDataSource.blockOf('abc-1'),
          (appointmentId: 'abc-1', serviceIndex: 0));
    });
  });

  group('Sincronización (10.03)', () {
    AppointmentEntity conflicted() => appointment().copyWith(
        needsReschedule: true, syncConflict: 'SLOT_UNAVAILABLE');

    final review = PaymentReviewItem(
      payment: const PaymentEntity(
        id: 'pr1',
        appointmentId: 'a1',
        amount: 60000,
        paymentMethod: PaymentMethod.CASH,
        status: PaymentStatus.COMPLETED,
        reviewRequired: 'OVERPAID',
      ),
      clientName: 'Carla Díaz',
      appointmentDate: tenAm,
      appointmentTotal: 50000,
      suggestedRefund: 10000,
    );

    void putReviewAwareActions() {
      Get.delete<AppointmentActionsController>(force: true);
      Get.put(AppointmentActionsController(
        cancelAppointmentUseCase: CancelAppointmentUseCase(appts),
        completeAppointmentUseCase: CompleteAppointmentUseCase(appts),
        getAppointmentUseCase: GetAppointmentUseCase(appts),
        getAppointmentBalanceUseCase: GetAppointmentBalanceUseCase(payments),
        getPaymentsInReviewUseCase: GetPaymentsInReviewUseCase(payments),
      ));
    }

    Future<void> pumpScreen(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
          GetMaterialApp(theme: ThemeConfig.lightTheme, home: home));
      await tester.pumpAndSettle();
    }

    testWidgets('agenda: aviso de citas por mover y pagos por revisar',
        (tester) async {
      signInAs('Owner');
      appts.toReschedule = [conflicted()];
      payments.inReview = [review];
      Get.put(SyncAttentionController(
        getAppointmentsToRescheduleUseCase:
            GetAppointmentsToRescheduleUseCase(appts),
        getPaymentsInReviewUseCase: GetPaymentsInReviewUseCase(payments),
        session: Get.find(),
      ));
      await pumpScreen(tester, const AppointmentsView());
      expect(find.text('1 cita por mover'), findsOneWidget);
      expect(find.text('1 pago por revisar'), findsOneWidget);
    });

    testWidgets('el Employee no ve los pagos por revisar', (tester) async {
      signInAs('Employee', userId: 'e1');
      appts.toReschedule = [conflicted()];
      payments.inReview = [review];
      Get.put(SyncAttentionController(
        getAppointmentsToRescheduleUseCase:
            GetAppointmentsToRescheduleUseCase(appts),
        getPaymentsInReviewUseCase: GetPaymentsInReviewUseCase(payments),
        session: Get.find(),
      ));
      await pumpScreen(tester, const AppointmentsView());
      expect(find.text('1 cita por mover'), findsOneWidget);
      expect(find.text('1 pago por revisar'), findsNothing);
    });

    testWidgets('detalle (Owner): motivo, "Mover a otra hora" y pago en revisión',
        (tester) async {
      signInAs('Owner');
      payments.inReview = [review];
      putReviewAwareActions();
      final a = conflicted();
      appts.agenda = [a];
      await pumpLauncher(tester, () => AppointmentDetailsDialog.show(a));
      expect(find.textContaining('ya estaba ocupada'), findsOneWidget);
      expect(find.text('Mover a otra hora'), findsOneWidget);
      expect(find.text('1 pago en revisión: revisar'), findsOneWidget);
    });

    testWidgets('detalle (Employee): solo el propietario puede moverla',
        (tester) async {
      signInAs('Employee', userId: 'e1');
      putReviewAwareActions();
      await pumpLauncher(
          tester, () => AppointmentDetailsDialog.show(conflicted()));
      expect(find.textContaining('Solo el propietario puede moverla'),
          findsOneWidget);
      expect(find.text('Mover a otra hora'), findsNothing);
      expect(find.textContaining('pago en revisión'), findsNothing);
    });

    testWidgets('mover: su hora no se ofrece como "(actual)"', (tester) async {
      signInAs('Owner');
      final a = conflicted();
      appts.agenda = [a];
      appts.freeSlots = [nineAm];
      await pumpLauncher(tester, () => AppointmentFormDialog.edit(a));
      expect(find.text('Editar cita'), findsOneWidget);
      expect(find.textContaining('(actual)'), findsNothing);
    });

    testWidgets('"Citas por mover": lista con el motivo y la acción',
        (tester) async {
      signInAs('Owner');
      appts.toReschedule = [conflicted()];
      Get.put(RescheduleListController(
          getAppointmentsToRescheduleUseCase:
              GetAppointmentsToRescheduleUseCase(appts)));
      await pumpScreen(tester, const RescheduleListScreen());
      expect(find.text('Carla Díaz'), findsOneWidget);
      expect(find.textContaining('ya estaba ocupada'), findsOneWidget);
      expect(find.text('Mover'), findsOneWidget);
    });

    testWidgets('"Pagos por revisar": motivo y reembolso', (tester) async {
      signInAs('Owner');
      payments.inReview = [review];
      Get.put(PaymentsReviewController(
        getPaymentsInReviewUseCase: GetPaymentsInReviewUseCase(payments),
        refundPaymentUseCase: RefundPaymentUseCase(payments),
      ));
      await pumpScreen(tester, const PaymentsReviewScreen());
      expect(find.text('En revisión'), findsOneWidget);
      expect(find.textContaining('pagada de más'), findsOneWidget);

      await tapText(tester, 'Reembolsar \$ 10.000');
      expect(find.text('Registrar reembolso'), findsOneWidget);
      await tapText(tester, 'Reembolsar');
      expect(payments.refunds.single, ('pr1', 10000.0, 'Pago de más'));
      expect(find.text('No hay pagos por revisar'), findsOneWidget);
      await expireSnackbar(tester);
    });

    testWidgets('Employee: el catálogo de la cita son sus servicios',
        (tester) async {
      signInAs('Employee', userId: 'e7', name: 'Eva Ruiz');
      final services = FakeServicesRepository()..offered = {'e7': [tinte]};
      Get.put(GetServicesOfferedByUseCase(services));
      await pumpLauncher(
          tester, () => AppointmentFormDialog.create(initialStart: nineAm));
      await tapKey(tester, 'appointment-services');
      expect(find.text('Tinte'), findsWidgets);
      expect(find.text('Corte'), findsNothing);
    });

    testWidgets('la campana: pestaña "Avisos"', (tester) async {
      signInAs('Owner');
      Get.put(AppointmentReminderController(
        getUpcomingAppointmentsUseCase: GetUpcomingAppointmentsUseCase(appts),
        prepareReminderUseCase: PrepareReminderUseCase(appts),
        markReminderSentUseCase: MarkReminderSentUseCase(appts),
        notifications: () => notifications,
      ));
      Get.put(NotificationsController(
          getNotificationsUseCase: GetNotificationsUseCase(_FakeNotices())));
      await pumpScreen(tester, const UpcomingAppointmentsScreen());
      expect(find.text('Recordatorio de cita'), findsOneWidget);
      await tapText(tester, 'Recordatorios');
      expect(find.text('No hay recordatorios pendientes'), findsOneWidget);
    });
  });
}

class _FakeNotices implements NotificationsRepository {
  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications() async =>
      Right([
        AppNotification(
          id: 'n1',
          type: 'APPOINTMENT_REMINDER',
          title: 'Recordatorio de cita',
          message: 'Carla Díaz a las 10:00 a. m.',
          createdAt: DateTime(2030, 1, 7, 9),
        ),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
