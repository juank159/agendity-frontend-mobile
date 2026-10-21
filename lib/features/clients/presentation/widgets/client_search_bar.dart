// lib/features/clients/presentation/widgets/client_search_bar.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';

class ClientSearchBar extends GetView<ClientsController> {
  const ClientSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda principal
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.7),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Campo de búsqueda
              Expanded(
                child: TextField(
                  onChanged: (value) => controller.searchQuery.value = value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              // Botón de filtro
              Obx(
                () => IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: controller.hasActiveFilters
                        ? Colors.blue.shade700
                        : Colors.blue.shade400,
                    size: 28,
                  ),
                  onPressed: () => _showFilterOptions(context),
                ),
              ),
            ],
          ),
        ),

        // Chips de filtros activos
        Obx(() {
          if (!controller.hasActiveFilters) {
            return const SizedBox.shrink();
          }

          return Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Chip para filtro por estado (activo/inactivo)
                if (controller.statusFilter.value != 'all')
                  _buildFilterChip(
                    label: controller.statusFilter.value == 'active'
                        ? 'Activos'
                        : 'Inactivos',
                    onRemoved: () => controller.applyStatusFilter('all'),
                    color: Colors.green,
                  ),

                // Chip para filtro por origen (dispositivo/manual)
                if (controller.sourceFilter.value != 'all')
                  _buildFilterChip(
                    label: controller.sourceFilter.value == 'imported'
                        ? 'Importados'
                        : 'Manuales',
                    onRemoved: () => controller.applySourceFilter('all'),
                    color: Colors.orange,
                  ),

                // Chip para ordenamiento
                if (controller.sortBy.value != 'created_at' || controller.sortOrder.value != 'DESC')
                  _buildFilterChip(
                    label: 'Ord: ${_getSortLabel(controller.sortBy.value, controller.sortOrder.value)}',
                    onRemoved: () => controller.applySortFilter('created_at', 'DESC'),
                    color: Colors.purple,
                  ),

                // Si hay algún filtro activo, mostrar botón para limpiar todos
                if (controller.hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ActionChip(
                      avatar: const Icon(
                        Icons.clear_all,
                        color: Colors.white,
                        size: 16,
                      ),
                      backgroundColor: Colors.red.shade400,
                      label: const Text(
                        'Limpiar filtros',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => controller.clearAllFilters(),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Construye un chip de filtro con opción para eliminar
  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemoved,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        backgroundColor: color.withOpacity(0.2),
        side: BorderSide(color: color.withOpacity(0.5)),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        deleteIcon: Icon(
          Icons.cancel,
          size: 18,
          color: color,
        ),
        onDeleted: onRemoved,
      ),
    );
  }

  // Obtiene la etiqueta para el tipo de ordenamiento
  String _getSortLabel(String sortBy, String sortOrder) {
    if (sortBy == 'name') {
      return sortOrder == 'ASC' ? 'A-Z' : 'Z-A';
    } else if (sortBy == 'created_at') {
      return sortOrder == 'ASC' ? 'Más antiguo' : 'Más reciente';
    } else {
      return 'Personalizado';
    }
  }

  // Muestra el diálogo de opciones de filtrado
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterOptionsBottomSheet(),
    );
  }
}

// BottomSheet para las opciones de filtrado
class _FilterOptionsBottomSheet extends GetView<ClientsController> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra indicadora
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Título
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Filtrar Clientes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    controller.clearAllFilters();
                    Get.back();
                  },
                  child: Text(
                    'Limpiar',
                    style: TextStyle(
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Sección de estado
          _buildSectionTitle('Estado'),
          Obx(() => Column(
                children: [
                  _buildFilterOption(
                    title: 'Todos los clientes',
                    isSelected: controller.statusFilter.value == 'all',
                    onTap: () {
                      controller.applyStatusFilter('all');
                    },
                  ),
                  _buildFilterOption(
                    title: 'Clientes activos',
                    isSelected: controller.statusFilter.value == 'active',
                    onTap: () {
                      controller.applyStatusFilter('active');
                    },
                  ),
                  _buildFilterOption(
                    title: 'Clientes inactivos',
                    isSelected: controller.statusFilter.value == 'inactive',
                    onTap: () {
                      controller.applyStatusFilter('inactive');
                    },
                  ),
                ],
              )),

          const Divider(),

          // Sección de origen
          _buildSectionTitle('Origen'),
          Obx(() => Column(
                children: [
                  _buildFilterOption(
                    title: 'Todos los orígenes',
                    isSelected: controller.sourceFilter.value == 'all',
                    onTap: () {
                      controller.applySourceFilter('all');
                    },
                  ),
                  _buildFilterOption(
                    title: 'Importados de contactos',
                    isSelected: controller.sourceFilter.value == 'imported',
                    onTap: () {
                      controller.applySourceFilter('imported');
                    },
                  ),
                  _buildFilterOption(
                    title: 'Creados manualmente',
                    isSelected: controller.sourceFilter.value == 'manual',
                    onTap: () {
                      controller.applySourceFilter('manual');
                    },
                  ),
                ],
              )),

          const Divider(),

          // Sección de ordenamiento
          _buildSectionTitle('Ordenar por'),
          Obx(() => Column(
                children: [
                  _buildFilterOption(
                    title: 'Predeterminado',
                    isSelected: controller.sortBy.value == 'created_at' && controller.sortOrder.value == 'DESC',
                    onTap: () {
                      controller.applySortFilter('created_at', 'DESC');
                    },
                  ),
                  _buildFilterOption(
                    title: 'Nombre (A-Z)',
                    isSelected: controller.sortBy.value == 'name' && controller.sortOrder.value == 'ASC',
                    onTap: () {
                      controller.applySortFilter('name', 'ASC');
                    },
                  ),
                  _buildFilterOption(
                    title: 'Nombre (Z-A)',
                    isSelected: controller.sortBy.value == 'name' && controller.sortOrder.value == 'DESC',
                    onTap: () {
                      controller.applySortFilter('name', 'DESC');
                    },
                  ),
                  _buildFilterOption(
                    title: 'Más recientes primero',
                    isSelected: controller.sortBy.value == 'created_at' && controller.sortOrder.value == 'DESC',
                    onTap: () {
                      controller.applySortFilter('created_at', 'DESC');
                    },
                  ),
                  _buildFilterOption(
                    title: 'Más antiguos primero',
                    isSelected: controller.sortBy.value == 'created_at' && controller.sortOrder.value == 'ASC',
                    onTap: () {
                      controller.applySortFilter('created_at', 'ASC');
                    },
                  ),
                ],
              )),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Los filtros ya se aplican automáticamente al cambiarlos
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ),

          // Espacio para teclado virtual
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  // Construye un título de sección
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
      ),
    );
  }

  // Construye una opción de filtro seleccionable
  Widget _buildFilterOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            isSelected
                ? Icon(
                    Icons.radio_button_checked,
                    color: Colors.blue.shade700,
                  )
                : Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey.shade500,
                  ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Colors.black87 : Colors.black54,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
