import 'package:flutter/material.dart';

class AppointmentEntity {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String clientName;
  final List<String> serviceTypes;
  final String? notes;
  final String status;
  final List<String>? colors;
  final String? ownerId;
  final String? professionalId;
  final String? paymentStatus;
  final String totalPrice;

  // Estados de pago que coinciden con el backend
  static const String PAYMENT_PENDING = 'PENDING';
  static const String PAYMENT_COMPLETED = 'COMPLETED';
  static const String PAYMENT_FAILED = 'FAILED';
  static const String PAYMENT_REFUNDED = 'REFUNDED';
  static const String PAYMENT_CANCELLED = 'CANCELLED';

  // Estados de la cita
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_COMPLETED = 'completed';
  static const String STATUS_CANCELLED = 'cancelled';

  const AppointmentEntity({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.clientName,
    required this.serviceTypes,
    required this.status,
    required this.totalPrice,
    this.paymentStatus,
    this.notes,
    this.colors,
    this.ownerId,
    this.professionalId,
  });

  // Métodos de utilidad
  bool get isCompleted => status == STATUS_COMPLETED;
  bool get isPaymentCompleted => paymentStatus == PAYMENT_COMPLETED;

  // Obtener el primer color o un color por defecto
  Color getPrimaryColor() {
    if (colors != null && colors!.isNotEmpty) {
      try {
        final colorStr = colors![0].replaceAll('#', '');
        return Color(int.parse('FF$colorStr', radix: 16));
      } catch (e) {
        return Colors.orange;
      }
    }
    return Colors.orange;
  }

  Color getStatusColor() {
    switch (status) {
      case STATUS_COMPLETED:
        return Colors.green;
      case STATUS_CANCELLED:
        return Colors.red;
      case STATUS_PENDING:
      default:
        return Colors.orange;
    }
  }

  String getStatusText() {
    switch (status) {
      case STATUS_COMPLETED:
        return 'Completado';
      case STATUS_CANCELLED:
        return 'Cancelado';
      case STATUS_PENDING:
      default:
        return 'Pendiente';
    }
  }

  Color getPaymentStatusColor() {
    switch (paymentStatus) {
      case PAYMENT_COMPLETED:
        return Colors.green;
      case PAYMENT_FAILED:
        return Colors.red;
      case PAYMENT_REFUNDED:
        return Colors.blue;
      case PAYMENT_CANCELLED:
        return Colors.red;
      case PAYMENT_PENDING:
      default:
        return Colors.orange;
    }
  }

  String getPaymentStatusText() {
    switch (paymentStatus) {
      case PAYMENT_COMPLETED:
        return 'Pagado';
      case PAYMENT_FAILED:
        return 'Fallido';
      case PAYMENT_REFUNDED:
        return 'Reembolsado';
      case PAYMENT_CANCELLED:
        return 'Cancelado';
      case PAYMENT_PENDING:
      default:
        return 'Pendiente';
    }
  }

  @override
  String toString() {
    return 'AppointmentEntity(id: $id, title: $title, startTime: $startTime, endTime: $endTime, clientName: $clientName, serviceTypes: $serviceTypes, notes: $notes, status: $status, colors: $colors, ownerId: $ownerId, professionalId: $professionalId, paymentStatus: $paymentStatus, totalPrice: $totalPrice)';
  }
}
