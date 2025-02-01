import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';
import 'package:login_signup/features/clients/presentation/widgets/client_header.dart';
import 'package:login_signup/features/clients/presentation/widgets/client_search_bar.dart';
import 'package:login_signup/features/clients/presentation/widgets/client_list.dart';
import 'package:login_signup/features/clients/presentation/widgets/add_client_dialog.dart';

class ClientsScreen extends GetView<ClientsController> {
  const ClientsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: const [
            ClientHeader(),
            ClientSearchBar(),
            ClientList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddClientDialog.show(),
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add),
      ),
    );
  }
}
