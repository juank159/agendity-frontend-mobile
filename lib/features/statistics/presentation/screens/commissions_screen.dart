import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/commissions_controller.dart';
import '../widgets/commission_settlement_view.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/stats_section_view.dart';

/// Liquidación de comisiones del período (solo Owner: todo el equipo y lo
/// que queda para el negocio; la empleada ve "Mis ganancias", D-27). Solo
/// cuentan las citas completadas, con el precio y el % que tenían al
/// agendarse.
class CommissionsScreen extends GetView<CommissionsController> {
  const CommissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comisiones'),
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
              loadingMessage: 'Calculando comisiones…',
              isEmpty: (settlement) => settlement.isEmpty,
              emptyIcon: Icons.percent_rounded,
              emptyMessage: 'Sin citas completadas en este período',
              emptySubMessage: 'Las comisiones salen de las citas '
                  'completadas. Prueba con un período más amplio.',
              builder: (context, settlement) =>
                  CommissionSettlementView(settlement: settlement),
            ),
          ],
        ),
      ),
    );
  }
}
