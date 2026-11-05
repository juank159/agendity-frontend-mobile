import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/auth/presentation/controllers/logout_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/user_info_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/email_verification_notice.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';
import 'package:login_signup/shared/controllers/theme_controller.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';

/// Menú lateral de la home (12.03): cabecera con el negocio, el usuario y su
/// rol sobre el degradado de la paleta; ítems agrupados con íconos
/// `_rounded` y el activo resaltado con una píldora. Solo entradas con
/// pantalla real; las de Owner (Personal, Informes, Comisiones, Mi negocio,
/// Recordatorios y Planes) se ocultan al Employee, igual que
/// `RoleMiddleware.ownerOnly()` en sus rutas; ella ve "Mis servicios" y
/// "Mis ganancias" (D-27). Los textos de los ítems los usan los
/// integration_test.
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

  /// Cierra el menú y abre [route] (si ya está ahí, solo lo cierra).
  void _open(String route) {
    Get.back();
    if (Get.currentRoute != route) Get.toNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final current = Get.currentRoute;
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Obx(() {
        final isOwner = controller.isOwner();
        _DrawerItem item(IconData icon, String title, String route,
                {Key? key}) =>
            _DrawerItem(
              key: key,
              icon: icon,
              title: title,
              active: current == route,
              onTap: () => _open(route),
            );
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _DrawerHeader(controller: controller, isOwner: isOwner),
            const SizedBox(height: 8),
            item(Icons.calendar_month_rounded, 'Agenda', GetRoutes.home,
                key: const Key('drawer-home')),
            const _SectionTitle('Tu negocio'),
            // Owner: el catálogo. Employee: solo los suyos, con su comisión
            // (D-27), en solo lectura.
            item(Icons.spa_rounded, isOwner ? 'Servicios' : 'Mis servicios',
                GetRoutes.services),
            // Owner y Employee crean y editan clientes; borrar, solo el Owner.
            item(Icons.people_alt_rounded, 'Clientela', GetRoutes.clients),
            if (isOwner)
              item(Icons.badge_rounded, 'Personal', GetRoutes.employees),
            const _SectionTitle('Números'),
            if (isOwner) ...[
              item(Icons.insights_rounded, 'Informes', GetRoutes.statistics),
              item(Icons.percent_rounded, 'Comisiones', GetRoutes.commissions),
            ] else
              // D-27: Informes y Comisiones de la empleada en una sola
              // entrada (ganado, por ganar y el detalle por cita).
              item(Icons.savings_rounded, 'Mis ganancias',
                  GetRoutes.myEarnings),
            const _SectionTitle('Configuración'),
            // Solo Owner: el backend responde 403 al Employee en la
            // configuración del negocio y al suscribirse.
            if (isOwner) ...[
              item(Icons.storefront_rounded, 'Mi negocio',
                  GetRoutes.businessSettings),
              item(Icons.notifications_active_rounded, 'Recordatorios',
                  GetRoutes.reminders),
              item(Icons.workspace_premium_rounded, 'Planes y suscripción',
                  GetRoutes.subscriptionPlans),
            ],
            item(Icons.palette_rounded, 'Apariencia', GetRoutes.themeSettings),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 12, 28, 4),
              child: Divider(),
            ),
            _DrawerItem(
              icon: Icons.logout_rounded,
              title: 'Cerrar sesión',
              destructive: true,
              onTap: () {
                Get.back();
                _confirmLogout();
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      }),
    );
  }
}

/// Cabecera sobre el degradado de la paleta: nombre del negocio, usuario,
/// email, rol y el aviso de email sin verificar (4.08b).
class _DrawerHeader extends StatelessWidget {
  final UserInfoController controller;
  final bool isOwner;

  const _DrawerHeader({required this.controller, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final onGradient = tokens.onGradient;
    final theme = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: tokens.primaryGradient,
        borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(AppRadii.sheet)),
        boxShadow: tokens.elevation2(),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(AppRadii.sheet)),
        gradient: tokens.sheenGradient,
      ),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 20),
      child: Obx(() {
        final business = theme?.businessName.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (business != null && business.trim().isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.storefront_rounded, size: 18, color: onGradient),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      business,
                      key: const Key('drawer-business-name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                          color: onGradient, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: onGradient.withValues(alpha: 0.18),
                    border: Border.all(
                        color: onGradient.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Text(
                    AppAvatar.initialsOf(controller.userName.value),
                    style: text.titleLarge?.copyWith(
                        color: onGradient, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.userName.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleLarge?.copyWith(
                          color: onGradient,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (controller.userEmail.value.isNotEmpty)
                        Text(
                          controller.userEmail.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(color: onGradient),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: onGradient.withValues(alpha: 0.18),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                border: Border.all(color: onGradient.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      isOwner
                          ? Icons.workspace_premium_rounded
                          : Icons.badge_rounded,
                      size: 14,
                      color: onGradient),
                  const SizedBox(width: 6),
                  Text(
                    isOwner ? 'PROPIETARIO' : 'EMPLEADO',
                    style: text.labelSmall?.copyWith(
                      color: onGradient,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const EmailVerificationNotice(),
          ],
        );
      }),
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
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 6),
      child: Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}

/// Ítem del menú; el activo se resalta con una píldora tonal.
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;
  final bool active;

  const _DrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = destructive
        ? scheme.error
        : active
            ? scheme.onPrimaryContainer
            : scheme.onSurface;
    const pill = BorderRadius.all(Radius.circular(100));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedContainer(
        duration: AppMotion.of(context),
        curve: AppMotion.curve,
        decoration: BoxDecoration(
          color: active ? scheme.primaryContainer : null,
          borderRadius: pill,
        ),
        child: ListTile(
          selected: active,
          leading: Icon(icon,
              color: destructive
                  ? scheme.error
                  : active
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant),
          title: Text(
            title,
            style: TextStyle(
              color: foreground,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          shape: const RoundedRectangleBorder(borderRadius: pill),
          onTap: onTap,
        ),
      ),
    );
  }
}
