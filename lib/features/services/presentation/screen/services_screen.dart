import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:login_signup/core/constants/app_colors.dart';
import 'package:login_signup/core/constants/app_styles.dart';
import 'package:login_signup/core/routes/routes.dart';

import '../../domain/entities/service_entity.dart';
import '../controller/services_controller.dart';
import '../widgets/action_button.dart';
import '../widgets/service_card.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final ServicesController controller = Get.find<ServicesController>();
  bool isExpanded = false;

  void _toggleMenu() {
    setState(() => isExpanded = !isExpanded);
  }

  void _navigateTo(String route) {
    _toggleMenu();
    Get.toNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBody(),
          if (isExpanded) _buildOverlay(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  AppBar _buildAppBar() => AppBar(
        title: const Text('Servicios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
      );

  Widget _buildBody() => RefreshIndicator(
        onRefresh: controller.loadServices,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return controller.services.isEmpty
              ? const _EmptyState()
              : _ServicesList(services: controller.services);
        }),
      );

  Widget _buildOverlay() => Positioned.fill(
        child: GestureDetector(
          onTap: _toggleMenu,
          child: Container(
            color: AppColors.overlay.withOpacity(AppStyles.overlayOpacity),
          ),
        ),
      );

  Widget _buildFloatingActionButtons() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (!isExpanded)
          FloatingActionButton(
            onPressed: _toggleMenu,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add),
          ),
        if (isExpanded) ...[
          Positioned(
            right: 0,
            bottom: AppStyles.floatingButtonSpacing * 2,
            child: ActionButton(
              label: 'Categoría',
              icon: Icons.folder_outlined,
              onTap: () => _navigateTo(GetRoutes.categories),
            ),
          ),
          Positioned(
            right: 0,
            bottom: AppStyles.floatingButtonSpacing,
            child: ActionButton(
              label: 'Servicio',
              icon: Icons.local_offer_outlined,
              onTap: () => _navigateTo(GetRoutes.addService),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No hay servicios disponibles',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}

class _ServicesList extends StatelessWidget {
  final RxList<ServiceEntity> services;

  const _ServicesList({required this.services});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppStyles.cardPadding,
      itemCount: services.length,
      itemBuilder: (_, index) => ServiceCard(service: services[index]),
    );
  }
}
