// presentation/widgets/client_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

class ClientCard extends StatelessWidget {
  final ClientEntity client;

  const ClientCard({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Get.toNamed(
          '/clients/edit',
          arguments: {'clientId': client.id},
        ),
        child: ListTile(
          leading: CircleAvatar(
            child: Text(client.name[0].toUpperCase()),
          ),
          title: Text(client.name),
          subtitle: Text(client.phone),
        ),
      ),
    );
  }
}
