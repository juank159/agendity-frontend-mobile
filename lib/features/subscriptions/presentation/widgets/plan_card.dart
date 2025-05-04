// lib/features/subscriptions/presentation/widgets/plan_card.dart

import 'package:flutter/material.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';

class PlanCard extends StatelessWidget {
  final SubscriptionPlanEntity plan;
  final bool isRecommended;
  final VoidCallback onTap;

  const PlanCard({
    Key? key,
    required this.plan,
    required this.isRecommended,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isRecommended
                ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          plan.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isRecommended
                                        ? Theme.of(context).primaryColor
                                        : Colors.black,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildPlanIcon(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    plan.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildPriceRow(context),
                  const SizedBox(height: 16),
                  _buildFeaturesList(context),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRecommended
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade200,
                        foregroundColor: isRecommended
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Seleccionar Plan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isRecommended)
          Positioned(
            top: -10,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Recomendado',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlanIcon() {
    IconData iconData;
    Color iconColor;

    if (plan.name.toLowerCase().contains('mensual')) {
      iconData = Icons.calendar_month;
      iconColor = Colors.blue;
    } else if (plan.name.toLowerCase().contains('semestral')) {
      iconData = Icons.calendar_today;
      iconColor = Colors.green;
    } else if (plan.name.toLowerCase().contains('anual')) {
      iconData = Icons.event_available;
      iconColor = Colors.purple;
    } else {
      iconData = Icons.schedule;
      iconColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context) {
    final bool isMonthly = plan.billingInterval == 'month' &&
        !plan.name.toLowerCase().contains('semestral');
    final bool isAnnual = plan.billingInterval == 'year' ||
        plan.name.toLowerCase().contains('anual');
    final bool isSemestral = plan.name.toLowerCase().contains('semestral');

    String period;
    if (isMonthly) {
      period = '/mes';
    } else if (isSemestral) {
      period = '/6 meses';
    } else if (isAnnual) {
      period = '/año';
    } else {
      period = '';
    }

    final formattedPrice = _formatCurrency(plan.price, plan.currency);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formattedPrice,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isRecommended
                    ? Theme.of(context).primaryColor
                    : Colors.black,
              ),
        ),
        Text(
          period,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    List<String> features = plan.features ?? [];

    // Si no hay características definidas, generamos algunas basadas en el plan
    if (features.isEmpty) {
      features = [
        'Citas ilimitadas',
        'Soporte 24/7',
      ];

      if (plan.name.toLowerCase().contains('semestral') ||
          plan.name.toLowerCase().contains('anual')) {
        features.add('Análisis de clientes');
      }

      if (plan.name.toLowerCase().contains('anual')) {
        features.add('Reportes personalizados');
        features.add('Prioridad en soporte técnico');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features
          .map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  String _formatCurrency(double price, String currency) {
    String symbol = currency == 'COP' ? '\$' : currency;

    if (currency == 'COP') {
      // Formato para peso colombiano
      return '$symbol ${price.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          )}';
    } else {
      // Formato general
      return '$symbol ${price.toStringAsFixed(2)}';
    }
  }
}
