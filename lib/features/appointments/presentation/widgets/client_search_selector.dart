// lib/features/appointments/presentation/widgets/client_search_selector.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/appointments_controller.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

class ClientSearchSelector extends GetView<AppointmentsController> {
  final Function(ClientEntity) onClientSelected;

  const ClientSearchSelector({
    super.key,
    required this.onClientSelected,
  });

  static Future<ClientEntity?> show(
    BuildContext context,
    AppointmentsController controller,
  ) async {
    // Adaptar el tamaño según la plataforma y orientación
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width * 0.9;
    final maxHeight = size.height * 0.8;

    final result = await showDialog<ClientEntity?>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: maxWidth,
          height: maxHeight,
          padding: const EdgeInsets.all(16),
          child: ClientSearchSelector(
            onClientSelected: (client) {
              Navigator.pop(context, client);
            },
          ),
        ),
      ),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Título
        Text(
          'Seleccionar Cliente',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 20),

        // Barra de búsqueda
        _buildSearchBar(context),
        const SizedBox(height: 16),

        // Lista de clientes
        Expanded(
          child: Obx(() {
            // Mostrar loading si está cargando y no hay clientes
            if (controller.isClientsLoading.value && controller.clients.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Cargando clientes...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            // ✅ CON PAGINACIÓN REAL, USAR LA LISTA DE CLIENTES DIRECTAMENTE
            // El filtrado ahora se hace en el servidor
            final clientsToShow = controller.clients;

            if (clientsToShow.isEmpty && controller.clients.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No se encontraron clientes',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => controller.clearClientSearch(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Limpiar búsqueda'),
                    ),
                  ],
                ),
              );
            }

            if (clientsToShow.isEmpty && controller.clients.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay clientes registrados',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: clientsToShow.length + (controller.hasMoreClients.value ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                // ✅ INDICADOR DE CARGA PARA MÁS CLIENTES
                if (index == clientsToShow.length) {
                  // Disparar carga de más clientes automáticamente
                  if (controller.hasMoreClients.value && !controller.isLoadingMoreClients.value) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      controller.loadMoreClients();
                    });
                  }
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: controller.isLoadingMoreClients.value
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text('Cargando más clientes...',
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                }

                final client = clientsToShow[index];
                final clientName = '${client.name} ${client.lastname}';
                final firstLetter = client.name[0].toString().toUpperCase();

                return Card(
                  elevation: 1,
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => onClientSelected(client),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar con iniciales
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.7),
                                  Theme.of(context).primaryColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: client.image != null &&
                                    client.image!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: Image.network(
                                      client.image!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildClientAvatar(firstLetter, context),
                                    ),
                                  )
                                : _buildClientAvatar(firstLetter, context),
                          ),
                          const SizedBox(width: 16),

                          // Información del cliente
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clientName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (client.phone.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          client.phone,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (client.email.isNotEmpty && 
                                    client.email != 'no-email@example.com')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.email,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            client.email,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Icono de selección
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),

        // Botones de acción
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.grey[700],
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text(
                    'Nuevo Cliente',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      onChanged: (value) => controller.updateClientSearch(value),
      decoration: InputDecoration(
        labelText: 'Buscar Cliente',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Obx(() => controller.clientSearchQuery.value.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => controller.clearClientSearch(),
              )
            : const SizedBox.shrink()),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }

  Widget _buildClientAvatar(String firstLetter, BuildContext context) {
    return Center(
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}