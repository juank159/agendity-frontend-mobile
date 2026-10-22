import 'package:login_signup/core/routes/routes.dart';

import 'package:flutter/material.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_status_usecase.dart';
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
  final CheckSubscriptionStatusUseCase checkSubscriptionStatusUseCase;
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
    required this.checkSubscriptionStatusUseCase,
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
    try {
      isLoading.value = true;
      error.value = null;

      final result = await checkSubscriptionStatusUseCase();

      canCreateAppointment.value = result['canCreateAppointment'] ?? false;
      statusMessage.value = result['message'] ?? '';

      print('SubscriptionController - Estado: ${canCreateAppointment.value}');
      print('SubscriptionController - Mensaje: ${statusMessage.value}');

      return canCreateAppointment.value;
    } catch (e) {
      print('SubscriptionController - Error en checkStatus: $e');
      error.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Carga los planes disponibles
  Future<void> loadPlans() async {
    try {
      isLoading.value = true;
      error.value = null;

      final result = await getAllPlansUseCase();

      if (result.isEmpty) {
        print('SubscriptionController - No se encontraron planes disponibles');
      } else {
        print('SubscriptionController - Planes cargados: ${result.length}');
        // Imprimir detalles de los planes para depuración
        for (int i = 0; i < result.length; i++) {
          print(
              'Plan ${i + 1}: ${result[i].name} - ${result[i].price} ${result[i].currency}');
        }
      }

      plans.assignAll(result);
    } catch (e) {
      print('SubscriptionController - Error en loadPlans: $e');
      error.value = e.toString();

      // Mostrar snackbar con error
      Get.snackbar(
        'Error',
        'No se pudieron cargar los planes: ${e.toString()}',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Crea una suscripción pagada y devuelve el link de pago del backend.
  /// Devuelve '' si el backend no entrega link y lanza la [Failure] si falla:
  /// nunca inventa un link de demostración.
  Future<String> createSubscription(String planId) async {
    try {
      isLoading.value = true;

      // El backend acepta myapp:// y lo reemplaza para Wompi.
      const redirectUrl = 'myapp://payment-callback';
      final result = await createPaidSubscriptionUseCase(planId, redirectUrl);

      paymentUrl.value = (result['payment_link'] as String?) ?? '';
      return paymentUrl.value;
    } finally {
      isLoading.value = false;
    }
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

    try {
      final subscription = await getCurrentSubscriptionUseCase();

      switch (subscription.status) {
        case 'active':
          paymentVerification.value = PaymentVerificationStatus.approved;
          paymentVerificationMessage.value = subscription.statusMessage;
          if (subscription.plan != null) {
            selectedPlan.value = subscription.plan;
          }
          await checkStatus();
          break;
        case 'pending':
          paymentVerification.value = PaymentVerificationStatus.pending;
          paymentVerificationMessage.value =
              'Tu pago aún no ha sido confirmado. Puede tardar unos minutos.';
          break;
        default:
          paymentVerification.value = PaymentVerificationStatus.failed;
          paymentVerificationMessage.value =
              'No encontramos un pago confirmado para tu suscripción.';
      }
    } catch (e) {
      paymentVerification.value = PaymentVerificationStatus.error;
      paymentVerificationMessage.value =
          'No se pudo verificar el estado del pago. Revisa tu conexión e inténtalo de nuevo.';
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
