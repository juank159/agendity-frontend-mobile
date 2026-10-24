import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/enums/appointment_status_enum.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';

AppointmentEntity withStatus(String status) => AppointmentEntity(
      id: '1',
      title: 'Cita',
      startTime: DateTime(2026, 10, 21, 8),
      endTime: DateTime(2026, 10, 21, 9),
      clientName: 'Ana',
      serviceTypes: const [],
      status: status,
      totalPrice: '0',
    );

void main() {
  test('el estado del backend (mayúsculas) se reconoce', () {
    expect(withStatus('COMPLETED').isCompleted, true);
    expect(withStatus('COMPLETED').getStatusText(), 'Completado');
    expect(withStatus('CANCELLED').getStatusText(), 'Cancelado');
    expect(withStatus('CONFIRMED').statusValue, AppointmentStatus.CONFIRMED);
    expect(withStatus('CONFIRMED').getStatusText(), 'Confirmado');
  });

  test('minúsculas antiguas y desconocidos', () {
    expect(withStatus('completed').isCompleted, true);
    expect(withStatus('raro').statusValue, AppointmentStatus.PENDING);
    expect(withStatus('raro').getStatusText(), 'Pendiente');
  });
}
