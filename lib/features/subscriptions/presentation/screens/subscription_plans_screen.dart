import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import '../controllers/subscription_controller.dart';
import '../widgets/plan_card.dart';
import '../widgets/subscription_status_card.dart';

/// Estado de la suscripción del negocio y planes para comprar (solo Owner).
class SubscriptionPlansScreen extends GetView<SubscriptionController> {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planes')),
      body: Obx(() {
        switch (controller.status.value) {
          case SubscriptionLoadStatus.loading:
            return const LoadingState(message: 'Cargando planes…');
          case SubscriptionLoadStatus.error:
            return ErrorState(
              title: 'No se pudo cargar',
              message: controller.loadError.value ?? '',
              onRetry: controller.load,
            );
          case SubscriptionLoadStatus.ready:
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (controller.subscription.value case final subscription?)
                    SubscriptionStatusCard(
                      subscription: subscription,
                      isVerifying: controller.verification.value ==
                          PaymentVerificationStatus.verifying,
                      onVerifyPending: controller.verifyPendingPayment,
                    ),
                  const SizedBox(height: 16),
                  ListStateView<SubscriptionPlanEntity>(
                    isLoading: false,
                    items: controller.plans,
                    emptyIcon: Icons.workspace_premium_outlined,
                    emptyMessage: 'No hay planes disponibles en este momento',
                    builder: (context, plans) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final plan in plans) _plan(plan),
                      ],
                    ),
                  ),
                ],
              ),
            );
        }
      }),
    );
  }

  Widget _plan(SubscriptionPlanEntity plan) {
    final current = controller.subscription.value;
    final starting = controller.startingPlanId.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PlanCard(
        plan: plan,
        isCurrent: (current?.isActive ?? false) && current?.plan?.id == plan.id,
        isStarting: starting == plan.id,
        onSelect: starting == null ? () => controller.startPayment(plan) : null,
      ),
    );
  }
}
