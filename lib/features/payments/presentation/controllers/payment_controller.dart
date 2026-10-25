import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/payments/domain/failures/payment_failures.dart';
import 'package:login_signup/features/payments/domain/usecases/create_payment_usecase.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Método propio del negocio que se ofrece en el diálogo
/// (`GET /custom-payment-methods/active`; aún sin use case: ver PLAN 4.02).
class CustomPaymentMethodOption {
  final String id;
  final String name;

  const CustomPaymentMethodOption({required this.id, required this.name});
}

/// Formulario de "Registrar pago" de una cita. Lo registra
/// `AppointmentsBinding` (ruta home, `fenix`) y lo borra el logout
/// (`SessionScope`); cada apertura del diálogo llama a [start].
class PaymentController extends GetxController {
  final CreatePaymentUseCase _createPayment;

  PaymentController({required CreatePaymentUseCase createPaymentUseCase})
      : _createPayment = createPaymentUseCase;

  final amountController = TextEditingController();
  final transactionController = TextEditingController();
  final method = PaymentMethod.CASH.obs;
  final customMethodId = RxnString();
  final isSaving = false.obs;

  /// Error de validación del monto (debajo del campo).
  final amountError = RxnString();

  /// Error de validación del método propio (debajo del selector).
  final methodError = RxnString();

  AppointmentEntity? _appointment;

  double get total => double.tryParse(_appointment?.totalPrice ?? '') ?? 0;

  bool get needsTransactionId =>
      method.value == PaymentMethod.TRANSFER ||
      method.value == PaymentMethod.ONLINE;

  /// Prepara el formulario para [appointment] con el total como monto.
  void start(AppointmentEntity appointment) {
    _appointment = appointment;
    amountController.text = total.round().toString();
    transactionController.clear();
    method.value = PaymentMethod.CASH;
    customMethodId.value = null;
    amountError.value = null;
    methodError.value = null;
    isSaving.value = false;
  }

  void selectMethod(PaymentMethod value) {
    method.value = value;
    methodError.value = null;
    if (value != PaymentMethod.CUSTOM) customMethodId.value = null;
  }

  void selectCustomMethod(String? id) {
    customMethodId.value = id;
    methodError.value = null;
  }

  /// Registra el pago. `true` si quedó guardado (el diálogo se cierra).
  /// Un monto menor que el total es un anticipo y se confirma antes.
  Future<bool> submit() async {
    final appointment = _appointment;
    if (appointment == null || isSaving.value) return false;
    amountError.value = null;
    methodError.value = null;

    final amount = parseAmount(amountController.text);
    final params = CreatePaymentParams(
      appointmentId: appointment.id,
      amount: amount ?? 0,
      method: method.value,
      customPaymentMethodId: customMethodId.value,
      transactionId: transactionController.text,
      appointmentTotal: total,
    );

    final looksValid = amount != null && amount > 0 && amount <= total;
    if (looksValid && amount < total) {
      final confirmed = await AppDialogs.confirm(
        title: '¿Registrar un anticipo?',
        message: 'Vas a registrar ${formatCop(amount)} de un total de '
            '${formatCop(total)}.',
        confirmLabel: 'Registrar anticipo',
        icon: Icons.payments_outlined,
      );
      if (!confirmed) return false;
    }

    isSaving.value = true;
    final result = await _createPayment(params);
    isSaving.value = false;

    return result.fold(
      (failure) {
        _showFailure(failure);
        return false;
      },
      (_) {
        AppSnackbar.success('Pago registrado: ${formatCop(params.amount)}');
        return true;
      },
    );
  }

  void _showFailure(Failure failure) {
    if (failure is InvalidPaymentAmountFailure) {
      amountError.value = failure.message;
    } else if (failure is ValidationFailure &&
        method.value == PaymentMethod.CUSTOM) {
      methodError.value = failure.message;
    } else if (failure is AppointmentNotPayableFailure) {
      AppSnackbar.error(AppointmentNotPayableFailure.defaultMessage,
          title: 'No se registró el pago');
    } else {
      AppSnackbar.error(failure.message, title: 'No se registró el pago');
    }
  }

  /// Texto del campo → pesos. Acepta `45000`, `45.000` y `$ 45.000`;
  /// la coma es el separador decimal. `null` si no es un número.
  static double? parseAmount(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'[\s$.]'), '')
        .replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  @override
  void onClose() {
    amountController.dispose();
    transactionController.dispose();
    super.onClose();
  }
}
