// lib/widgets/custom_drawer.dart

import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/auth/presentation/controllers/logout_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/user_info_controller.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';

class CustomDrawer extends GetView<UserInfoController> {
  const CustomDrawer({super.key});

  // Método para inicializar UserInfoController si no existe
  UserInfoController _ensureUserInfoController() {
    try {
      return Get.find<UserInfoController>();
    } catch (e) {
      print('UserInfoController no encontrado, inicializando uno nuevo: $e');
      final controller = UserInfoController();
      Get.put(controller, permanent: true);
      // Asegurar que se cargue la información del usuario inmediatamente
      controller.loadUserInfo();
      return controller;
    }
  }

  void _showLogoutDialog() {
    try {
      final logoutController = Get.find<LogoutController>();
      Get.dialog(
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.red.shade700,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¿Cerrar Sesión?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¿Está seguro que desea cerrar la sesión?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            logoutController.logout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cerrar Sesión',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
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
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.3),
      );
    } catch (e) {
      print('Error al mostrar diálogo de logout: $e');
      Get.snackbar(
        'Error',
        'No se pudo iniciar el proceso de cierre de sesión',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final userController = _ensureUserInfoController();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A237E), // Azul oscuro
              const Color(0xFF0D47A1), // Azul profundo
              const Color(0xFF01579B), // Azul oscuro
            ],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            final bool isOwner = userController.isOwner();

            return Column(
              children: [
                  // Perfil de usuario
                  Container(
                    padding: const EdgeInsets.only(top: 30, bottom: 20),
                    child: Column(
                      children: [
                        // Avatar del usuario
                        Obx(() => Container(
                              height: 100,
                              width: 100,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade300,
                                    Colors.blue.shade600,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.7),
                                  width: 4,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  userController.userInitial.value,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )),

                        // Nombre de usuario
                        Obx(() => Text(
                              userController.userName.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            )),

                        // Email del usuario
                        Obx(() => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                userController.userEmail.value,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )),

                        // Chip de rol
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isOwner
                                  ? Colors.amber.withOpacity(0.5)
                                  : Colors.blue.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isOwner ? "PROPIETARIO" : "EMPLEADO",
                            style: TextStyle(
                              color: isOwner ? Colors.amber : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Separador decorativo
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Lista de opciones del menú
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                          children: [
                            // Sección: Buscar
                            _buildSectionTitle('NAVEGACIÓN'),

                            _buildDrawerItem(
                              icon: Icons.search,
                              title: 'Buscar',
                              onTap: () {
                                Get.back();
                                // Implementar acción de búsqueda
                              },
                            ),

                            // Elementos condicionales según el rol
                            if (isOwner) ...[
                              _buildDrawerItem(
                                icon: Icons.sell,
                                title: 'Servicios',
                                onTap: () async {
                                  Get.back();
                                  try {
                                    final servicesController =
                                        Get.find<ServicesController>();
                                    await servicesController
                                        .initializeServices();
                                    Get.toNamed(GetRoutes.services);
                                  } catch (e) {
                                    print('Error inicializando servicios: $e');
                                    Get.toNamed(GetRoutes.services);
                                  }
                                },
                              ),
                              _buildDrawerItem(
                                icon: Icons.people,
                                title: 'Clientela',
                                onTap: () async {
                                  Get.back();
                                  try {
                                    final clientsController =
                                        Get.find<ClientsController>();
                                    await clientsController.loadClients();
                                    Get.toNamed(GetRoutes.clients);
                                  } catch (e) {
                                    print('Error inicializando clientes: $e');
                                    Get.toNamed(GetRoutes.clients);
                                  }
                                },
                                badgeCount:
                                    0, // Opcional: añade un contador dinámico
                              ),
                              _buildDrawerItem(
                                icon: Icons.message,
                                title: 'Mensajes',
                                onTap: () {
                                  Get.back();
                                  // Implementar navegación
                                },
                                isBeta: true, // Indica que es una función beta
                              ),
                              _buildDrawerItem(
                                icon: Icons.monetization_on,
                                title: 'Gastos',
                                onTap: () {
                                  Get.back();
                                  // Implementar navegación
                                },
                              ),
                              _buildDrawerItem(
                                icon: Icons.calendar_today,
                                title: 'Reserva Online',
                                onTap: () {
                                  Get.back();
                                  // Implementar navegación
                                },
                              ),
                              _buildDrawerItem(
                                icon: Icons.person,
                                title: 'Personal',
                                onTap: () async {
                                  Get.back();
                                  try {
                                    await Get.toNamed(GetRoutes.employees);
                                  } catch (e) {
                                    print('Error al navegar a Personal: $e');
                                    Get.snackbar(
                                      'Error',
                                      'No se pudo cargar la pantalla de Personal',
                                      backgroundColor: Colors.red[100],
                                      colorText: Colors.red[900],
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  }
                                },
                              ),
                              _buildDrawerItem(
                                icon: Icons.description,
                                title: 'Formularios',
                                onTap: () {
                                  Get.back();
                                  // Implementar navegación
                                },
                              ),
                            ],

                            // Visible para Owner y Employee
                            _buildDrawerItem(
                              icon: Icons.bar_chart,
                              title: 'Informes',
                              onTap: () {
                                Get.back();
                                final route = userController.getStatisticsRoute();
                                Get.toNamed(route);
                              },
                            ),

                            // Sección: Configuración
                            const SizedBox(height: 16),
                            _buildSectionTitle('CONFIGURACIÓN'),

                            _buildDrawerItem(
                              icon: Icons.settings,
                              title: 'Ajustes',
                              onTap: () {
                                Get.back();
                                Get.toNamed(GetRoutes.configWhatsapp);
                              },
                            ),
                            _buildDrawerItem(
                              icon: Icons.help,
                              title: 'Centro de ayuda',
                              onTap: () {
                                Get.back();
                                Get.toNamed(GetRoutes.subscriptionPlans);
                              },
                            ),
                            _buildDrawerItem(
                              icon: Icons.send,
                              title: 'Enviar opiniones',
                              onTap: () {
                                Get.back();
                                // Implementar navegación
                              },
                            ),

                            // Sección: Cuenta
                            const SizedBox(height: 16),
                            _buildSectionTitle('CUENTA'),

                            _buildDrawerItem(
                              icon: Icons.logout_rounded,
                              title: 'Cerrar Sesión',
                              onTap: () {
                                Get.back();
                                _showLogoutDialog();
                              },
                              isDestructive:
                                  true, // Estilo especial para acciones destructivas
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
        ),
      ),
    );
  }

  // Widget para crear títulos de sección
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade300,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // Widget para crear items del drawer
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int badgeCount = 0,
    bool isBeta = false,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: isDestructive
              ? Colors.red.withOpacity(0.1)
              : Colors.white.withOpacity(0.1),
          highlightColor: isDestructive
              ? Colors.red.withOpacity(0.05)
              : Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isDestructive ? Colors.red.shade300 : Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red.shade300 : Colors.white,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (isBeta)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "BETA",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
