import 'package:login_signup/common/enums/appointment_payment_status_enum.dart';
import 'package:login_signup/common/enums/appointment_status_enum.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/statistics/domain/entities/commission_settlement.dart';

/// DTO de `GET /payments/stats/commissions` (8.02):
/// `{start, end, timezone, totals: {services_total, professional_total,
/// business_total, appointment_count}, professionals: [{professional_id,
/// professional_name, appointment_count, …totales, appointments: [{
/// appointment_id, date, timezone, client_name, …totales, lines: [{
/// service_id, service_name, price, commission_percentage, commission}]}]}]}`.
/// Importes en número (ya sumados en centavos por el backend).
///
/// D-27 (13.10): `pending` = la misma forma para las citas PENDING/CONFIRMED
/// del periodo; cada cita trae además `status`, `payment_status` y quizá
/// `paid_amount`. A la empleada no le llega `business_total` en ningún nivel
/// (ausente o `null` → `businessTotal` null).
abstract final class CommissionSettlementModel {
  static CommissionSettlement fromJson(Map<String, dynamic> json) {
    final totals = JsonRead.asMap(json['totals']) ?? const {};
    final pending = JsonRead.asMap(json['pending']);
    return CommissionSettlement(
      startDay: DateCodec.tryDecodeDay(json['start']),
      endDay: DateCodec.tryDecodeDay(json['end']),
      timeZone: JsonRead.asOptionalString(json['timezone']),
      totals: _amounts(totals),
      appointmentCount: JsonRead.asInt(totals['appointment_count']),
      professionals: JsonRead.asMapList(json['professionals'])
          .map(_professional)
          .toList(growable: false),
      pending: pending == null ? null : _pending(json, pending),
    );
  }

  /// `pending` no repite el periodo: se toma el de la liquidación.
  static CommissionSettlement _pending(
          Map<String, dynamic> parent, Map<String, dynamic> pending) =>
      fromJson({
        'start': parent['start'],
        'end': parent['end'],
        'timezone': parent['timezone'],
        ...pending,
      }..remove('pending'));

  static CommissionAmounts _amounts(Map<String, dynamic> json) =>
      CommissionAmounts(
        servicesTotal: JsonRead.asDouble(json['services_total']),
        professionalTotal: JsonRead.asDouble(json['professional_total']),
        businessTotal: json['business_total'] == null
            ? null
            : JsonRead.asDouble(json['business_total']),
      );

  static ProfessionalCommission _professional(Map<String, dynamic> json) =>
      ProfessionalCommission(
        professionalId: JsonRead.asString(json['professional_id']),
        professionalName: JsonRead.asString(json['professional_name']),
        appointmentCount: JsonRead.asInt(json['appointment_count']),
        amounts: _amounts(json),
        appointments: [
          for (final row in JsonRead.asMapList(json['appointments']))
            if (_appointment(row) case final appointment?) appointment,
        ],
      );

  /// Sin fecha legible no se puede mostrar: se descarta.
  static CommissionAppointment? _appointment(Map<String, dynamic> json) {
    final timeZone = JsonRead.asOptionalString(json['timezone']);
    final date = DateCodec.tryDecode(json['date'], timeZone: timeZone);
    if (date == null) return null;
    return CommissionAppointment(
      appointmentId: JsonRead.asString(json['appointment_id']),
      date: date,
      timeZone: timeZone,
      clientName: JsonRead.asString(json['client_name']),
      amounts: _amounts(json),
      status: AppointmentStatus.fromApi(json['status']),
      paymentStatus: AppointmentPaymentStatus.fromApi(json['payment_status']),
      paidAmount: json['paid_amount'] == null
          ? null
          : JsonRead.asDouble(json['paid_amount']),
      lines: [
        for (final line in JsonRead.asMapList(json['lines']))
          CommissionLine(
            serviceId: JsonRead.asString(line['service_id']),
            serviceName: JsonRead.asString(line['service_name']),
            price: JsonRead.asDouble(line['price']),
            commissionPercentage:
                JsonRead.asDouble(line['commission_percentage']),
            commission: JsonRead.asDouble(line['commission']),
          ),
      ],
    );
  }
}
