// lib/features/subscriptions/presentation/screens/subscription_plans_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/features/subscriptions/presentation/controllers/subscription_controller.dart';
import 'package:login_signup/features/subscriptions/presentation/widgets/plan_card.dart';

class SubscriptionPlansScreen extends GetView<SubscriptionController> {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes de Suscripción'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${controller.error.value}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadPlans(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildPlansList(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.blue.shade50,
      width: double.infinity,
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            size: 40,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            'Tu plan de prueba ha finalizado',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            controller.statusMessage.value,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona un plan para continuar usando todas las funcionalidades',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList() {
    if (controller.plans.isEmpty) {
      return const Center(
        child: Text(
          'No hay planes disponibles en este momento',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Identificar planes especiales
    final SubscriptionPlanEntity? monthlyPlan =
        controller.plans.firstWhereOrNull(
      (plan) => plan.name.toLowerCase().contains('mensual'),
    );

    final SubscriptionPlanEntity? semestralPlan =
        controller.plans.firstWhereOrNull(
      (plan) => plan.name.toLowerCase().contains('semestral'),
    );

    final SubscriptionPlanEntity? annualPlan =
        controller.plans.firstWhereOrNull(
      (plan) => plan.name.toLowerCase().contains('anual'),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (monthlyPlan != null)
          PlanCard(
            plan: monthlyPlan,
            isRecommended: false,
            onTap: () => controller.openPaymentLink(monthlyPlan.id),
          ),

        const SizedBox(height: 16),

        if (semestralPlan != null)
          PlanCard(
            plan: semestralPlan,
            isRecommended: true, // Marcar el plan semestral como recomendado
            onTap: () => controller.openPaymentLink(semestralPlan.id),
          ),

        const SizedBox(height: 16),

        if (annualPlan != null)
          PlanCard(
            plan: annualPlan,
            isRecommended: false,
            onTap: () => controller.openPaymentLink(annualPlan.id),
          ),

        const SizedBox(height: 32),

        // Planes restantes (si hay otros)
        ...controller.plans
            .where((plan) =>
                plan.id != monthlyPlan?.id &&
                plan.id != semestralPlan?.id &&
                plan.id != annualPlan?.id)
            .map((plan) => Column(
                  children: [
                    PlanCard(
                      plan: plan,
                      isRecommended: false,
                      onTap: () => controller.openPaymentLink(plan.id),
                    ),
                    const SizedBox(height: 16),
                  ],
                )),
      ],
    );
  }
}
