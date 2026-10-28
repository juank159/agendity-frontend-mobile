import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/create_paid_subscription_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/get_all_plans_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/get_current_subscription_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/refresh_subscription_status_usecase.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Estado de la carga de la pantalla de planes.
enum SubscriptionLoadStatus { loading, ready, error }

/// Resultado de verificar un pago contra el backend.
enum PaymentVerificationStatus {
  idle,
  verifying,

  /// Estado efectivo `active` y sin intento pendiente.
  approved,

  /// Wompi aún no confirma el intento (`pending_payment`).
  pending,

  /// Sin intento pendiente ni plan activo (rechazado o no encontrado).
  failed,

  /// No se pudo consultar al backend.
  error,
}

/// Compra de un plan (solo Owner; las rutas llevan `RoleMiddleware.ownerOnly()`):
/// estado de la suscripción, planes, inicio del pago y su verificación real.
///
/// Lo comparten la pantalla de planes y la webview de pago. El pago solo se
/// da por hecho cuando el backend lo confirma: `refresh-status` (consulta
/// Wompi y aplica el intento) y luego `GET /status` con estado `active`.
class SubscriptionController extends GetxController {
  final GetCurrentSubscriptionUseCase _getStatus;
  final GetAllPlansUseCase _getPlans;
  final CreatePaidSubscriptionUseCase _subscribe;
  final RefreshSubscriptionStatusUseCase _refreshStatus;

  SubscriptionController({
    required GetCurrentSubscriptionUseCase getCurrentSubscriptionUseCase,
    required GetAllPlansUseCase getAllPlansUseCase,
    required CreatePaidSubscriptionUseCase createPaidSubscriptionUseCase,
    required RefreshSubscriptionStatusUseCase refreshSubscriptionStatusUseCase,
  })  : _getStatus = getCurrentSubscriptionUseCase,
        _getPlans = getAllPlansUseCase,
        _subscribe = createPaidSubscriptionUseCase,
        _refreshStatus = refreshSubscriptionStatusUseCase;

  final status = SubscriptionLoadStatus.loading.obs;
  final loadError = RxnString();
  final subscription = Rxn<SubscriptionEntity>();
  final plans = <SubscriptionPlanEntity>[].obs;

  /// Plan cuyo enlace de pago se está pidiendo.
  final startingPlanId = RxnString();

  final verification = PaymentVerificationStatus.idle.obs;
  final verificationMessage = ''.obs;

  /// Suscripción confirmada por la última verificación aprobada.
  SubscriptionEntity? verifiedSubscription;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Estado de la suscripción y planes, en paralelo.
  Future<void> load() async {
    status.value = SubscriptionLoadStatus.loading;
    loadError.value = null;
    final statusRequest = _getStatus(NoParams());
    final plansRequest = _getPlans(NoParams());
    final statusResult = await statusRequest;
    final plansResult = await plansRequest;

    final failure = statusResult.fold((f) => f, (s) {
          subscription.value = s;
          return null;
        }) ??
        plansResult.fold((f) => f, (p) {
          plans.assignAll(p);
          return null;
        });
    if (failure != null) {
      loadError.value = failure.message;
      status.value = SubscriptionLoadStatus.error;
      return;
    }
    status.value = SubscriptionLoadStatus.ready;
  }

  /// Pide el enlace de pago de [plan] y abre la webview. Al volver de ella
  /// recarga el estado (el pago pudo quedar confirmado o pendiente).
  Future<void> startPayment(SubscriptionPlanEntity plan) async {
    if (startingPlanId.value != null) return;
    if (subscription.value?.hasPendingPayment ?? false) {
      final proceed = await AppDialogs.confirm(
        title: 'Tienes un pago en verificación',
        message: 'Si ya pagaste, verifica ese pago antes de iniciar otro para '
            'no pagar dos veces.',
        confirmLabel: 'Pagar otro plan',
        cancelLabel: 'Cancelar',
      );
      if (!proceed) return;
    }

    startingPlanId.value = plan.id;
    final result = await _subscribe(plan.id);
    startingPlanId.value = null;

    await result.fold(
      (failure) async =>
          AppSnackbar.error('No se pudo iniciar el pago: ${failure.message}'),
      (checkout) async {
        resetVerification();
        await Get.toNamed(GetRoutes.paymentWebview,
            arguments: {'url': checkout.paymentLink});
        // Tras un pago aprobado la app va a paymentSuccess y esta pantalla
        // (con su controller) ya no existe.
        if (!isClosed) await load();
      },
    );
  }

  /// Verificación real del pago: `refresh-status` y después el estado
  /// efectivo. Éxito solo si es `active` sin intento pendiente.
  Future<PaymentVerificationStatus> verifyPayment() async {
    if (verification.value == PaymentVerificationStatus.verifying) {
      return verification.value;
    }
    verification.value = PaymentVerificationStatus.verifying;
    verificationMessage.value = '';

    final refreshed = await _refreshStatus(NoParams());
    final refreshFailure = refreshed.fold((f) => f, (_) => null);
    if (refreshFailure != null) {
      return _verificationError(refreshFailure);
    }

    final current = await _getStatus(NoParams());
    return current.fold(_verificationError, (value) {
      subscription.value = value;
      if (value.hasPendingPayment) {
        verificationMessage.value =
            'Tu pago aún no ha sido confirmado. Puede tardar unos minutos.';
        return verification.value = PaymentVerificationStatus.pending;
      }
      if (value.isActive) {
        verifiedSubscription = value;
        verificationMessage.value = 'Plan ${value.plan!.name} activo';
        return verification.value = PaymentVerificationStatus.approved;
      }
      verificationMessage.value =
          'No encontramos un pago confirmado. Si Wompi rechazó el pago, '
          'puedes intentarlo de nuevo con otro medio.';
      return verification.value = PaymentVerificationStatus.failed;
    });
  }

  /// "Verificar pago" desde la pantalla de planes (pago en verificación).
  Future<void> verifyPendingPayment() async {
    final result = await verifyPayment();
    switch (result) {
      case PaymentVerificationStatus.approved:
        Get.offAllNamed(GetRoutes.paymentSuccess,
            arguments: verifiedSubscription);
        return;
      case PaymentVerificationStatus.pending:
        AppSnackbar.info(verificationMessage.value,
            title: 'Pago en verificación');
      case PaymentVerificationStatus.failed:
        AppSnackbar.warning(verificationMessage.value,
            title: 'Pago no confirmado');
      case PaymentVerificationStatus.error:
        AppSnackbar.error(verificationMessage.value);
      case PaymentVerificationStatus.idle:
      case PaymentVerificationStatus.verifying:
        break;
    }
    resetVerification();
  }

  void resetVerification() {
    verification.value = PaymentVerificationStatus.idle;
    verificationMessage.value = '';
  }

  PaymentVerificationStatus _verificationError(Failure failure) {
    verificationMessage.value = failure is NetworkFailure
        ? 'No se pudo verificar el pago. Revisa tu conexión e inténtalo de nuevo.'
        : 'No se pudo verificar el pago: ${failure.message}';
    return verification.value = PaymentVerificationStatus.error;
  }
}
