// // lib/features/clients/presentation/widgets/client_search_bar.dart

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';

// class ClientSearchBar extends GetView<ClientsController> {
//   const ClientSearchBar({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.9),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             spreadRadius: 1,
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//         border: Border.all(
//           color: Colors.white.withOpacity(0.7),
//           width: 1,
//         ),
//       ),
//       child: TextField(
//         onChanged: (value) => controller.searchQuery.value = value,
//         style: const TextStyle(
//           color: Colors.black87,
//           fontSize: 16,
//         ),
//         decoration: InputDecoration(
//           hintText: 'Buscar cliente por nombre o teléfono',
//           hintStyle: TextStyle(
//             color: Colors.grey.shade500,
//             fontSize: 16,
//           ),
//           prefixIcon: Icon(
//             Icons.search_rounded,
//             color: Colors.blue.shade700,
//             size: 24,
//           ),
//           suffixIcon: IconButton(
//             icon: Icon(
//               Icons.filter_list_rounded,
//               color: Colors.blue.shade600,
//             ),
//             onPressed: () {
//               // Acción para filtros
//               Get.snackbar(
//                 'Filtros',
//                 'Opciones de filtrado próximamente',
//                 backgroundColor: Colors.blue.shade200,
//                 colorText: Colors.white,
//                 snackPosition: SnackPosition.BOTTOM,
//               );
//             },
//           ),
//           filled: true,
//           fillColor: Colors.transparent,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(20),
//             borderSide: BorderSide.none,
//           ),
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 20,
//             vertical: 16,
//           ),
//         ),
//       ),
//     );
//   }
// }

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
                    color: controller.isFilterActive.value
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
          if (!controller.isFilterActive.value) {
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
                if (controller.activeFilter.value != null)
                  _buildFilterChip(
                    label: controller.activeFilter.value == true
                        ? 'Activos'
                        : 'Inactivos',
                    onRemoved: () => controller.activeFilter.value = null,
                    color: Colors.green,
                  ),

                // Chip para filtro por origen (dispositivo/manual)
                if (controller.sourceFilter.value != null)
                  _buildFilterChip(
                    label: controller.sourceFilter.value == true
                        ? 'Importados'
                        : 'Manuales',
                    onRemoved: () => controller.sourceFilter.value = null,
                    color: Colors.orange,
                  ),

                // Chip para ordenamiento
                if (controller.sortOrder.value != null)
                  _buildFilterChip(
                    label: 'Ord: ${_getSortLabel(controller.sortOrder.value!)}',
                    onRemoved: () => controller.sortOrder.value = null,
                    color: Colors.purple,
                  ),

                // Si hay algún filtro activo, mostrar botón para limpiar todos
                if (controller.isFilterActive.value)
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
  String _getSortLabel(String sortType) {
    switch (sortType) {
      case 'name_asc':
        return 'A-Z';
      case 'name_desc':
        return 'Z-A';
      case 'date_asc':
        return 'Más antiguo';
      case 'date_desc':
        return 'Más reciente';
      default:
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
                    isSelected: controller.activeFilter.value == null,
                    onTap: () {
                      controller.activeFilter.value = null;
                    },
                  ),
                  _buildFilterOption(
                    title: 'Clientes activos',
                    isSelected: controller.activeFilter.value == true,
                    onTap: () {
                      controller.activeFilter.value = true;
                    },
                  ),
                  _buildFilterOption(
                    title: 'Clientes inactivos',
                    isSelected: controller.activeFilter.value == false,
                    onTap: () {
                      controller.activeFilter.value = false;
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
                    isSelected: controller.sourceFilter.value == null,
                    onTap: () {
                      controller.sourceFilter.value = null;
                    },
                  ),
                  _buildFilterOption(
                    title: 'Importados de contactos',
                    isSelected: controller.sourceFilter.value == true,
                    onTap: () {
                      controller.sourceFilter.value = true;
                    },
                  ),
                  _buildFilterOption(
                    title: 'Creados manualmente',
                    isSelected: controller.sourceFilter.value == false,
                    onTap: () {
                      controller.sourceFilter.value = false;
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
                    isSelected: controller.sortOrder.value == null,
                    onTap: () {
                      controller.sortOrder.value = null;
                    },
                  ),
                  _buildFilterOption(
                    title: 'Nombre (A-Z)',
                    isSelected: controller.sortOrder.value == 'name_asc',
                    onTap: () {
                      controller.sortOrder.value = 'name_asc';
                    },
                  ),
                  _buildFilterOption(
                    title: 'Nombre (Z-A)',
                    isSelected: controller.sortOrder.value == 'name_desc',
                    onTap: () {
                      controller.sortOrder.value = 'name_desc';
                    },
                  ),
                  _buildFilterOption(
                    title: 'Más recientes primero',
                    isSelected: controller.sortOrder.value == 'date_desc',
                    onTap: () {
                      controller.sortOrder.value = 'date_desc';
                    },
                  ),
                  _buildFilterOption(
                    title: 'Más antiguos primero',
                    isSelected: controller.sortOrder.value == 'date_asc',
                    onTap: () {
                      controller.sortOrder.value = 'date_asc';
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
                      controller.applyFilters();
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
