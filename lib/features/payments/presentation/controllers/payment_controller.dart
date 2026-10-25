import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
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
    isLoading.value = true;
    error.value = '';
    paymentDate.value = DateTime.now().toLocal();

    final total = double.tryParse(appointment.totalPrice) ?? 0;
    final result = await createPaymentUseCase(CreatePaymentParams(
      appointmentId: appointment.id,
      amount: total,
      method: selectedPaymentMethod.value,
      transactionId: transactionId.value,
      appointmentTotal: total,
    ));
    isLoading.value = false;

    return result.fold(
      (failure) {
        error.value = failure.message;
        Get.snackbar(
          'Error',
          'Error al registrar el pago: ${failure.message}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
        );
        return false;
      },
      (_) {
        // Actualizar la vista de citas después de crear el pago
        if (Get.isRegistered<AppointmentsController>()) {
          Get.find<AppointmentsController>().fetchAppointments();
        }
        Get.snackbar(
          'Éxito',
          'Pago registrado correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
        return true;
      },
    );
  }

  void setPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod.value = method;
  }

  void setTransactionId(String id) {
    transactionId.value = id;
  }
}
