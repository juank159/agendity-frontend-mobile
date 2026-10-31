import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/auth/presentation/controllers/logout_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/user_info_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/email_verification_notice.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';

/// Menú lateral de la home. Solo entradas con pantalla real; las de Owner
/// (Personal, Mi negocio, WhatsApp y Planes) se ocultan al Employee, igual
/// que `RoleMiddleware.ownerOnly()` en sus rutas. Colores del `ColorScheme`.
class CustomDrawer extends GetView<UserInfoController> {
  const CustomDrawer({super.key});

  /// Mensaje del cierre de sesión: con cambios sin enviar (10.03), dice que
  /// no se pierden.
  static String logoutMessage(int unsent) => unsent == 0
      ? '¿Seguro que quieres cerrar la sesión?'
      : 'Tienes ${formatCount(unsent, 'cambio', 'cambios')} sin enviar al '
          'servidor. No se pierden: quedan guardados en este teléfono, en los '
          'datos de tu usuario, y se enviarán cuando vuelvas a iniciar sesión '
          'aquí con conexión.';

  Future<void> _confirmLogout() async {
    final unsent = Get.isRegistered<SyncController>()
        ? Get.find<SyncController>().unsent
        : 0;
    final confirmed = await AppDialogs.confirm(
      title: unsent == 0 ? '¿Cerrar sesión?' : 'Hay cambios sin enviar',
      message: logoutMessage(unsent),
      confirmLabel: 'Cerrar sesión',
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (confirmed) await Get.find<LogoutController>().logout();
  }

  /// Cierra el menú y abre [route].
  void _open(String route) {
    Get.back();
    Get.toNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Obx(() {
        final isOwner = controller.isOwner();
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _DrawerHeader(controller: controller, isOwner: isOwner),
            const _SectionTitle('NAVEGACIÓN'),
            // Owner y Employee (el Employee, en solo lectura).
            _DrawerItem(
              icon: Icons.sell_outlined,
              title: 'Servicios',
              onTap: () => _open(GetRoutes.services),
            ),
            // Owner y Employee crean y editan clientes; borrar, solo el Owner.
            _DrawerItem(
              icon: Icons.people_outline,
              title: 'Clientela',
              onTap: () => _open(GetRoutes.clients),
            ),
            if (isOwner)
              _DrawerItem(
                icon: Icons.badge_outlined,
                title: 'Personal',
                onTap: () => _open(GetRoutes.employees),
              ),
            _DrawerItem(
              icon: Icons.bar_chart,
              title: 'Informes',
              onTap: () => _open(controller.getStatisticsRoute()),
            ),
            // Owner: el equipo; Employee: sus comisiones.
            _DrawerItem(
              icon: Icons.percent,
              title: 'Comisiones',
              onTap: () => _open(GetRoutes.commissions),
            ),
            const _SectionTitle('CONFIGURACIÓN'),
            // Solo Owner: el backend responde 403 al Employee en la
            // configuración del negocio, la de WhatsApp y al suscribirse.
            if (isOwner) ...[
              _DrawerItem(
                icon: Icons.storefront_outlined,
                title: 'Mi negocio',
                onTap: () => _open(GetRoutes.businessSettings),
              ),
              _DrawerItem(
                icon: Icons.chat_outlined,
                title: 'WhatsApp',
                onTap: () => _open(GetRoutes.configWhatsapp),
              ),
              _DrawerItem(
                icon: Icons.workspace_premium_outlined,
                title: 'Planes y suscripción',
                onTap: () => _open(GetRoutes.subscriptionPlans),
              ),
            ],
            _DrawerItem(
              icon: Icons.palette_outlined,
              title: 'Apariencia',
              onTap: () => _open(GetRoutes.themeSettings),
            ),
            const _SectionTitle('CUENTA'),
            _DrawerItem(
              icon: Icons.logout_rounded,
              title: 'Cerrar sesión',
              destructive: true,
              onTap: () {
                Get.back();
                _confirmLogout();
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      }),
    );
  }
}

/// Avatar, nombre, email, rol y el aviso de email sin verificar (4.08b).
class _DrawerHeader extends StatelessWidget {
  final UserInfoController controller;
  final bool isOwner;

  const _DrawerHeader({required this.controller, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final roleBackground =
        isOwner ? scheme.tertiaryContainer : scheme.secondaryContainer;
    final roleForeground =
        isOwner ? scheme.onTertiaryContainer : scheme.onSecondaryContainer;

    return Container(
      color: scheme.primaryContainer,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 24, 16, 20),
      child: Obx(() => Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                child: Text(
                  controller.userInitial.value,
                  style: const TextStyle(
                      fontSize: 38, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                controller.userName.value,
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (controller.userEmail.value.isNotEmpty)
                Text(
                  controller.userEmail.value,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium
                      ?.copyWith(color: scheme.onPrimaryContainer),
                ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: roleBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOwner ? 'PROPIETARIO' : 'EMPLEADO',
                  style: text.labelMedium?.copyWith(
                    color: roleForeground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const EmailVerificationNotice(),
            ],
          )),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: destructive ? scheme.error : scheme.primary),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }
}
