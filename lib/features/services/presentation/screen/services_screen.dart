import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/constants/app_colors.dart';
import 'package:login_signup/core/constants/app_styles.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/services/presentation/bindings/categories_binding.dart';
import 'package:login_signup/features/services/presentation/controller/categories_controller.dart';
import 'package:login_signup/features/services/presentation/screen/categories_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeServices();
    });
  }

  void _toggleMenu() {
    setState(() => isExpanded = !isExpanded);
  }

  void _navigateToCategories() {
    _toggleMenu();
    try {
      Get.delete<CategoriesController>(force: true);
      Get.to(
        () => const CategoriesScreen(),
        binding: CategoriesBinding(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 250),
        preventDuplicates: true,
      );
    } catch (e) {
      print('Error navegando a categorías: $e');
    }
  }

  Future<void> _handleServiceCreation() async {
    _toggleMenu();
    try {
      final hasCategories = await controller.checkIfCategoriesExist();

      if (!hasCategories) {
        await _showCreateCategoryDialog();
        return;
      }

      await _navigateToNewService();
    } catch (e) {
      _showError('Ocurrió un error inesperado');
    }
  }

  Future<void> _showCreateCategoryDialog() {
    return Get.dialog(
      AlertDialog(
        title: const Text('Crear categoría'),
        content: const Text(
            'Para crear un servicio, primero necesitas crear una categoría. ¿Deseas ir a la sección de categorías?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _navigateToCategories();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ir a categorías'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToNewService() async {
    try {
      await Get.toNamed(GetRoutes.addService);
      await controller.refreshServices();
    } catch (e) {
      _showError('No se pudo abrir la pantalla de nuevo servicio');
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Permitir retroceder sin mostrar un cuadro de diálogo
        return true;
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildBody(),
            if (isExpanded) _buildOverlay(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButtons(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        title: const Text('Servicios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Retroceder directamente
            Get.toNamed('/');
          },
        ),
      );

  Widget _buildBody() => RefreshIndicator(
        onRefresh: controller.refreshServices,
        child: Obx(() {
          if (controller.isLoading.value && !controller.isInitialized.value) {
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
            backgroundColor: AppColors.cardIndicator,
            child: const Icon(Icons.add),
          ),
        if (isExpanded) ...[
          Positioned(
            right: 0,
            bottom: AppStyles.floatingButtonSpacing * 2,
            child: ActionButton(
              label: 'Categoría',
              icon: Icons.folder_outlined,
              onTap: _navigateToCategories,
            ),
          ),
          Positioned(
            right: 0,
            bottom: AppStyles.floatingButtonSpacing,
            child: ActionButton(
              label: 'Servicio',
              icon: Icons.local_offer_outlined,
              onTap: _handleServiceCreation,
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
    final controller = Get.find<ServicesController>();
    final groupedServices = controller.getServicesGroupedByCategory();

    return ListView.builder(
      padding: AppStyles.cardPadding,
      itemCount: groupedServices.length,
      itemBuilder: (context, index) {
        final categoryName = groupedServices.keys.elementAt(index);
        final categoryServices = groupedServices[categoryName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categoryServices.length,
              itemBuilder: (_, index) => ServiceCard(
                service: categoryServices[index],
              ),
            ),
            const SizedBox(height: 1),
          ],
        );
      },
    );
  }
}
