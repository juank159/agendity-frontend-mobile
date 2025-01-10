import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/logout_controller.dart';
import 'package:login_signup/features/services/presentation/screen/services_screen.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '¿Está seguro que desea cerrar la sesión?',
          style: TextStyle(fontSize: 16),
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
              Get.find<LogoutController>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        backgroundColor: const Color(0xFF1A1A2E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(Icons.search, color: Colors.white),
                title: Text('Buscar', style: TextStyle(color: Colors.white)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            _DrawerTile(
              icon: Icons.sell,
              title: 'Servicios',
              onTap: () {
                Get.back();
                Get.toNamed('/services');
              },
            ),
            _DrawerTile(
              icon: Icons.people,
              title: 'Clientela',
              onTap: () {
                Get.back();
                // Get.to(() => const ClientelaScreen()); // Implementar cuando exista
              },
            ),
            _DrawerTile(
              icon: Icons.message,
              title: 'Mensajes',
              onTap: () {
                Get.back();
                // Get.to(() => const MensajesScreen());
              },
            ),
            _DrawerTile(
              icon: Icons.monetization_on,
              title: 'Gastos',
              onTap: () {
                Get.back();
                // Get.to(() => const GastosScreen());
              },
            ),
            _DrawerTile(
              icon: Icons.bar_chart,
              title: 'Informes',
              onTap: () {
                Get.back();
                // Get.to(() => const InformesScreen());
              },
            ),
            _DrawerTile(
              icon: Icons.calendar_today,
              title: 'Reserva Online',
              onTap: () {
                Get.back();
                // Get.to(() => const ReservaScreen());
              },
            ),
            _DrawerTile(
              icon: Icons.person,
              title: 'Personal',
              onTap: () {
                Get.back();
                // Get.to(() => const PersonalScreen());
              },
            ),
            _DrawerTile(
              icon: Icons.description,
              title: 'Formularios',
              onTap: () {
                Get.back();
                // Get.to(() => const FormulariosScreen());
              },
            ),
            Divider(color: Colors.grey.withOpacity(0.3)),
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text('J', style: TextStyle(color: Colors.white)),
              ),
              title:
                  Text('Paola Jiménez', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'juankpaez21@gmail.com',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            _DrawerTile(
              icon: Icons.settings,
              title: 'Ajustes',
              onTap: () {
                Get.back();
                // Get.to(() => const AjustesScreen());
              },
            ),
            _DrawerTile(
              icon: Icons.logout_rounded,
              title: 'Cerrar Sesión',
              onTap: () {
                Get.back();
                _showLogoutDialog();
              },
            ),
            _DrawerTile(
              icon: Icons.help,
              title: 'Centro de ayuda',
              onTap: () {
                Get.back();
                // Get.to(() => const AyudaScreen());
              },
            ),
            _DrawerTile(
              icon: Icons.send,
              title: 'Enviar opiniones',
              onTap: () {
                Get.back();
                // Get.to(() => const OpinionesScreen());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}
