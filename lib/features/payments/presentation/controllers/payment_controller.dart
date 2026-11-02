import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/payments/domain/entities/custom_payment_method.dart';
import 'package:login_signup/features/payments/domain/failures/payment_failures.dart';
import 'package:login_signup/features/payments/domain/usecases/create_payment_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_active_custom_payment_methods_usecase.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/core/utils/cop_input_formatter.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Formulario de "Registrar pago" de una cita. Lo registra
/// `AppointmentsBinding` (ruta home, `fenix`) y lo borra el logout
/// (`SessionScope`); cada apertura del diálogo llama a [start].
class PaymentController extends GetxController {
  final CreatePaymentUseCase _createPayment;
  final GetActiveCustomPaymentMethodsUseCase _getCustomMethods;

  PaymentController({
    required CreatePaymentUseCase createPaymentUseCase,
    required GetActiveCustomPaymentMethodsUseCase
        getActiveCustomPaymentMethodsUseCase,
  })  : _createPayment = createPaymentUseCase,
        _getCustomMethods = getActiveCustomPaymentMethodsUseCase;

  /// Texto del `MoneyField` "Monto recibido" (`45.000`).
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
  double? _balanceDue;

  double get total => _appointment?.totalPrice ?? 0;

  /// Lo que falta por pagar (con anticipos, menos que el total). Es el
  /// máximo de este pago.
  double get balanceDue => _balanceDue ?? total;

  bool get hasPreviousPayments =>
      (balanceDue * 100).round() < (total * 100).round();

  bool get needsTransactionId =>
      method.value == PaymentMethod.TRANSFER ||
      method.value == PaymentMethod.ONLINE;

  /// Prepara el formulario para [appointment] con el saldo pendiente
  /// ([balanceDue]; sin él, el total) como monto.
  void start(AppointmentEntity appointment, {double? balanceDue}) {
    _appointment = appointment;
    _balanceDue = balanceDue;
    amountController.text = _amountText(this.balanceDue);
    transactionController.clear();
    method.value = PaymentMethod.CASH;
    customMethodId.value = null;
    amountError.value = null;
    methodError.value = null;
    isSaving.value = false;
  }

  /// Métodos propios activos para ofrecer "Otro método". Si la carga falla
  /// (sin red, o 403 del Employee) devuelve `[]`: el pago no se bloquea y no
  /// se muestra ningún error.
  Future<List<CustomPaymentMethod>> loadCustomMethods() async {
    final result = await _getCustomMethods(NoParams());
    return result.fold((_) => const [], (methods) => methods);
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
  /// Un monto menor que el saldo es un anticipo y se confirma antes.
  Future<bool> submit() async {
    final appointment = _appointment;
    if (appointment == null || isSaving.value) return false;
    amountError.value = null;
    methodError.value = null;

    // Pesos enteros del `MoneyField` (D-24: sin decimales).
    final pesos = parseCop(amountController.text);
    final amount = pesos?.toDouble();
    final params = CreatePaymentParams(
      appointmentId: appointment.id,
      amount: amount ?? 0,
      method: method.value,
      customPaymentMethodId: customMethodId.value,
      transactionId: transactionController.text,
      appointmentTotal: total,
    );

    final due = balanceDue;
    if (amount != null && _cents(amount) > _cents(due) && amount <= total) {
      amountError.value =
          'El monto no puede superar el saldo pendiente (${formatCop(due)})';
      return false;
    }
    final looksValid = amount != null && amount > 0 && amount <= due;
    if (looksValid && _cents(amount) < _cents(due)) {
      final confirmed = await AppDialogs.confirm(
        title: '¿Registrar un anticipo?',
        message: 'Vas a registrar ${formatCop(amount)} de un saldo pendiente '
            'de ${formatCop(due)}.',
        confirmLabel: 'Registrar anticipo',
        icon: Icons.payments_rounded,
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

  static int _cents(double value) => (value * 100).round();

  /// Texto inicial del campo de dinero (`45.000`; pesos enteros, D-24).
  static String _amountText(double value) =>
      CopInputFormatter.format(value.round());

  @override
  void onClose() {
    amountController.dispose();
    transactionController.dispose();
    super.onClose();
  }
}
