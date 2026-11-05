import 'package:login_signup/common/enums/appointment_payment_status_enum.dart';
import 'package:login_signup/common/enums/appointment_status_enum.dart';
import 'package:login_signup/core/utils/deep_equality.dart';

/// Reparto de un importe (COP) entre el profesional y el negocio.
class CommissionAmounts {
  /// Suma de los precios guardados en las líneas de las citas.
  final double servicesTotal;

  /// Comisión del profesional.
  final double professionalTotal;

  /// Lo que queda para el negocio (`servicesTotal − professionalTotal`).
  /// `null` = el servidor no lo envía: a la empleada nunca se le dice (D-27).
  final double? businessTotal;

  const CommissionAmounts({
    this.servicesTotal = 0,
    this.professionalTotal = 0,
    this.businessTotal = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommissionAmounts &&
          other.servicesTotal == servicesTotal &&
          other.professionalTotal == professionalTotal &&
          other.businessTotal == businessTotal;

  @override
  int get hashCode =>
      Object.hash(servicesTotal, professionalTotal, businessTotal);
}

/// Un servicio de una cita completada con su % congelado (D-16).
class CommissionLine {
  final String serviceId;
  final String serviceName;
  final double price;
  final double commissionPercentage;
  final double commission;

  const CommissionLine({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.commissionPercentage,
    required this.commission,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommissionLine &&
          other.serviceId == serviceId &&
          other.serviceName == serviceName &&
          other.price == price &&
          other.commissionPercentage == commissionPercentage &&
          other.commission == commission;

  @override
  int get hashCode => Object.hash(
      serviceId, serviceName, price, commissionPercentage, commission);
}

/// Cita de la liquidación: completada (lo ganado) o, en
/// [CommissionSettlement.pending], pendiente o confirmada (lo que está por
/// ganar, D-27).
class CommissionAppointment {
  final String appointmentId;

  /// Hora de pared en la zona de la cita ([timeZone], 6.03).
  final DateTime date;
  final String? timeZone;
  final String clientName;
  final CommissionAmounts amounts;
  final List<CommissionLine> lines;

  /// Solo en las citas por ganar: `PENDING` o `CONFIRMED`. `null` en las
  /// completadas (o si el servidor no lo envía).
  final AppointmentStatus? status;

  /// Solo en las citas por ganar: si ya se pagó (`COMPLETED`), en parte
  /// (`PARTIAL`) o nada (`PENDING`). `null` si no se sabe.
  final AppointmentPaymentStatus? paymentStatus;

  /// Lo pagado neto de la cita, si el servidor lo envía.
  final double? paidAmount;

  const CommissionAppointment({
    required this.appointmentId,
    required this.date,
    this.timeZone,
    required this.clientName,
    required this.amounts,
    this.lines = const [],
    this.status,
    this.paymentStatus,
    this.paidAmount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommissionAppointment &&
          other.appointmentId == appointmentId &&
          other.date == date &&
          other.timeZone == timeZone &&
          other.clientName == clientName &&
          other.amounts == amounts &&
          DeepEquality.lists(other.lines, lines) &&
          other.status == status &&
          other.paymentStatus == paymentStatus &&
          other.paidAmount == paidAmount;

  @override
  int get hashCode => Object.hash(appointmentId, date, timeZone, clientName,
      amounts, Object.hashAll(lines), status, paymentStatus, paidAmount);
}

/// Lo que le toca a un profesional en el periodo, con el detalle por cita.
class ProfessionalCommission {
  final String professionalId;
  final String professionalName;
  final int appointmentCount;
  final CommissionAmounts amounts;

  /// Ordenadas por fecha.
  final List<CommissionAppointment> appointments;

  const ProfessionalCommission({
    required this.professionalId,
    required this.professionalName,
    required this.appointmentCount,
    required this.amounts,
    this.appointments = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfessionalCommission &&
          other.professionalId == professionalId &&
          other.professionalName == professionalName &&
          other.appointmentCount == appointmentCount &&
          other.amounts == amounts &&
          DeepEquality.lists(other.appointments, appointments);

  @override
  int get hashCode => Object.hash(professionalId, professionalName,
      appointmentCount, amounts, Object.hashAll(appointments));
}

/// Liquidación de comisiones de un periodo (`GET /payments/stats/commissions`,
/// 8.02): solo citas **COMPLETED** del periodo (días completos del negocio),
/// con el precio y el % guardados en cada línea. Owner: todos (o uno);
/// Employee: solo lo suyo, sin lo del negocio (`businessTotal` null, D-27).
/// Sin citas: totales en 0 y lista vacía.
///
/// [pending] (D-27): la misma liquidación para las citas `PENDING` y
/// `CONFIRMED` del periodo, lo que está "por ganar" hasta que el negocio las
/// complete. `null` si el servidor no lo envía.
class CommissionSettlement {
  /// Días del negocio (sin hora).
  final DateTime? startDay;
  final DateTime? endDay;
  final String? timeZone;
  final CommissionAmounts totals;
  final int appointmentCount;

  /// Ordenados por nombre.
  final List<ProfessionalCommission> professionals;

  /// Citas por ganar (pendientes y confirmadas) con la misma forma.
  final CommissionSettlement? pending;

  const CommissionSettlement({
    this.startDay,
    this.endDay,
    this.timeZone,
    required this.totals,
    this.appointmentCount = 0,
    this.professionals = const [],
    this.pending,
  });

  bool get isEmpty => professionals.isEmpty;

  /// Ni completadas ni por ganar.
  bool get isEmptyWithPending => isEmpty && (pending?.isEmpty ?? true);

  /// Las citas de todos los profesionales, por fecha (la empleada solo tiene
  /// las suyas).
  List<CommissionAppointment> get appointments => [
        for (final professional in professionals) ...professional.appointments,
      ]..sort((a, b) => a.date.compareTo(b.date));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommissionSettlement &&
          other.startDay == startDay &&
          other.endDay == endDay &&
          other.timeZone == timeZone &&
          other.totals == totals &&
          other.appointmentCount == appointmentCount &&
          DeepEquality.lists(other.professionals, professionals) &&
          other.pending == pending;

  @override
  int get hashCode => Object.hash(startDay, endDay, timeZone, totals,
      appointmentCount, Object.hashAll(professionals), pending);
}
