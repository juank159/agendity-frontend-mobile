import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/appointments/presentation/controllers/client_picker_controller.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

/// Busca y elige el cliente de una cita (paginado en el servidor). Crea su
/// `ClientPickerController` al abrirse y lo borra al cerrarse. Devuelve el
/// cliente elegido o `null`.
class ClientSearchSelector extends StatefulWidget {
  final ClientPickerController Function() createController;

  const ClientSearchSelector({super.key, required this.createController});

  static Future<ClientEntity?> show() => Get.dialog<ClientEntity>(
      const ClientSearchSelector(
          createController: ClientPickerController.fromDependencies));

  @override
  State<ClientSearchSelector> createState() => _ClientSearchSelectorState();
}

class _ClientSearchSelectorState extends State<ClientSearchSelector> {
  late final String _tag = 'client-picker-${identityHashCode(this)}';
  late final ClientPickerController _controller;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(widget.createController(), tag: _tag);
  }

  @override
  void dispose() {
    _search.dispose();
    Get.delete<ClientPickerController>(tag: _tag);
    super.dispose();
  }

  Future<void> _newClient() async {
    final created = await Get.toNamed(GetRoutes.addClient);
    if (created == true) await _controller.search();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Elegir cliente',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  labelText: 'Buscar por nombre o teléfono',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Limpiar búsqueda',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _search.clear();
                      _controller.clear();
                    },
                  ),
                ),
                onChanged: (value) => _controller.query.value = value,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(() => ListStateView<ClientEntity>(
                      isLoading: _controller.isLoading.value,
                      error: _controller.error.value?.message,
                      items: _controller.clients.toList(),
                      onRetry: _controller.search,
                      emptyIcon: Icons.person_off_outlined,
                      emptyMessage: _controller.query.value.trim().isEmpty
                          ? 'No hay clientes registrados'
                          : 'Ningún cliente coincide',
                      builder: (context, clients) => _ClientList(
                        clients: clients,
                        controller: _controller,
                      ),
                    )),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _newClient,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Nuevo cliente'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientList extends StatelessWidget {
  final List<ClientEntity> clients;
  final ClientPickerController controller;

  const _ClientList({required this.clients, required this.controller});

  @override
  Widget build(BuildContext context) {
    final hasMore = controller.hasMore.value;
    return ListView.builder(
      itemCount: clients.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == clients.length) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => controller.loadMore());
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final client = clients[index];
        final initial =
            client.name.isEmpty ? '?' : client.name[0].toUpperCase();
        return ListTile(
          leading: CircleAvatar(child: Text(initial)),
          title: Text(client.fullName),
          subtitle: client.phone.isEmpty ? null : Text(client.phone),
          onTap: () => Navigator.of(context).pop(client),
        );
      },
    );
  }
}
