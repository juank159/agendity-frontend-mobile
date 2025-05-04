// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/core/routes/routes.dart';
// import 'package:login_signup/features/auth/presentation/controllers/logout_controller.dart';
// import 'package:login_signup/features/auth/presentation/controllers/user_info_controller.dart';
// import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';
// import 'package:login_signup/features/services/presentation/controller/services_controller.dart';

// class CustomDrawer extends GetView<UserInfoController> {
//   const CustomDrawer({super.key});

//   // Método para inicializar UserInfoController si no existe
//   UserInfoController _ensureUserInfoController() {
//     try {
//       return Get.find<UserInfoController>();
//     } catch (e) {
//       print('UserInfoController no encontrado, inicializando uno nuevo: $e');
//       final controller = UserInfoController();
//       Get.put(controller);
//       return controller;
//     }
//   }

//   void _showLogoutDialog() {
//     try {
//       final logoutController = Get.find<LogoutController>();
//       Get.dialog(
//         AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           title: const Text(
//             'Cerrar Sesión',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           content: const Text(
//             '¿Está seguro que desea cerrar la sesión?',
//             style: TextStyle(fontSize: 16),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Get.back(),
//               child: const Text(
//                 'Cancelar',
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Get.back();
//                 logoutController.logout();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text('Cerrar Sesión'),
//             ),
//           ],
//         ),
//         barrierDismissible: false,
//       );
//     } catch (e) {
//       print('Error al mostrar diálogo de logout: $e');
//       Get.snackbar(
//         'Error',
//         'No se pudo iniciar el proceso de cierre de sesión',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userController = _ensureUserInfoController();
//     return SafeArea(
//       child: Drawer(
//         backgroundColor: const Color(0xFF1A1A2E),
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: ListTile(
//                 leading: Icon(Icons.search, color: Colors.white),
//                 title: Text('Buscar', style: TextStyle(color: Colors.white)),
//                 contentPadding: EdgeInsets.zero,
//               ),
//             ),
//             // Perfil de usuario
//             Container(
//               padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//               decoration: BoxDecoration(
//                 border: Border(
//                   bottom: BorderSide(
//                     color: Colors.grey.withOpacity(0.3),
//                     width: 1,
//                   ),
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   Obx(() => CircleAvatar(
//                         radius: 30,
//                         backgroundColor: Colors.orange,
//                         child: Text(
//                           userController.userInitial.value,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       )),
//                   const SizedBox(height: 12),
//                   Obx(() => Text(
//                         userController.userName.value,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       )),
//                   const SizedBox(height: 4),
//                   Obx(() => Text(
//                         userController.userEmail.value,
//                         style: TextStyle(
//                           color: Colors.grey[400],
//                           fontSize: 14,
//                         ),
//                       )),
//                 ],
//               ),
//             ),
//             _DrawerTile(
//               icon: Icons.sell,
//               title: 'Servicios',
//               onTap: () async {
//                 Get.back();
//                 try {
//                   final servicesController = Get.find<ServicesController>();
//                   await servicesController.initializeServices();
//                   Get.toNamed('/services');
//                   await Get.toNamed(GetRoutes.services);
//                 } catch (e) {
//                   print('Error inicializando servicios: $e');
//                   Get.toNamed('/services');
//                 }
//               },
//             ),
//             _DrawerTile(
//               icon: Icons.people,
//               title: 'Clientela',
//               onTap: () async {
//                 Get.back();
//                 try {
//                   final clientsController = Get.find<ClientsController>();
//                   await clientsController
//                       .loadClients(); // Método similar a initializeServices
//                   Get.toNamed('/clients'); // Usar la ruta definida en GetRoutes
//                 } catch (e) {
//                   print('Error inicializando clientes: $e');
//                   Get.toNamed('/clients');
//                 }
//               },
//             ),
//             _DrawerTile(
//               icon: Icons.message,
//               title: 'Mensajes',
//               onTap: () {
//                 Get.back();
//                 // Get.to(() => const MensajesScreen());
//               },
//             ),
//             _DrawerTile(
//               icon: Icons.monetization_on,
//               title: 'Gastos',
//               onTap: () {
//                 Get.back();
//                 // Get.to(() => const GastosScreen());
//               },
//             ),
//             _DrawerTile(
//               icon: Icons.bar_chart,
//               title: 'Informes',
//               onTap: () {
//                 Get.back();
//                 try {
//                   print('Roles del usuario: ${userController.userRoles}');

//                   // Extraer el token y verificar el rol
//                   final token =
//                       userController.storage.read(key: 'token').then((value) {
//                     if (value != null) {
//                       final parts = value.split('.');
//                       if (parts.length == 3) {
//                         final payload = json.decode(
//                           utf8.decode(
//                               base64Url.decode(base64Url.normalize(parts[1]))),
//                         );

//                         final roles = payload['roles'];
//                         final bool isEmployee = roles is List
//                             ? roles.contains('Employee') &&
//                                 !roles.contains('Owner')
//                             : roles == 'Employee';

//                         print('Es solo empleado: $isEmployee');

//                         // Navegar a la ruta correspondiente
//                         if (isEmployee) {
//                           Get.toNamed('/employee-statistics');
//                         } else {
//                           Get.toNamed('/statistics');
//                         }
//                       }
//                     }
//                   });
//                 } catch (e) {
//                   print('Error al verificar rol y navegar: $e');
//                   // Si hay error, intentar la ruta de estadísticas general
//                   Get.toNamed('/statistics');
//                 }
//               },
//             ),
//             _DrawerTile(
//               icon: Icons.calendar_today,
//               title: 'Reserva Online',
//               onTap: () {
//                 Get.back();
//                 // Get.to(() => const ReservaScreen());
//               },
//             ),
//             _DrawerTile(
//               icon: Icons.person,
//               title: 'Personal',
//               onTap: () async {
//                 Get.back(); // Cerrar el drawer primero
//                 try {
//                   // Usar la constante de rutas
//                   await Get.toNamed(GetRoutes.employees);
//                 } catch (e) {
//                   print('Error al navegar a Personal: $e');
//                   Get.snackbar(
//                     'Error',
//                     'No se pudo cargar la pantalla de Personal',
//                     backgroundColor: Colors.red[100],
//                     colorText: Colors.red[900],
//                     snackPosition: SnackPosition.BOTTOM,
//                   );
//                 }
//               },
//             ),
//             _DrawerTile(
//               icon: Icons.description,
//               title: 'Formularios',
//               onTap: () {
//                 Get.back();
//                 // Get.to(() => const FormulariosScreen());
//               },
//             ),
//             Divider(color: Colors.grey.withOpacity(0.3)),
//             _DrawerTile(
//               icon: Icons.settings,
//               title: 'Ajustes',
//               onTap: () {
//                 Get.back();
//                 Get.toNamed('/whatsapp-config');
//               },
//             ),
//             _DrawerTile(
//               icon: Icons.logout_rounded,
//               title: 'Cerrar Sesión',
//               onTap: () {
//                 Get.back();
//                 _showLogoutDialog();
//               },
//             ),
//             _DrawerTile(
//               icon: Icons.help,
//               title: 'Centro de ayuda',
//               onTap: () {
//                 Get.back();
//                 // Get.to(() => const AyudaScreen());
//               },
//             ),
//             _DrawerTile(
//               icon: Icons.send,
//               title: 'Enviar opiniones',
//               onTap: () {
//                 Get.back();
//                 // Get.to(() => const OpinionesScreen());
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _DrawerTile extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final Widget? trailing;
//   final VoidCallback? onTap;

//   const _DrawerTile({
//     required this.icon,
//     required this.title,
//     this.trailing,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.white),
//       title: Text(title, style: const TextStyle(color: Colors.white)),
//       trailing: trailing,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//       onTap: onTap,
//     );
//   }
// }

import 'dart:convert';

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
      Get.put(controller);
      return controller;
    }
  }

  void _showLogoutDialog() {
    try {
      final logoutController = Get.find<LogoutController>();
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(fontWeight: FontWeight.bold),
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
                logoutController.logout();
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

  // Método para verificar si el usuario es Owner
  Future<bool> _isOwner(UserInfoController userController) async {
    try {
      final token = await userController.storage.read(key: 'token');
      if (token != null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );
          final roles = payload['roles'];
          return roles is List ? roles.contains('Owner') : roles == 'Owner';
        }
      }
      return false;
    } catch (e) {
      print('Error al verificar el rol de Owner: $e');
      return false;
    }
  }

  // Método para verificar si el usuario es Employee
  Future<bool> _isEmployee(UserInfoController userController) async {
    try {
      final token = await userController.storage.read(key: 'token');
      if (token != null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );
          final roles = payload['roles'];
          return roles is List
              ? roles.contains('Employee')
              : roles == 'Employee';
        }
      }
      return false;
    } catch (e) {
      print('Error al verificar el rol de Employee: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = _ensureUserInfoController();

    return SafeArea(
      child: Drawer(
        backgroundColor: const Color(0xFF1A1A2E),
        child: FutureBuilder<List<bool>>(
          future: Future.wait(
              [_isOwner(userController), _isEmployee(userController)]),
          builder: (context, snapshot) {
            final bool isOwner =
                snapshot.data != null ? snapshot.data![0] : false;
            final bool isEmployee =
                snapshot.data != null ? snapshot.data![1] : false;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                // Buscar - visible para todos
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.search, color: Colors.white),
                    title:
                        Text('Buscar', style: TextStyle(color: Colors.white)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                // Perfil de usuario - visible para todos
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Obx(() => CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.orange,
                            child: Text(
                              userController.userInitial.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )),
                      const SizedBox(height: 12),
                      Obx(() => Text(
                            userController.userName.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          )),
                      const SizedBox(height: 4),
                      Obx(() => Text(
                            userController.userEmail.value,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          )),
                    ],
                  ),
                ),

                // Elementos condicionales según el rol
                // Solo visible para Owner
                if (isOwner) ...[
                  _DrawerTile(
                    icon: Icons.sell,
                    title: 'Servicios',
                    onTap: () async {
                      Get.back();
                      try {
                        final servicesController =
                            Get.find<ServicesController>();
                        await servicesController.initializeServices();
                        Get.toNamed('/services');
                        await Get.toNamed(GetRoutes.services);
                      } catch (e) {
                        print('Error inicializando servicios: $e');
                        Get.toNamed('/services');
                      }
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.people,
                    title: 'Clientela',
                    onTap: () async {
                      Get.back();
                      try {
                        final clientsController = Get.find<ClientsController>();
                        await clientsController
                            .loadClients(); // Método similar a initializeServices
                        Get.toNamed(
                            '/clients'); // Usar la ruta definida en GetRoutes
                      } catch (e) {
                        print('Error inicializando clientes: $e');
                        Get.toNamed('/clients');
                      }
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
                    onTap: () async {
                      Get.back(); // Cerrar el drawer primero
                      try {
                        // Usar la constante de rutas
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
                  _DrawerTile(
                    icon: Icons.description,
                    title: 'Formularios',
                    onTap: () {
                      Get.back();
                      // Get.to(() => const FormulariosScreen());
                    },
                  ),
                ],

                // Visible para Owner y Employee
                _DrawerTile(
                  icon: Icons.bar_chart,
                  title: 'Informes',
                  onTap: () {
                    Get.back();
                    try {
                      print('Roles del usuario: ${userController.userRoles}');

                      // Extraer el token y verificar el rol
                      final token = userController.storage
                          .read(key: 'token')
                          .then((value) {
                        if (value != null) {
                          final parts = value.split('.');
                          if (parts.length == 3) {
                            final payload = json.decode(
                              utf8.decode(base64Url
                                  .decode(base64Url.normalize(parts[1]))),
                            );

                            final roles = payload['roles'];
                            final bool isEmployee = roles is List
                                ? roles.contains('Employee') &&
                                    !roles.contains('Owner')
                                : roles == 'Employee';

                            print('Es solo empleado: $isEmployee');

                            // Navegar a la ruta correspondiente
                            if (isEmployee) {
                              Get.toNamed('/employee-statistics');
                            } else {
                              Get.toNamed('/statistics');
                            }
                          }
                        }
                      });
                    } catch (e) {
                      print('Error al verificar rol y navegar: $e');
                      // Si hay error, intentar la ruta de estadísticas general
                      Get.toNamed('/statistics');
                    }
                  },
                ),

                // Separador si hay elementos de Owner que mostrar
                if (isOwner) Divider(color: Colors.grey.withOpacity(0.3)),

                // Elementos visibles para todos los roles
                _DrawerTile(
                  icon: Icons.settings,
                  title: 'Ajustes',
                  onTap: () {
                    Get.back();
                    Get.toNamed('/whatsapp-config');
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
                    Get.toNamed('/subscription-plans');
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
            );
          },
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
