import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/features/statistics/data/models/client_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/employee_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/payment_comparison_model.dart';
import 'package:login_signup/features/statistics/data/models/payment_method_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/payment_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/professional_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/service_stats_model.dart';
import 'package:login_signup/features/statistics/data/models/top_client_model.dart';
import 'package:login_signup/features/statistics/domain/entities/employee_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_method_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_stats_entity.dart';

// Respuestas tal como las arma hoy `payments.service.ts` (tras 2.05/2.06):
// importes netos convertidos con `Number()`, fechas con el offset del negocio
// (`businessJsonReplacer`) y días del desglose como "YYYY-MM-DD".

/// `GET /payments/stats`.
Map<String, dynamic> backendPaymentStats({
  Object? total = 105000,
  Object? count = 3,
  Object? average = 35000,
}) =>
    {'total_amount': total, 'payment_count': count, 'average_amount': average};

/// `GET /payments/stats/comparison` (21/10 frente a 20/10).
Map<String, dynamic> backendComparison() => {
      'current_period': {
        'start_date': '2026-10-21T00:00:00.000-05:00',
        'end_date': '2026-10-21T23:59:59.999-05:00',
        'total_amount': 105000,
        'payment_count': 3,
        'average_amount': 35000,
      },
      'previous_period': {
        'start_date': '2026-10-20T00:00:00.000-05:00',
        'end_date': '2026-10-20T23:59:59.999-05:00',
        'total_amount': 0,
        'payment_count': 0,
        'average_amount': 0,
      },
      'change': {
        'amount_difference': 105000,
        'amount_percentage': 100,
        'count_difference': 3,
        'count_percentage': 100,
        'average_difference': 35000,
        'average_percentage': 100,
      },
    };

/// Elemento de `GET /payments/stats/by-method`.
Map<String, dynamic> backendMethodStats({String method = 'CASH'}) => {
      'method': method,
      'method_type': 'STANDARD',
      'count': 2,
      'total': 70000,
      'average': 35000,
      'percentage': 66.66666666666667,
    };

/// Elemento de `GET /payments/stats/by-professional`.
Map<String, dynamic> backendProfessionalStats() => {
      'professional_id': 'pro-1',
      'professional_name': 'Laura ', // CONCAT con apellido null
      'appointment_count': 2,
      'payment_count': 2,
      'total_amount': 80000,
      'average_per_payment': 40000,
      'percentage_of_total': 76.19047619047619,
    };

/// Elemento de `GET /payments/stats/by-service`.
Map<String, dynamic> backendServiceStats() => {
      'service_id': 'srv-1',
      'service_name': 'Cejas en hilo',
      'payment_count': 3,
      'total_amount': 135000,
      'average_amount': 45000,
      'percentage_of_total': 128.57142857142858,
    };

/// Elemento de `GET /payments/stats/by-client`.
Map<String, dynamic> backendClientStats() => {
      'client_id': 'cli-1',
      'client_name': 'Ana Pérez',
      'first_visit_date': '2026-10-01T09:00:00.000-05:00',
      'last_visit_date': '2026-10-21T15:30:00.000-05:00',
      'visit_count': 3,
      'payment_count': 3,
      'total_spent': 105000,
      'average_per_payment': 35000,
      'frequency_days': 10,
    };

/// Elemento de `GET /payments/stats/top-clients`.
Map<String, dynamic> backendTopClient() => {
      'client_id': 'cli-1',
      'client_name': 'Ana Pérez',
      'visit_count': 3,
      'total_spent': 105000,
    };

/// `GET /payments/employee-stats`.
Map<String, dynamic> backendEmployeeStats() => {
      'summary': {
        'total_amount': 80000,
        'payment_count': 2,
        'appointment_count': 2,
        'average_per_payment': 40000,
      },
      'by_service': [
        {
          'service_id': 'srv-1',
          'service_name': 'Cejas en hilo',
          'count': 2,
          'total': 90000,
        },
      ],
      'daily_evolution': [
        {'date': '2026-10-20', 'total': 30000, 'count': 1},
        {'date': '2026-10-21', 'total': 50000, 'count': 1},
      ],
    };

/// `GET /payments/employee-stats` sin pagos en el rango.
Map<String, dynamic> backendEmptyEmployeeStats() => {
      'summary': {
        'total_amount': 0,
        'payment_count': 0,
        'appointment_count': 0,
        'average_per_payment': 0,
      },
      'by_service': [],
      'daily_evolution': [],
    };

void main() {
  group('PaymentStatsModel', () {
    test('fromJson → entidad con importes netos', () {
      expect(
          PaymentStatsModel.fromJson(backendPaymentStats()).toEntity(),
          const PaymentStatsEntity(
              totalAmount: 105000, paymentCount: 3, averageAmount: 35000));
    });

    test('rango vacío (ceros) → PaymentStatsEntity.empty', () {
      final entity = PaymentStatsModel.fromJson(
              backendPaymentStats(total: 0, count: 0, average: 0))
          .toEntity();
      expect(entity, PaymentStatsEntity.empty);
      expect(entity.isEmpty, true);
    });

    test('importes como texto o null no rompen', () {
      final entity = PaymentStatsModel.fromJson(
              backendPaymentStats(total: '45000.50', count: '1', average: null))
          .toEntity();
      expect(entity.totalAmount, 45000.5);
      expect(entity.paymentCount, 1);
      expect(entity.averageAmount, 0);
    });
  });

  group('PaymentComparisonModel', () {
    test('períodos como días del negocio y cambios', () {
      final entity =
          PaymentComparisonModel.fromJson(backendComparison()).toEntity();
      // El fin (23:59:59.999 -05:00) sigue siendo el 21 en cualquier zona.
      expect(entity.currentPeriod.startDate, DateTime(2026, 10, 21));
      expect(entity.currentPeriod.endDate, DateTime(2026, 10, 21));
      expect(entity.previousPeriod.startDate, DateTime(2026, 10, 20));
      expect(entity.currentPeriod.totalAmount, 105000);
      expect(entity.previousPeriod.paymentCount, 0);
      expect(entity.change.amountPercentage, 100);
      expect(entity.change.countDifference, 3);
    });

    test('sin período → FormatException (safeCall la vuelve ServerFailure)',
        () {
      expect(
          () => PaymentComparisonModel.fromJson(
              {...backendComparison()}..remove('previous_period')),
          throwsFormatException);
    });
  });

  test('PaymentMethodStatsModel: enum, tipo y porcentaje', () {
    final entity =
        PaymentMethodStatsModel.fromJson(backendMethodStats()).toEntity();
    expect(entity.method, 'CASH');
    expect(entity.paymentMethod, PaymentMethod.CASH);
    expect(entity.methodType, PaymentMethodType.standard);
    expect(entity.count, 2);
    expect(entity.total, 70000);
    expect(entity.percentage, closeTo(66.67, 0.01));

    final unknown = PaymentMethodStatsModel.fromJson(
        {...backendMethodStats(method: 'NEQUI'), 'method_type': 'CUSTOM'});
    expect(unknown.toEntity().paymentMethod, isNull);
    expect(unknown.toEntity().method, 'NEQUI');
    expect(unknown.toEntity().methodType, PaymentMethodType.custom);
  });

  test('ProfessionalStatsModel: nombre recortado', () {
    final entity =
        ProfessionalStatsModel.fromJson(backendProfessionalStats()).toEntity();
    expect(entity.professionalId, 'pro-1');
    expect(entity.professionalName, 'Laura');
    expect(entity.appointmentCount, 2);
    expect(entity.totalAmount, 80000);
    expect(entity.percentageOfTotal, closeTo(76.19, 0.01));
  });

  test('ServiceStatsModel: tal cual (el % puede pasar de 100, ver entidad)',
      () {
    final entity = ServiceStatsModel.fromJson(backendServiceStats()).toEntity();
    expect(entity.serviceName, 'Cejas en hilo');
    expect(entity.paymentCount, 3);
    expect(entity.totalAmount, 135000);
    expect(entity.averageAmount, 45000);
    expect(entity.percentageOfTotal, greaterThan(100));
  });

  group('ClientStatsModel', () {
    test('visitas con offset → mismo instante, en hora local', () {
      final entity = ClientStatsModel.fromJson(backendClientStats()).toEntity();
      expect(entity.clientName, 'Ana Pérez');
      expect(entity.firstVisitDate!.isUtc, false);
      expect(entity.firstVisitDate!.toUtc(), DateTime.utc(2026, 10, 1, 14));
      expect(entity.lastVisitDate!.toUtc(), DateTime.utc(2026, 10, 21, 20, 30));
      expect(entity.frequencyDays, 10);
      expect(entity.totalSpent, 105000);
    });

    test('fecha null (Date inválido en el backend) → null, sin excepción', () {
      final entity = ClientStatsModel.fromJson(
          {...backendClientStats(), 'first_visit_date': null}).toEntity();
      expect(entity.firstVisitDate, isNull);
    });
  });

  test('TopClientModel', () {
    final entity = TopClientModel.fromJson(backendTopClient()).toEntity();
    expect(entity.clientId, 'cli-1');
    expect(entity.visitCount, 3);
    expect(entity.totalSpent, 105000);
  });

  group('EmployeeStatsModel', () {
    test('resumen, servicios y días del negocio tipados', () {
      final entity =
          EmployeeStatsModel.fromJson(backendEmployeeStats()).toEntity();
      expect(
          entity.summary,
          const EmployeeStatsSummary(
              totalAmount: 80000,
              paymentCount: 2,
              appointmentCount: 2,
              averagePerPayment: 40000));
      expect(
          entity.byService.single,
          const EmployeeServiceStats(
              serviceId: 'srv-1',
              serviceName: 'Cejas en hilo',
              count: 2,
              total: 90000));
      expect(entity.dailyEvolution.map((d) => d.day),
          [DateTime(2026, 10, 20), DateTime(2026, 10, 21)]);
      expect(entity.dailyEvolution.last.total, 50000);
    });

    test('rango vacío → resumen en 0 y listas vacías', () {
      final entity =
          EmployeeStatsModel.fromJson(backendEmptyEmployeeStats()).toEntity();
      expect(entity, const EmployeeStatsEntity());
      expect(entity.isEmpty, true);
    });

    test('sin claves o con un día ilegible: no rompe', () {
      expect(EmployeeStatsModel.fromJson(const {}).toEntity(),
          const EmployeeStatsEntity());
      final entity = EmployeeStatsModel.fromJson({
        ...backendEmployeeStats(),
        'daily_evolution': [
          {'date': null, 'total': 1, 'count': 1},
          {'date': '2026-10-21', 'total': '50000.00', 'count': '1'},
        ],
      }).toEntity();
      expect(entity.dailyEvolution.single.day, DateTime(2026, 10, 21));
      expect(entity.dailyEvolution.single.total, 50000);
    });
  });
}
