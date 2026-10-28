import 'package:get/get.dart';
import 'package:login_signup/shared/controller/session_controller.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import '../../domain/entities/payment_comparison_entity.dart';
import '../../domain/entities/payment_method_stats_entity.dart';
import '../../domain/entities/payment_stats_entity.dart';
import '../../domain/entities/professional_stats_entity.dart';
import '../../domain/entities/service_stats_entity.dart';
import '../../domain/entities/top_client_entity.dart';
import '../../domain/usecases/get_payment_comparison_usecase.dart';
import '../../domain/usecases/get_payment_stats_by_method_usecase.dart';
import '../../domain/usecases/get_payment_stats_by_professional_usecase.dart';
import '../../domain/usecases/get_payment_stats_by_service_usecase.dart';
import '../../domain/usecases/get_payment_stats_usecase.dart';
import '../../domain/usecases/get_top_clients_usecase.dart';
import '../../domain/usecases/stats_use_case.dart';
import 'stats_period_controller.dart';
import 'stats_section.dart';

/// Bloques plegables del panel; cada uno se carga al abrirlo.
enum StatsDashboardSection {
  paymentMethods,
  professionals,
  services,
  topClients
}

/// Panel de estadísticas del negocio (ruta `/statistics`, solo Owner).
///
/// Todo lo que pide es solo Owner en el backend: si la sesión no es de un
/// Owner no hace ninguna petición y muestra el aviso. El Employee ve las
/// suyas en `EmployeeStatsController`.
class StatisticsController extends StatsPeriodController {
  static const topClientsLimit = 5;
  static const moreTopClientsLimit = 20;
  static const ownerOnlyMessage =
      'Solo el propietario del negocio puede ver las estadísticas del negocio.';

  final GetPaymentStatsUseCase _getStats;
  final GetPaymentComparisonUseCase _getComparison;
  final GetPaymentStatsByMethodUseCase _getByMethod;
  final GetPaymentStatsByProfessionalUseCase _getByProfessional;
  final GetPaymentStatsByServiceUseCase _getByService;
  final GetTopClientsUseCase _getTopClients;
  final SessionController _session;

  StatisticsController({
    required GetPaymentStatsUseCase getPaymentStatsUseCase,
    required GetPaymentComparisonUseCase getPaymentComparisonUseCase,
    required GetPaymentStatsByMethodUseCase getPaymentStatsByMethodUseCase,
    required GetPaymentStatsByProfessionalUseCase
        getPaymentStatsByProfessionalUseCase,
    required GetPaymentStatsByServiceUseCase getPaymentStatsByServiceUseCase,
    required GetTopClientsUseCase getTopClientsUseCase,
    required SessionController session,
    super.clock,
  })  : _getStats = getPaymentStatsUseCase,
        _getComparison = getPaymentComparisonUseCase,
        _getByMethod = getPaymentStatsByMethodUseCase,
        _getByProfessional = getPaymentStatsByProfessionalUseCase,
        _getByService = getPaymentStatsByServiceUseCase,
        _getTopClients = getTopClientsUseCase,
        _session = session;

  /// Resumen (ingresos netos del período). Manda en el estado de la pantalla.
  final overview = StatsSection<PaymentStatsEntity>();
  final comparison = StatsSection<PaymentComparisonEntity>();
  final paymentMethods = StatsSection<List<PaymentMethodStatsEntity>>();
  final professionals = StatsSection<List<ProfessionalStatsEntity>>();
  final services = StatsSection<List<ServiceStatsEntity>>();
  final topClients = StatsSection<List<TopClientEntity>>();

  /// Cuántos clientes se piden en el ranking.
  final topClientsShown = topClientsLimit.obs;

  final expanded = <StatsDashboardSection>{}.obs;

  bool get canView => _session.isOwner;

  bool isExpanded(StatsDashboardSection section) => expanded.contains(section);

  /// Puede haber más clientes que los mostrados.
  bool get canShowMoreTopClients =>
      topClientsShown.value < moreTopClientsLimit &&
      (topClients.data.value?.length ?? 0) >= topClientsShown.value;

  List<StatsSection<Object>> get _allSections => [
        overview,
        comparison,
        paymentMethods,
        professionals,
        services,
        topClients,
      ];

  @override
  void onInit() {
    super.onInit();
    if (!canView) {
      overview.fail(ownerOnlyMessage);
      return;
    }
    loadOverview();
  }

  Future<void> loadOverview() => Future.wait([
        overview.load(() => _getStats(range.value)),
        comparison.load(() => _getComparison(range.value)),
      ]);

  Future<void> loadSection(StatsDashboardSection section) {
    switch (section) {
      case StatsDashboardSection.paymentMethods:
        return paymentMethods.load(() => _getByMethod(range.value));
      case StatsDashboardSection.professionals:
        return professionals.load(() => _getByProfessional(range.value));
      case StatsDashboardSection.services:
        return services.load(() => _getByService(range.value));
      case StatsDashboardSection.topClients:
        return topClients.load(() => _getTopClients(
            StatsRankingParams(range.value, limit: topClientsShown.value)));
    }
  }

  /// Abre o cierra un bloque; al abrirlo por primera vez lo carga.
  void toggle(StatsDashboardSection section) {
    if (expanded.contains(section)) {
      expanded.remove(section);
      return;
    }
    expanded.add(section);
    final state = _sectionState(section);
    if (!state.hasData && !state.isLoading.value) loadSection(section);
  }

  void showMoreTopClients() {
    topClientsShown.value = moreTopClientsLimit;
    loadSection(StatsDashboardSection.topClients);
  }

  /// Recarga lo visible (pull to refresh y botón de la barra). Si un bloque
  /// ya tenía datos y falla, se conservan y se avisa con un snackbar.
  Future<void> refreshAll() async {
    if (!canView) return;
    await Future.wait([loadOverview(), ...expanded.map(loadSection)]);
    final failed = _allSections
        .where((s) => s.hasData && s.error.value != null)
        .map((s) => s.error.value!);
    if (failed.isNotEmpty) AppSnackbar.error(failed.first);
  }

  @override
  void onRangeChanged() {
    if (!canView) return;
    for (final section in _allSections) {
      section.reset();
    }
    topClientsShown.value = topClientsLimit;
    loadOverview();
    expanded.forEach(loadSection);
  }

  StatsSection<Object> _sectionState(StatsDashboardSection section) {
    switch (section) {
      case StatsDashboardSection.paymentMethods:
        return paymentMethods;
      case StatsDashboardSection.professionals:
        return professionals;
      case StatsDashboardSection.services:
        return services;
      case StatsDashboardSection.topClients:
        return topClients;
    }
  }
}
