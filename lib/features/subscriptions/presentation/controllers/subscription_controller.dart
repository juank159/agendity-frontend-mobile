import 'package:login_signup/core/routes/routes.dart';

import 'package:flutter/material.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_limits_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/create_paid_subscription_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/get_all_plans_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/get_current_subscription_usecase.dart';

/// Estado de la verificación de un pago contra el backend.
enum PaymentVerificationStatus {
  idle,
  verifying,
  approved,
  pending,
  failed,
  error
}

class SubscriptionController extends GetxController {
  final CheckSubscriptionLimitsUseCase checkSubscriptionLimitsUseCase;
  final GetAllPlansUseCase getAllPlansUseCase;
  final CreatePaidSubscriptionUseCase createPaidSubscriptionUseCase;
  final GetCurrentSubscriptionUseCase getCurrentSubscriptionUseCase;

  // Estado
  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final RxBool canCreateAppointment = true.obs;
  final RxString statusMessage = ''.obs;
  final RxList<SubscriptionPlanEntity> plans = <SubscriptionPlanEntity>[].obs;
  final RxString paymentUrl = ''.obs;
  final Rx<SubscriptionPlanEntity?> selectedPlan =
      Rx<SubscriptionPlanEntity?>(null);

  // Verificación del pago (pantalla de la webview)
  final Rx<PaymentVerificationStatus> paymentVerification =
      PaymentVerificationStatus.idle.obs;
  final RxString paymentVerificationMessage = ''.obs;

  SubscriptionController({
    required this.checkSubscriptionLimitsUseCase,
    required this.getAllPlansUseCase,
    required this.createPaidSubscriptionUseCase,
    required this.getCurrentSubscriptionUseCase,
  });

  @override
  void onInit() {
    super.onInit();
    checkStatus();
    loadPlans();
  }

  // Verifica el estado de la suscripción
  Future<bool> checkStatus() async {
    isLoading.value = true;
    error.value = null;
    final result = await checkSubscriptionLimitsUseCase(NoParams());
    isLoading.value = false;
    return result.fold(
      (failure) {
        error.value = failure.message;
        return false;
      },
      (limits) {
        canCreateAppointment.value = limits.canCreateAppointment;
        statusMessage.value = limits.message;
        return limits.canCreateAppointment;
      },
    );
  }

  // Carga los planes disponibles
  Future<void> loadPlans() async {
    isLoading.value = true;
    error.value = null;
    final result = await getAllPlansUseCase(NoParams());
    isLoading.value = false;
    result.fold(
      (failure) => error.value = failure.message,
      (result) => plans.assignAll(result),
    );
  }

  /// Crea una suscripción pagada y devuelve el link de pago del backend.
  /// Devuelve '' si el backend no entrega link y lanza la [Failure] si falla:
  /// nunca inventa un link de demostración.
  Future<String> createSubscription(String planId) async {
    isLoading.value = true;
    final result = await createPaidSubscriptionUseCase(planId);
    isLoading.value = false;
    return result.fold(
      (failure) => throw failure,
      (checkout) => paymentUrl.value = checkout.paymentLink,
    );
  }

  // Método para abrir WebView con el link de pago
  void openPaymentLink(String planId) async {
    try {
      // Establecer el plan seleccionado
      selectedPlan.value = plans.firstWhere((plan) => plan.id == planId);

      final url = await createSubscription(planId);

      if (url.isNotEmpty) {
        print('SubscriptionController - Abriendo WebView con URL: $url');
        resetPaymentVerification();
        Get.toNamed(GetRoutes.paymentWebview, arguments: {'url': url});
      } else {
        print('SubscriptionController - URL vacía, no se puede abrir WebView');
        Get.snackbar(
          'Error',
          'El servidor no devolvió un link de pago. Inténtalo de nuevo más tarde.',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('SubscriptionController - Error al abrir WebView: $e');
      Get.snackbar(
        'Error',
        e is Failure
            ? 'No se pudo iniciar el pago: ${e.message}'
            : 'No se pudo iniciar el pago: ${e.toString()}',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Consulta en el backend si el pago quedó confirmado.
  ///
  /// Solo `status == 'active'` cuenta como pagado. No se usa la URL de la
  /// webview para decidir. Nota: hasta la tarea 2.03 el backend puede devolver
  /// la suscripción de otro tenant.
  Future<PaymentVerificationStatus> verifyPayment() async {
    paymentVerification.value = PaymentVerificationStatus.verifying;
    paymentVerificationMessage.value = '';

    final result = await getCurrentSubscriptionUseCase(NoParams());
    final subscription = result.fold((_) => null, (s) => s);
    if (subscription == null) {
      paymentVerification.value = PaymentVerificationStatus.error;
      paymentVerificationMessage.value =
          'No se pudo verificar el estado del pago. Revisa tu conexión e inténtalo de nuevo.';
    } else if (subscription.isActive) {
      paymentVerification.value = PaymentVerificationStatus.approved;
      paymentVerificationMessage.value = 'Plan ${subscription.plan!.name} activo';
      selectedPlan.value = subscription.plan;
      await checkStatus();
    } else if (subscription.hasPendingPayment) {
      paymentVerification.value = PaymentVerificationStatus.pending;
      paymentVerificationMessage.value =
          'Tu pago aún no ha sido confirmado. Puede tardar unos minutos.';
    } else {
      paymentVerification.value = PaymentVerificationStatus.failed;
      paymentVerificationMessage.value =
          'No encontramos un pago confirmado para tu suscripción.';
    }

    return paymentVerification.value;
  }

  /// El usuario rechazó el pago (flujo de demostración).
  void markPaymentRejected() {
    paymentVerification.value = PaymentVerificationStatus.failed;
    paymentVerificationMessage.value =
        'Tu pago no pudo ser procesado. Intenta nuevamente con otro método de pago.';
  }

  void resetPaymentVerification() {
    paymentVerification.value = PaymentVerificationStatus.idle;
    paymentVerificationMessage.value = '';
  }
}
