// lib/features/clients/presentation/widgets/client_list.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';
import 'package:login_signup/core/config/utils/string_utils.dart';
import 'package:login_signup/features/clients/presentation/widgets/add_client_dialog.dart';

class ClientList extends GetView<ClientsController> {
  const ClientList({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: Obx(() {
            if (controller.isLoading.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando clientes...',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (controller.clients.isEmpty) {
              return _buildEmptyState();
            }

            // ✅ CON PAGINACIÓN REAL, NO NECESITAMOS VERIFICAR filteredClients
            // El servidor ya aplica filtros y devuelve solo los resultados válidos

            return RefreshIndicator(
              onRefresh: controller.refreshClients,
              color: Colors.blue.shade700,
              child: Stack(
                children: [
                  // Lista de clientes paginada
                  ListView.builder(
                    controller: controller.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    itemCount: controller.clients.length +
                        1, // +1 para el loader
                    itemBuilder: (context, index) {
                      // Si es el último elemento, mostrar indicador de carga o mensaje final
                      if (index == controller.clients.length) {
                        if (controller.isLoadingMore.value) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue.shade400,
                              ),
                            ),
                          );
                        } else if (!controller.hasNextPage.value &&
                            controller.clients.isNotEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No hay más clientes para mostrar',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox(height: 80); // Espacio para FAB
                        }
                      }

                      // Elementos normales de la lista
                      final client = controller.clients[index];

                      // Determinar el color de fondo según el índice para alternar colores
                      final backgroundColor = index % 2 == 0
                          ? Colors.white
                          : Colors.blue.shade50.withOpacity(0.3);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8), // ✅ Reducir margen
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12), // ✅ Menos redondeado
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              spreadRadius: 0,
                              blurRadius: 6, // ✅ Menos sombra
                              offset: const Offset(0, 1),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 0.5, // ✅ Borde más fino
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Get.toNamed(
                                '/clients/edit',
                                arguments: {'clientId': client.id},
                                preventDuplicates: true,
                              );
                            },
                            splashColor: Colors.blue.withOpacity(0.1),
                            highlightColor: Colors.blue.withOpacity(0.05),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0), // ✅ Menos padding
                              child: Row(
                                children: [
                                  // Avatar del cliente - MÁS PEQUEÑO
                                  Hero(
                                    tag: 'client-${client.id}',
                                    child: Container(
                                      width: 45, // ✅ Más pequeño
                                      height: 45, // ✅ Más pequeño
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: client.image != null &&
                                                  client.image!.isNotEmpty
                                              ? [
                                                  Colors.transparent,
                                                  Colors.transparent
                                                ]
                                              : [
                                                  Colors.blue.shade400,
                                                  Colors.blue.shade700,
                                                ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: client.image != null &&
                                              client.image!.isNotEmpty
                                          ? ClipOval(
                                              child: Image.network(
                                                client.image!,
                                                width: 45,
                                                height: 45,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Center(
                                                    child: Text(
                                                      StringUtils.getInitials(
                                                          client.name),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                StringUtils.getInitials(
                                                    client.name),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Información del cliente
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${client.name} ${client.lastname}'
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone_android,
                                              size: 14,
                                              color: Colors.blue.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              StringUtils.formatPhoneNumber(
                                                  client.phone),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.blue.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (client.email.isNotEmpty &&
                                            client.email !=
                                                'no-email@example.com')
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 2),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.email_outlined,
                                                  size: 14,
                                                  color: Colors.blue.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    client.email,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black54,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Acciones rápidas
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          // Acción para llamar al cliente
                                          final phoneNumber = client.phone;
                                          // Aquí podrías implementar la acción de llamada
                                          Get.snackbar(
                                            'Llamando',
                                            'Llamando a ${client.name}: $phoneNumber',
                                            backgroundColor:
                                                Colors.green.shade200,
                                            colorText: Colors.green.shade900,
                                            snackPosition: SnackPosition.TOP,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.phone,
                                            color: Colors.green.shade700,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () {
                                          // Acción para enviar mensaje al cliente
                                          Get.snackbar(
                                            'Mensaje',
                                            'Enviando mensaje a ${client.name}',
                                            backgroundColor:
                                                Colors.blue.shade200,
                                            colorText: Colors.blue.shade900,
                                            snackPosition: SnackPosition.TOP,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.message,
                                            color: Colors.blue.shade700,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Indicador de carga flotante
                  if (controller.isLoadingMore.value)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0),
                              Colors.white.withOpacity(0.8),
                              Colors.white,
                            ],
                          ),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_contacts.png', // Asegúrate de tener esta imagen
            width: 150,
            height: 150,
            // Si no tienes la imagen, usa un icono en su lugar
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.people_outline,
                size: 100,
                color: Colors.blue.shade200,
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'No tienes clientes registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Comienza a agregar clientes para gestionar tu negocio',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => AddClientDialog.show(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Cliente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.blue.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            controller.searchQuery.value.isNotEmpty
                ? 'No hay resultados para "${controller.searchQuery.value}"'
                : 'No hay clientes que coincidan con los filtros',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => controller.hasActiveFilters
                ? TextButton.icon(
                    onPressed: () => controller.clearAllFilters(),
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Limpiar filtros'),
                  )
                : TextButton.icon(
                    onPressed: () => controller.searchQuery.value = '',
                    icon: const Icon(Icons.refresh),
                    label: const Text('Limpiar búsqueda'),
                  ),
          ),
        ],
      ),
    );
  }
}
