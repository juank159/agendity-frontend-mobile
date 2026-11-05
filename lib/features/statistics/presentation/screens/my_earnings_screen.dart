import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/commissions_controller.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/my_earnings_view.dart';
import '../widgets/stats_section_view.dart';

/// "Mis ganancias" (`/my-earnings`, D-27): la única pantalla de números de
/// la empleada. Lo ganado (citas completadas), lo que está por ganar
/// (pendientes y confirmadas) y el detalle por cita, sin lo del negocio.
/// Mismo controller que "Comisiones" del Owner.
class MyEarningsScreen extends GetView<CommissionsController> {
  const MyEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis ganancias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: controller.refreshSettlement,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshSettlement,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          children: [
            Obx(() => DateRangeSelector(
                  selected: controller.range.value,
                  today: controller.today,
                  onChanged: controller.setRange,
                )),
            const SizedBox(height: 4),
            StatsSectionView(
              section: controller.settlement,
              onRetry: controller.load,
              loadingMessage: 'Calculando tus ganancias…',
              isEmpty: (settlement) => settlement.isEmptyWithPending,
              emptyIcon: Icons.savings_rounded,
              emptyMessage: 'Sin citas en este período',
              emptySubMessage: 'Aquí verás lo que ganas por cada cita. '
                  'Prueba con un período más amplio.',
              builder: (context, settlement) =>
                  MyEarningsView(settlement: settlement),
            ),
          ],
        ),
      ),
    );
  }
}
