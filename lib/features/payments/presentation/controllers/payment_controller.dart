import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/usecases/create_payment_usecase.dart';

class PaymentController extends GetxController {
  final CreatePaymentUseCase createPaymentUseCase;

  // Estados observables
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<PaymentMethod> selectedPaymentMethod = PaymentMethod.CASH.obs;
  final RxString transactionId = ''.obs;

  final Rx<DateTime> paymentDate = DateTime.now().toLocal().obs;

  PaymentController({
    required this.createPaymentUseCase,
  });

  Future<bool> createPayment(AppointmentEntity appointment) async {
    try {
      isLoading.value = true;
      error.value = '';

      paymentDate.value = DateTime.now().toLocal();

      final payment = PaymentEntity(
        appointmentId: appointment.id,
        amount: double.parse(appointment.totalPrice),
        paymentMethod: selectedPaymentMethod.value,
        transactionId:
            transactionId.value.isNotEmpty ? transactionId.value : null,
      );

      await createPaymentUseCase(payment);

      // Actualizar la vista de citas después de crear el pago
      if (Get.isRegistered<AppointmentsController>()) {
        final appointmentsController = Get.find<AppointmentsController>();
        appointmentsController.fetchAppointments();
      }

      Get.snackbar(
        'Éxito',
        'Pago registrado correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );

      return true;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'Error al registrar el pago: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void setPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod.value = method;
  }

  void setTransactionId(String id) {
    transactionId.value = id;
  }
}
