import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/statistics/data/datasources/statistics_remote_datasource.dart';
import 'package:login_signup/features/statistics/data/models/commission_settlement_model.dart';
import 'package:login_signup/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:login_signup/features/statistics/domain/entities/commission_settlement.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/failures/statistics_failures.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_commission_settlement_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/stats_use_case.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';

/// Respuesta real de `GET /payments/stats/commissions` (8.02).
Map<String, dynamic> backendSettlement() => {
      'start': '2026-10-01T00:00:00.000-05:00',
      'end': '2026-10-31T23:59:59.999-05:00',
      'timezone': 'America/Bogota',
      'totals': {
        'services_total': 120000,
        'professional_total': 39000,
        'business_total': 81000,
        'appointment_count': 2,
      },
      'professionals': [
        {
          'professional_id': 'pro-1',
          'professional_name': 'Laura Gómez',
          'appointment_count': 2,
          'services_total': 120000,
          'professional_total': 39000,
          'business_total': 81000,
          'appointments': [
            {
              'appointment_id': 'apt-1',
              'date': '2026-10-21T10:00:00.000-05:00',
              'timezone': 'America/Bogota',
              'client_name': 'Ana Pérez',
              'services_total': 50000,
              'professional_total': 15000,
              'business_total': 35000,
              'lines': [
                {
                  'service_id': 'svc-1',
                  'service_name': 'Cejas',
                  'price': 50000,
                  'commission_percentage': 30,
                  'commission': 15000,
                },
              ],
            },
            {
              'appointment_id': 'apt-2',
              'date': 'no es fecha',
              'client_name': 'X',
              'lines': [],
            },
          ],
        },
      ],
    };

void main() {
  tearDown(BusinessTimeZone.reset);

  test('fromJson: totales, profesional, cita en su zona y líneas', () {
    BusinessTimeZone.use('America/Caracas');
    final s = CommissionSettlementModel.fromJson(backendSettlement());
    expect(s.startDay, DateTime(2026, 10, 1));
    expect(s.endDay, DateTime(2026, 10, 31));
    expect(s.timeZone, 'America/Bogota');
    expect(
        s.totals,
        const CommissionAmounts(
            servicesTotal: 120000,
            professionalTotal: 39000,
            businessTotal: 81000));
    expect(s.appointmentCount, 2);
    final pro = s.professionals.single;
    expect(pro.professionalName, 'Laura Gómez');
    expect(pro.amounts.professionalTotal, 39000);
    expect(pro.appointments.length, 1, reason: 'sin fecha se descarta');
    final appointment = pro.appointments.single;
    expect(appointment.date, DateTime(2026, 10, 21, 10),
        reason: 'en la zona de la cita, no en la actual del negocio');
    expect(appointment.lines.single,
        const CommissionLine(
            serviceId: 'svc-1',
            serviceName: 'Cejas',
            price: 50000,
            commissionPercentage: 30,
            commission: 15000));
  });

  test('vacío: totales en 0', () {
    final s = CommissionSettlementModel.fromJson({
      'totals': {
        'services_total': 0,
        'professional_total': 0,
        'business_total': 0,
        'appointment_count': 0
      },
      'professionals': [],
    });
    expect(s.isEmpty, true);
    expect(s.totals, const CommissionAmounts());
  });

  group('use case', () {
    late FakeHttpClientAdapter adapter;
    late GetCommissionSettlementUseCase useCase;
    final range = StatsRange(
        start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31));

    setUp(() {
      adapter = FakeHttpClientAdapter((_) => jsonBody(200, backendSettlement()));
      useCase = GetCommissionSettlementUseCase(StatisticsRepositoryImpl(
          StatisticsRemoteDataSourceImpl(buildApiClient(
              baseUrl: 'http://api.test/api',
              tokenStore: MemoryTokenStore('jwt'),
              httpClientAdapter: adapter,
              enableLogs: false))));
    });

    test('GET con días del negocio y profesional opcional', () async {
      await useCase(EmployeeStatsParams(range, professionalId: 'pro-1'));
      final request = adapter.requests.single;
      expect(request.uri.path, '/api/payments/stats/commissions');
      expect(request.uri.queryParameters, {
        'startDate': '2026-10-01',
        'endDate': '2026-10-31',
        'professionalId': 'pro-1',
      });
      await useCase(EmployeeStatsParams(range));
      expect(adapter.requests.last.uri.queryParameters
          .containsKey('professionalId'), false);
    });

    test('rango invertido → sin llamar al backend', () async {
      final result = await useCase(EmployeeStatsParams(StatsRange(
          start: DateTime(2026, 10, 31), end: DateTime(2026, 10, 1))));
      expect(result.fold((f) => f, (_) => null),
          isA<InvalidStatsQueryFailure>());
      expect(adapter.requests, isEmpty);
    });

    test('Employee pidiendo otro profesional → ForbiddenFailure', () async {
      adapter.handler = (_) => jsonBody(403, {
            'statusCode': 403,
            'code': 'FORBIDDEN',
            'message': 'Solo puedes consultar tus propias comisiones',
          });
      final result =
          await useCase(EmployeeStatsParams(range, professionalId: 'otro'));
      expect(result.fold((f) => f, (_) => null), isA<ForbiddenFailure>());
    });
  });
}
