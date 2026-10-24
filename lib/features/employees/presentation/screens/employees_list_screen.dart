import 'package:login_signup/core/routes/routes.dart';
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/core/constants/app_colors.dart';
// import 'package:login_signup/features/auth/presentation/controllers/user_info_controller.dart';
// import 'package:login_signup/features/employees/data/models/employee_model.dart';
// import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
// import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
// import 'package:login_signup/features/employees/presentation/screens/create_employee_screen.dart';
// import 'package:login_signup/features/employees/presentation/screens/edit_employee_screen.dart';
// import 'package:login_signup/features/employees/presentation/screens/employee_details_screen.dart';
// import 'package:login_signup/features/employees/presentation/widgets/search_bar_widget.dart';
// import 'package:login_signup/features/employees/presentation/widgets/toggle_status_dialog.dart';
// import 'package:login_signup/features/services/presentation/controller/services_controller.dart';

// class EmployeesListScreen extends StatelessWidget {
//   const EmployeesListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final TextEditingController searchController = TextEditingController();

//     return GetBuilder<EmployeesController>(
//       init: Get.find<EmployeesController>(),
//       initState: (_) {
//         // Este callback se ejecuta cuando se inicializa el widget
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Get.find<EmployeesController>().loadEmployees();
//         });
//       },
//       builder: (controller) {
//         return Scaffold(
//           appBar: AppBar(
//             title: Obx(() => Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       controller.showDeletedEmployees.value
//                           ? 'Profesionales'
//                           : 'Profesionales',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       controller.showDeletedEmployees.value
//                           ? 'Eliminados (${controller.filteredDeletedEmployees.length})'
//                           : 'Activos (${controller.filteredEmployees.length})',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w400,
//                         color: controller.showDeletedEmployees.value
//                             ? Colors.red[600]
//                             : Colors.green[600],
//                       ),
//                     ),
//                   ],
//                 )),
//             leading: IconButton(
//               icon: const Icon(Icons.arrow_back),
//               onPressed: () {
//                 Get.offAllNamed('/');
//               },
//             ),
//             centerTitle: true,
//             actions: [
//               // Toggle para ver eliminados/activos
//               Obx(() => IconButton(
//                     icon: Container(
//                       padding: const EdgeInsets.all(6),
//                       decoration: BoxDecoration(
//                         color: controller.showDeletedEmployees.value
//                             ? Colors.red.withOpacity(0.1)
//                             : Colors.green.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(
//                         controller.showDeletedEmployees.value
//                             ? Icons.people
//                             : Icons.delete_forever,
//                         color: controller.showDeletedEmployees.value
//                             ? Colors.green[600]
//                             : Colors.red[600],
//                         size: 20,
//                       ),
//                     ),
//                     onPressed: () => controller.toggleDeletedEmployeesView(),
//                     tooltip: controller.showDeletedEmployees.value
//                         ? 'Ver activos'
//                         : 'Ver eliminados',
//                   )),
//               // Botón de actualizar
//               IconButton(
//                 icon: const Icon(Icons.refresh),
//                 onPressed: () {
//                   controller.refreshAllData();
//                   Get.snackbar(
//                     'Actualizado',
//                     'Lista actualizada',
//                     snackPosition: SnackPosition.TOP,
//                     duration: const Duration(seconds: 1),
//                   );
//                 },
//               ),
//             ],
//           ),
//           body: Column(
//             children: [
//               // Barra de búsqueda
//               SearchBarWidget(
//                 hint: 'Buscar profesionales',
//                 onChanged: (value) {
//                   controller.updateSearchQuery(value);
//                 },
//                 onClear: () {
//                   controller.updateSearchQuery('');
//                 },
//                 controller: searchController,
//               ),

//               // Lista de empleados
//               Expanded(
//                 child: RefreshIndicator(
//                   onRefresh: () => controller.refreshAllData(),
//                   child: Obx(() {
//                     final currentList = controller.getCurrentEmployeesList();
//                     final isLoading = controller.getCurrentLoadingState();

//                     if (isLoading && currentList.isEmpty) {
//                       return const Center(
//                         child: CircularProgressIndicator(),
//                       );
//                     }

//                     if (currentList.isEmpty) {
//                       if (controller.searchQuery.isNotEmpty) {
//                         // No se encontraron resultados de búsqueda
//                         return Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               const Icon(
//                                 Icons.search_off,
//                                 size: 70,
//                                 color: Colors.grey,
//                               ),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'No se encontraron profesionales con "${controller.searchQuery.value}"',
//                                 style: const TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.grey,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                               const SizedBox(height: 8),
//                               ElevatedButton.icon(
//                                 onPressed: () {
//                                   searchController.clear();
//                                   controller.updateSearchQuery('');
//                                 },
//                                 icon: const Icon(Icons.clear),
//                                 label: const Text('Limpiar búsqueda'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: AppColors.cardIndicator,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       } else {
//                         // Estado vacío según el tipo de lista
//                         return controller.showDeletedEmployees.value
//                             ? _buildEmptyDeletedState(context)
//                             : _buildEmptyState(context);
//                       }
//                     }

//                     return ListView.builder(
//                       padding: const EdgeInsets.all(16),
//                       itemCount: currentList.length,
//                       itemBuilder: (context, index) {
//                         final employee = currentList[index];
//                         return _buildEmployeeCard(
//                             employee, context, controller);
//                       },
//                     );
//                   }),
//                 ),
//               ),
//             ],
//           ),
//           floatingActionButton: FloatingActionButton(
//             heroTag: 'createEmployeeButton',
//             onPressed: () async {
//               try {
//                 print('Iniciando navegación a CreateEmployeeScreen...');

//                 // Asegurarnos de que los controladores estén disponibles
//                 final employeesController = Get.find<EmployeesController>();

//                 // Verificar si ServicesController está registrado
//                 if (!Get.isRegistered<ServicesController>()) {
//                   print('ServicesController no encontrado, registrando...');
//                   Get.put(
//                     ServicesController(getServicesUseCase: Get.find()),
//                     permanent: true,
//                   );
//                 }

//                 // Pre-cargar servicios antes de navegar
//                 final servicesController = Get.find<ServicesController>();

//                 // Cargar servicios explícitamente
//                 if (servicesController.services.isEmpty) {
//                   print('Pre-cargando servicios...');
//                   await servicesController.loadServices();
//                 }

//                 // Navegar a la pantalla
//                 print('Navegando a CreateEmployeeScreen...');
//                 Get.to(
//                   () => const CreateEmployeeScreen(),
//                   transition: Transition.rightToLeft,
//                   duration: const Duration(milliseconds: 250),
//                 );
//               } catch (e) {
//                 print('Error al navegar: $e');
//                 Get.snackbar(
//                   'Error',
//                   'No se pudo abrir la pantalla de creación',
//                   snackPosition: SnackPosition.TOP,
//                 );
//               }
//             },
//             backgroundColor: AppColors.cardIndicator,
//             child: const Icon(Icons.add),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEmptyState(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(
//             Icons.people_outline,
//             size: 80,
//             color: Colors.grey,
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'No hay profesionales registrados',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Añade tu primer profesional pulsando el botón +',
//             style: TextStyle(
//               color: Colors.grey,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.cardIndicator,
//               minimumSize: const Size(200, 45),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             onPressed: () {
//               try {
//                 if (!Get.isRegistered<ServicesController>()) {
//                   Get.put(
//                     ServicesController(getServicesUseCase: Get.find()),
//                     permanent: true,
//                   );
//                 }
//                 Get.to(() => const CreateEmployeeScreen());
//               } catch (e) {
//                 print('Error navegando desde estado vacío: $e');
//                 Get.snackbar(
//                   'Error',
//                   'No se pudo abrir la pantalla de creación',
//                   snackPosition: SnackPosition.TOP,
//                 );
//               }
//             },
//             child: const Text(
//               'Crear Profesional',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyDeletedState(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(
//             Icons.restore_from_trash,
//             size: 80,
//             color: Colors.grey,
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'No hay profesionales eliminados',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Los profesionales eliminados aparecerán aquí',
//             style: TextStyle(
//               color: Colors.grey,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.teal,
//               minimumSize: const Size(200, 45),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             onPressed: () {
//               Get.find<EmployeesController>()
//                   .switchEmployeeView(showDeleted: false);
//             },
//             icon: const Icon(Icons.people, color: Colors.white),
//             label: const Text(
//               'Ver Profesionales Activos',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Método para verificar si un empleado específico es Owner basado en sus roles
//   bool _isEmployeeOwner(EmployeeEntity employee) {
//     try {
//       // Verificar si tiene rol de Owner en la lista de roles
//       if (employee.roles.isNotEmpty) {
//         return employee.roles.any((role) => role.name == 'Owner');
//       }
//       return false;
//     } catch (e) {
//       print('Error al verificar si el empleado es Owner: $e');
//       return false;
//     }
//   }

// // Método adicional para verificar el rol del usuario actual logueado
//   Future<bool> _isCurrentUserOwner() async {
//     try {
//       final userController = Get.find<UserInfoController>();
//       final token = await userController.storage.read(key: 'token');

//       if (token != null) {
//         final parts = token.split('.');
//         if (parts.length == 3) {
//           final payload = json.decode(
//             utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
//           );
//           final roles = payload['roles'];
//           return roles is List ? roles.contains('Owner') : roles == 'Owner';
//         }
//       }
//       return false;
//     } catch (e) {
//       print('Error al verificar el rol del usuario actual: $e');
//       return false;
//     }
//   }

//   Widget _buildEmployeeCard(EmployeeEntity employee, BuildContext context,
//       EmployeesController controller) {
//     final bool isActive = employee.isActive;

//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           // Usar gradiente para un efecto visual más agradable
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Colors.white,
//               // Color de fondo basado en el estado (verde para activo, rojo tenue para inactivo)
//               isActive ? Colors.green[50]! : Colors.red[50]!,
//             ],
//           ),
//           // Borde sutil para reforzar el estado
//           border: Border.all(
//             color: isActive ? Colors.green[200]! : Colors.red[200]!,
//             width: 1.0,
//           ),
//         ),
//         child: ListTile(
//           contentPadding:
//               const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           leading: Hero(
//             tag: 'avatar_${employee.id}',
//             child: CircleAvatar(
//               backgroundColor: isActive ? AppColors.cardIndicator : Colors.grey,
//               radius: 28,
//               child: employee.image != null && employee.image!.isNotEmpty
//                   ? ClipRRect(
//                       borderRadius: BorderRadius.circular(28),
//                       child: Image.network(
//                         employee.image!,
//                         width: 56,
//                         height: 56,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Text(
//                             employee.name.isNotEmpty
//                                 ? employee.name[0].toUpperCase()
//                                 : '?',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           );
//                         },
//                       ),
//                     )
//                   : Text(
//                       employee.name.isNotEmpty
//                           ? employee.name[0].toUpperCase()
//                           : '?',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                       ),
//                     ),
//             ),
//           ),
//           title: Text(
//             employee.fullName,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 17,
//             ),
//           ),
//           subtitle: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 4),
//               Text(
//                 employee.email,
//                 style: const TextStyle(fontSize: 14),
//               ),
//               if (employee.phone.isNotEmpty) ...[
//                 const SizedBox(height: 2),
//                 Text(
//                   employee.phone,
//                   style: const TextStyle(fontSize: 14),
//                 ),
//               ],
//               const SizedBox(height: 6),
//               Row(
//                 children: [
//                   Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                     decoration: BoxDecoration(
//                       color: employee.statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(4),
//                       border: Border.all(
//                           color: employee.statusColor.withOpacity(0.4)),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           employee.statusIcon,
//                           size: 14,
//                           color: employee.statusColor,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           employee.displayStatus,
//                           style: TextStyle(
//                             color: employee.statusColor,
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   if (employee.serviceIds != null &&
//                       employee.serviceIds!.isNotEmpty) ...[
//                     const SizedBox(width: 8),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 3),
//                       decoration: BoxDecoration(
//                         color: Colors.blue[50],
//                         borderRadius: BorderRadius.circular(4),
//                         border: Border.all(color: Colors.blue[300]!),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Icon(
//                             Icons.spa,
//                             size: 14,
//                             color: AppColors.cardIndicator,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${employee.serviceIds!.length} servicios',
//                             style: TextStyle(
//                               color: Colors.blue[700],
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                   // 🆕 NUEVO: Indicador para Owners
//                   if (_isEmployeeOwner(employee)) ...[
//                     const SizedBox(width: 8),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 3),
//                       decoration: BoxDecoration(
//                         color: Colors.amber[50],
//                         borderRadius: BorderRadius.circular(4),
//                         border: Border.all(color: Colors.amber[300]!),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Icon(
//                             Icons.business_center,
//                             size: 14,
//                             color: Colors.amber,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             'Propietario',
//                             style: TextStyle(
//                               color: Colors.amber[700],
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ],
//           ),
//           trailing: IconButton(
//             icon: const Icon(
//               Icons.more_vert,
//               color: AppColors.cardIndicator,
//             ),
//             onPressed: () => _showOptions(context, employee, controller),
//           ),
//           onTap: () => _showEmployeeDetails(context, employee),
//         ),
//       ),
//     );
//   }

//   void _showOptions(BuildContext context, EmployeeEntity employee,
//       EmployeesController controller) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Container(
//           padding: const EdgeInsets.symmetric(vertical: 20),
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           ),
//           child: SafeArea(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   height: 5,
//                   width: 40,
//                   margin: const EdgeInsets.only(bottom: 20),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                 ),

//                 // 🆕 LÓGICA PRINCIPAL: Diferentes opciones según el tipo de usuario

//                 // CASO 1: Empleado eliminado (no Owner)
//                 if (employee.isDeleted && !_isEmployeeOwner(employee)) ...[
//                   ListTile(
//                     leading: const CircleAvatar(
//                       backgroundColor: Colors.teal,
//                       child: Icon(Icons.restore, color: Colors.white),
//                     ),
//                     title: const Text('Restaurar'),
//                     subtitle: const Text('Volver a activar empleado'),
//                     onTap: () {
//                       Navigator.pop(context);
//                       controller.showRestoreEmployeeDialog(employee);
//                     },
//                   ),
//                   const Divider(height: 0.5),
//                   if (employee.deletionReason != null &&
//                       employee.deletionReason!.isNotEmpty)
//                     ListTile(
//                       leading: const CircleAvatar(
//                         backgroundColor: Colors.grey,
//                         child: Icon(Icons.info, color: Colors.white),
//                       ),
//                       title: const Text('Razón de eliminación'),
//                       subtitle: Text(
//                         employee.deletionReason!,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       onTap: () {
//                         Navigator.pop(context);
//                         _showDeletionReasonDialog(context, employee);
//                       },
//                     ),
//                   if (employee.deletedAt != null) ...[
//                     const Divider(height: 0.5),
//                     ListTile(
//                       leading: const CircleAvatar(
//                         backgroundColor: Colors.orange,
//                         child: Icon(Icons.access_time, color: Colors.white),
//                       ),
//                       title: const Text('Fecha de eliminación'),
//                       subtitle: Text(
//                         '${employee.deletedAt!.day}/${employee.deletedAt!.month}/${employee.deletedAt!.year} a las ${employee.deletedAt!.hour}:${employee.deletedAt!.minute.toString().padLeft(2, '0')}',
//                       ),
//                       onTap: () => Navigator.pop(context),
//                     ),
//                   ],
//                 ]

//                 // CASO 2: Owner activo - Solo ver detalles
//                 else if (_isEmployeeOwner(employee) && !employee.isDeleted) ...[
//                   ListTile(
//                     leading: const CircleAvatar(
//                       backgroundColor: Colors.blue,
//                       child: Icon(Icons.visibility, color: Colors.white),
//                     ),
//                     title: const Text('Ver mi perfil'),
//                     subtitle: const Text('Ver información del propietario'),
//                     onTap: () {
//                       Navigator.pop(context);
//                       _showEmployeeDetails(context, employee);
//                     },
//                   ),
//                   const Divider(height: 0.5),
//                   ListTile(
//                     leading: const CircleAvatar(
//                       backgroundColor: Colors.amber,
//                       child: Icon(Icons.business_center, color: Colors.white),
//                     ),
//                     title: const Text('Perfil de Propietario'),
//                     subtitle: const Text(
//                         'Tu cuenta tiene privilegios de administrador'),
//                     enabled: false,
//                     titleTextStyle: TextStyle(
//                       color: Colors.amber[700],
//                       fontWeight: FontWeight.w500,
//                     ),
//                     subtitleTextStyle: TextStyle(
//                       color: Colors.amber[600],
//                       fontSize: 12,
//                     ),
//                   ),
//                   const Divider(height: 0.5),
//                   ListTile(
//                     leading: const CircleAvatar(
//                       backgroundColor: Colors.grey,
//                       child: Icon(Icons.info_outline, color: Colors.white),
//                     ),
//                     title: const Text('Información'),
//                     subtitle: const Text(
//                         'Los propietarios se gestionan desde Ajustes'),
//                     onTap: () {
//                       Navigator.pop(context);
//                       Get.dialog(
//                         AlertDialog(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           title: const Row(
//                             children: [
//                               Icon(Icons.info_outline, color: Colors.blue),
//                               SizedBox(width: 10),
//                               Text(
//                                 'Gestión de Propietario',
//                                 style: TextStyle(
//                                     fontSize: 20, fontWeight: FontWeight.bold),
//                               ),
//                             ],
//                           ),
//                           content: const Column(
//                             mainAxisSize: MainAxisSize.min,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Como propietario del negocio, tu perfil tiene características especiales:',
//                                 style: TextStyle(fontWeight: FontWeight.w500),
//                               ),
//                               SizedBox(height: 12),
//                               Row(
//                                 children: [
//                                   Icon(Icons.security,
//                                       size: 16, color: Colors.green),
//                                   SizedBox(width: 8),
//                                   Expanded(
//                                       child: Text('No puede ser eliminado',
//                                           style: TextStyle(fontSize: 14))),
//                                 ],
//                               ),
//                               SizedBox(height: 6),
//                               Row(
//                                 children: [
//                                   Icon(Icons.admin_panel_settings,
//                                       size: 16, color: Colors.blue),
//                                   SizedBox(width: 8),
//                                   Expanded(
//                                       child: Text('Acceso completo al sistema',
//                                           style: TextStyle(fontSize: 14))),
//                                 ],
//                               ),
//                               SizedBox(height: 6),
//                               Row(
//                                 children: [
//                                   Icon(Icons.settings,
//                                       size: 16, color: Colors.orange),
//                                   SizedBox(width: 8),
//                                   Expanded(
//                                       child: Text('Configuración desde Ajustes',
//                                           style: TextStyle(fontSize: 14))),
//                                 ],
//                               ),
//                               SizedBox(height: 12),
//                               Text(
//                                 'Para modificar tu información personal, ve a la sección de Ajustes en el menú principal.',
//                                 style:
//                                     TextStyle(fontSize: 13, color: Colors.grey),
//                               ),
//                             ],
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Get
//                                   .back(), // 🔧 CAMBIO: Usar Get.back() en lugar de Navigator.of(context).pop()
//                               child: const Text('Entendido'),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ]

//                 // CASO 3: Owner eliminado (caso especial, no debería pasar pero por seguridad)
//                 else if (_isEmployeeOwner(employee) && employee.isDeleted) ...[
//                   ListTile(
//                     leading: const CircleAvatar(
//                       backgroundColor: Colors.red,
//                       child: Icon(Icons.error_outline, color: Colors.white),
//                     ),
//                     title: const Text('Error del Sistema'),
//                     subtitle:
//                         const Text('Un propietario no debería estar eliminado'),
//                     enabled: false,
//                   ),
//                   const Divider(height: 0.5),
//                   ListTile(
//                     leading: const CircleAvatar(
//                       backgroundColor: Colors.amber,
//                       child: Icon(Icons.support_agent, color: Colors.white),
//                     ),
//                     title: const Text('Contactar Soporte'),
//                     subtitle:
//                         const Text('Este es un error que debe ser reportado'),
//                     onTap: () {
//                       Navigator.pop(context);
//                       Get.dialog(
//                         AlertDialog(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           title: const Row(
//                             children: [
//                               Icon(Icons.error_outline, color: Colors.red),
//                               SizedBox(width: 10),
//                               Text('Error del Sistema'),
//                             ],
//                           ),
//                           content: const Text(
//                             'Se ha detectado una inconsistencia en los datos. Un propietario no debería aparecer como eliminado. Por favor, contacta al soporte técnico.',
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.of(context).pop(),
//                               child: const Text('Cerrar'),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ]

//                 // CASO 4: Empleado normal activo - Todas las opciones de gestión
//                 else ...[
//                   ListTile(
//                     leading: const CircleAvatar(
//                       backgroundColor: Colors.blue,
//                       child: Icon(Icons.visibility, color: Colors.white),
//                     ),
//                     title: const Text('Ver detalles'),
//                     subtitle: const Text('Ver información completa'),
//                     onTap: () {
//                       Navigator.pop(context);
//                       _showEmployeeDetails(context, employee);
//                     },
//                   ),
//                   const Divider(height: 0.5),
//                   ListTile(
//                     leading: const CircleAvatar(
//                       backgroundColor: Colors.green,
//                       child: Icon(Icons.edit, color: Colors.white),
//                     ),
//                     title: const Text('Editar'),
//                     subtitle: const Text('Modificar información'),
//                     onTap: () {
//                       Navigator.pop(context);
//                       _navigateToEditScreen(employee.id);
//                     },
//                   ),
//                   const Divider(height: 0.5),
//                   ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor:
//                           employee.isActive ? Colors.orange : Colors.green,
//                       child: Icon(
//                         employee.isActive ? Icons.person_off : Icons.person,
//                         color: Colors.white,
//                       ),
//                     ),
//                     title: Text(
//                       employee.isActive ? 'Desactivar' : 'Activar',
//                       style: TextStyle(
//                         color: employee.isActive ? Colors.orange : Colors.green,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     subtitle: Text(
//                       employee.isActive
//                           ? 'El profesional no estará disponible'
//                           : 'El profesional estará disponible',
//                     ),
//                     onTap: () {
//                       Navigator.pop(context);
//                       _handleStatusToggle(context, employee, controller);
//                     },
//                   ),
//                   const Divider(height: 0.5),
//                   ListTile(
//                     leading: const CircleAvatar(
//                       backgroundColor: Colors.red,
//                       child: Icon(Icons.delete_forever, color: Colors.white),
//                     ),
//                     title: const Text('Eliminar'),
//                     subtitle: const Text('Eliminar profesional (soft delete)'),
//                     onTap: () {
//                       Navigator.pop(context);
//                       controller.showDeleteEmployeeDialog(employee);
//                     },
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _showDeletionReasonDialog(
//       BuildContext context, EmployeeEntity employee) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: const Row(
//             children: [
//               Icon(Icons.info_outline, color: Colors.orange),
//               SizedBox(width: 10),
//               Text('Razón de Eliminación'),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Empleado: ${employee.fullName}',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               if (employee.deletedAt != null)
//                 Text(
//                   'Eliminado el: ${employee.deletedAt!.day}/${employee.deletedAt!.month}/${employee.deletedAt!.year}',
//                   style: TextStyle(color: Colors.grey[600]),
//                 ),
//               const SizedBox(height: 16),
//               const Text(
//                 'Razón:',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey[300]!),
//                 ),
//                 child: Text(
//                   employee.deletionReason ?? 'Sin razón especificada',
//                   style: const TextStyle(fontSize: 14),
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cerrar'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _handleStatusToggle(BuildContext context, EmployeeEntity employee,
//       EmployeesController controller) {
//     // Mostrar diálogo de confirmación
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) => ToggleStatusDialog(
//         employee: employee,
//         onConfirm: (newStatus) {
//           // Cerrar el diálogo primero
//           Navigator.pop(dialogContext);

//           // 🆕 NUEVO: Lógica simplificada sin navegación
//           _performStatusToggle(controller, employee, newStatus);
//         },
//       ),
//     );
//   }

//   void _performStatusToggle(
//       EmployeesController controller, EmployeeEntity employee, bool newStatus) {
//     // Mostrar SnackBar de progreso
//     Get.snackbar(
//       newStatus ? 'Activando...' : 'Desactivando...',
//       'Procesando cambio de estado',
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: newStatus
//           ? Colors.green.withOpacity(0.8)
//           : Colors.orange.withOpacity(0.8),
//       colorText: Colors.white,
//       duration: const Duration(seconds: 2),
//       showProgressIndicator: true,
//       progressIndicatorBackgroundColor: Colors.white,
//       margin: const EdgeInsets.all(10),
//       borderRadius: 10,
//       icon: Icon(
//         newStatus ? Icons.check_circle_outline : Icons.person_off_outlined,
//         color: Colors.white,
//       ),
//     );

//     // Llamar al método del controlador
//     controller.toggleEmployeeStatus(employee.id, newStatus).then((success) {
//       // Cerrar el SnackBar de progreso
//       Get.closeAllSnackbars();

//       if (success) {
//         // 🎯 CLAVE: Actualizar el empleado en la lista local directamente
//         final employeeIndex =
//             controller.employees.indexWhere((e) => e.id == employee.id);
//         if (employeeIndex >= 0) {
//           // Crear una copia actualizada del empleado
//           final updatedEmployee = employee is EmployeeModel
//               ? (employee as EmployeeModel).copyWith(isActive: newStatus)
//               : employee; // Si no es EmployeeModel, usar el original

//           // Actualizar en la lista
//           controller.employees[employeeIndex] = updatedEmployee;

//           // Actualizar listas filtradas
//           controller.filterEmployees();
//           controller.update();
//         }

//         // Mostrar notificación de éxito
//         Get.snackbar(
//           newStatus ? 'Profesional Activado' : 'Profesional Desactivado',
//           newStatus
//               ? 'El profesional ha sido activado correctamente'
//               : 'El profesional ha sido desactivado correctamente',
//           snackPosition: SnackPosition.TOP,
//           backgroundColor: newStatus
//               ? Colors.green.withOpacity(0.8)
//               : Colors.orange.withOpacity(0.8),
//           colorText: Colors.white,
//           duration: const Duration(seconds: 2),
//           margin: const EdgeInsets.all(10),
//           borderRadius: 10,
//           icon: Icon(
//             newStatus ? Icons.check_circle : Icons.person_off,
//             color: Colors.white,
//           ),
//         );
//       } else {
//         // Mostrar error si algo salió mal
//         Get.snackbar(
//           'Error',
//           'No se pudo cambiar el estado del profesional',
//           snackPosition: SnackPosition.TOP,
//           backgroundColor: Colors.red.withOpacity(0.8),
//           colorText: Colors.white,
//           duration: const Duration(seconds: 3),
//           margin: const EdgeInsets.all(10),
//           borderRadius: 10,
//           icon: const Icon(Icons.error_outline, color: Colors.white),
//         );
//       }
//     }).catchError((error) {
//       // Cerrar el SnackBar de progreso
//       Get.closeAllSnackbars();

//       // Mostrar notificación de error
//       Get.snackbar(
//         'Error',
//         'No se pudo ${newStatus ? "activar" : "desactivar"} al profesional: ${error.toString()}',
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: Colors.red.withOpacity(0.8),
//         colorText: Colors.white,
//         duration: const Duration(seconds: 3),
//         margin: const EdgeInsets.all(10),
//         borderRadius: 10,
//         icon: const Icon(Icons.error_outline, color: Colors.white),
//       );
//     });
//   }

//   void _navigateToEditScreen(String employeeId) {
//     // Usar navegación directa, no rutas nombradas
//     Get.to(
//       () => EditEmployeeScreen(employeeId: employeeId),
//       transition: Transition.rightToLeft,
//     );
//   }

//   void _showEmployeeDetails(BuildContext context, EmployeeEntity employee) {
//     // Usar navegación directa, no rutas nombradas
//     Get.to(
//       () => EmployeeDetailsScreen(employee: employee),
//       transition: Transition.rightToLeft,
//     );
//   }

//   void _showDeleteConfirmation(BuildContext context, EmployeeEntity employee,
//       EmployeesController controller) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: const Text('Eliminar Profesional'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.warning_amber_rounded,
//                 color: Colors.red,
//                 size: 64,
//               ),
//               const SizedBox(height: 16),
//               RichText(
//                 textAlign: TextAlign.center,
//                 text: TextSpan(
//                   style: const TextStyle(color: Colors.black87, fontSize: 16),
//                   children: [
//                     const TextSpan(
//                         text: '¿Estás seguro que deseas eliminar a '),
//                     TextSpan(
//                       text: employee.fullName,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black,
//                       ),
//                     ),
//                     const TextSpan(text: '?'),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Esta acción no se puede deshacer.',
//                 style: TextStyle(color: Colors.red),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancelar'),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//               ),
//               onPressed: () async {
//                 Navigator.of(context).pop();

//                 try {
//                   await controller.deleteEmployee(employee.id);
//                 } catch (e) {
//                   // El snackbar ya se muestra en el controller
//                 }
//               },
//               child: const Text(
//                 'Eliminar',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/constants/app_colors.dart';
import 'package:login_signup/features/employees/data/models/employee_model.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/employees/presentation/screens/create_employee_screen.dart';
import 'package:login_signup/features/employees/presentation/screens/edit_employee_screen.dart';
import 'package:login_signup/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:login_signup/features/employees/presentation/widgets/search_bar_widget.dart';
import 'package:login_signup/features/employees/presentation/widgets/toggle_status_dialog.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';

class EmployeesListScreen extends StatelessWidget {
  const EmployeesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    return GetBuilder<EmployeesController>(
      init: Get.find<EmployeesController>(),
      initState: (_) {
        // Este callback se ejecuta cuando se inicializa el widget
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.find<EmployeesController>().loadEmployees();
        });
      },
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Obx(() => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.showDeletedEmployees.value
                          ? 'Profesionales'
                          : 'Profesionales',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      controller.showDeletedEmployees.value
                          ? 'Eliminados (${controller.filteredDeletedEmployees.length})'
                          : 'Activos (${controller.filteredEmployees.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: controller.showDeletedEmployees.value
                            ? Colors.red[600]
                            : Colors.green[600],
                      ),
                    ),
                  ],
                )),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Get.offAllNamed(GetRoutes.home);
              },
            ),
            centerTitle: true,
            actions: [
              // Toggle para ver eliminados/activos
              Obx(() => IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: controller.showDeletedEmployees.value
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        controller.showDeletedEmployees.value
                            ? Icons.people
                            : Icons.delete_forever,
                        color: controller.showDeletedEmployees.value
                            ? Colors.green[600]
                            : Colors.red[600],
                        size: 20,
                      ),
                    ),
                    onPressed: () => controller.toggleDeletedEmployeesView(),
                    tooltip: controller.showDeletedEmployees.value
                        ? 'Ver activos'
                        : 'Ver eliminados',
                  )),
              // Botón de actualizar
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  controller.refreshAllData();
                  Get.snackbar(
                    'Actualizado',
                    'Lista actualizada',
                    snackPosition: SnackPosition.TOP,
                    duration: const Duration(seconds: 1),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Barra de búsqueda
              SearchBarWidget(
                hint: 'Buscar profesionales',
                onChanged: (value) {
                  controller.updateSearchQuery(value);
                },
                onClear: () {
                  controller.updateSearchQuery('');
                },
                controller: searchController,
              ),

              // Lista de empleados
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => controller.refreshAllData(),
                  child: Obx(() {
                    final currentList = controller.getCurrentEmployeesList();
                    final isLoading = controller.getCurrentLoadingState();

                    if (isLoading && currentList.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (currentList.isEmpty) {
                      if (controller.searchQuery.isNotEmpty) {
                        // No se encontraron resultados de búsqueda
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 70,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron profesionales con "${controller.searchQuery.value}"',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  searchController.clear();
                                  controller.updateSearchQuery('');
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Limpiar búsqueda'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.cardIndicator,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Estado vacío según el tipo de lista
                        return controller.showDeletedEmployees.value
                            ? _buildEmptyDeletedState(context)
                            : _buildEmptyState(context);
                      }
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: currentList.length,
                      itemBuilder: (context, index) {
                        final employee = currentList[index];
                        return _buildEmployeeCard(
                            employee, context, controller);
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'createEmployeeButton',
            onPressed: () async {
              try {
                print('Iniciando navegación a CreateEmployeeScreen...');

                // Asegurarnos de que los controladores estén disponibles
                final employeesController = Get.find<EmployeesController>();

                // Verificar si ServicesController está registrado
                if (!Get.isRegistered<ServicesController>()) {
                  print('ServicesController no encontrado, registrando...');
                  Get.put(
                    ServicesController(getServicesUseCase: Get.find()),
                    permanent: true,
                  );
                }

                // Pre-cargar servicios antes de navegar
                final servicesController = Get.find<ServicesController>();

                // Cargar servicios explícitamente
                if (servicesController.services.isEmpty) {
                  print('Pre-cargando servicios...');
                  await servicesController.loadServices();
                }

                // Navegar a la pantalla
                print('Navegando a CreateEmployeeScreen...');
                Get.to(
                  () => const CreateEmployeeScreen(),
                  transition: Transition.rightToLeft,
                  duration: const Duration(milliseconds: 250),
                );
              } catch (e) {
                print('Error al navegar: $e');
                Get.snackbar(
                  'Error',
                  'No se pudo abrir la pantalla de creación',
                  snackPosition: SnackPosition.TOP,
                );
              }
            },
            backgroundColor: AppColors.cardIndicator,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay profesionales registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Añade tu primer profesional pulsando el botón +',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardIndicator,
              minimumSize: const Size(200, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              try {
                if (!Get.isRegistered<ServicesController>()) {
                  Get.put(
                    ServicesController(getServicesUseCase: Get.find()),
                    permanent: true,
                  );
                }
                Get.to(() => const CreateEmployeeScreen());
              } catch (e) {
                print('Error navegando desde estado vacío: $e');
                Get.snackbar(
                  'Error',
                  'No se pudo abrir la pantalla de creación',
                  snackPosition: SnackPosition.TOP,
                );
              }
            },
            child: const Text(
              'Crear Profesional',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDeletedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restore_from_trash,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay profesionales eliminados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los profesionales eliminados aparecerán aquí',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              minimumSize: const Size(200, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Get.find<EmployeesController>()
                  .switchEmployeeView(showDeleted: false);
            },
            icon: const Icon(Icons.people, color: Colors.white),
            label: const Text(
              'Ver Profesionales Activos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para verificar si un empleado específico es Owner basado en sus roles
  bool _isEmployeeOwner(EmployeeEntity employee) {
    try {
      // Verificar si tiene rol de Owner en la lista de roles
      if (employee.roles.isNotEmpty) {
        return employee.roles.any((role) => role.name == 'Owner');
      }
      return false;
    } catch (e) {
      print('Error al verificar si el empleado es Owner: $e');
      return false;
    }
  }

  Widget _buildEmployeeCard(EmployeeEntity employee, BuildContext context,
      EmployeesController controller) {
    final bool isActive = employee.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // Usar gradiente para un efecto visual más agradable
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              // Color de fondo basado en el estado (verde para activo, rojo tenue para inactivo)
              isActive ? Colors.green[50]! : Colors.red[50]!,
            ],
          ),
          // Borde sutil para reforzar el estado
          border: Border.all(
            color: isActive ? Colors.green[200]! : Colors.red[200]!,
            width: 1.0,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Hero(
            tag: 'avatar_${employee.id}',
            child: CircleAvatar(
              backgroundColor: isActive ? AppColors.cardIndicator : Colors.grey,
              radius: 28,
              child: employee.image != null && employee.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(
                        employee.image!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            employee.name.isNotEmpty
                                ? employee.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      employee.name.isNotEmpty
                          ? employee.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
            ),
          ),
          title: Text(
            employee.fullName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                employee.email,
                style: const TextStyle(fontSize: 14),
              ),
              if (employee.phone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  employee.phone,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: employee.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: employee.statusColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          employee.statusIcon,
                          size: 14,
                          color: employee.statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          employee.displayStatus,
                          style: TextStyle(
                            color: employee.statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (employee.serviceIds != null &&
                      employee.serviceIds!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.spa,
                            size: 14,
                            color: AppColors.cardIndicator,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${employee.serviceIds!.length} servicios',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // 🆕 NUEVO: Indicador para Owners
                  if (_isEmployeeOwner(employee)) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.business_center,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Propietario',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.cardIndicator,
            ),
            onPressed: () => _showOptions(context, employee, controller),
          ),
          onTap: () => _showEmployeeDetails(context, employee),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, EmployeeEntity employee,
      EmployeesController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                // 🆕 LÓGICA PRINCIPAL: Diferentes opciones según el tipo de usuario

                // CASO 1: Empleado eliminado (no Owner)
                if (employee.isDeleted && !_isEmployeeOwner(employee)) ...[
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.restore, color: Colors.white),
                    ),
                    title: const Text('Restaurar'),
                    subtitle: const Text('Volver a activar empleado'),
                    onTap: () {
                      Navigator.pop(context);
                      controller.showRestoreEmployeeDialog(employee);
                    },
                  ),
                  const Divider(height: 0.5),
                  if (employee.deletionReason != null &&
                      employee.deletionReason!.isNotEmpty)
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.info, color: Colors.white),
                      ),
                      title: const Text('Razón de eliminación'),
                      subtitle: Text(
                        employee.deletionReason!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showDeletionReasonDialog(context, employee);
                      },
                    ),
                  if (employee.deletedAt != null) ...[
                    const Divider(height: 0.5),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.access_time, color: Colors.white),
                      ),
                      title: const Text('Fecha de eliminación'),
                      subtitle: Text(
                        '${employee.deletedAt!.day}/${employee.deletedAt!.month}/${employee.deletedAt!.year} a las ${employee.deletedAt!.hour}:${employee.deletedAt!.minute.toString().padLeft(2, '0')}',
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ]

                // CASO 2: Owner activo - Solo ver detalles
                else if (_isEmployeeOwner(employee) && !employee.isDeleted) ...[
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.visibility, color: Colors.white),
                    ),
                    title: const Text('Ver mi perfil'),
                    subtitle: const Text('Ver información del propietario'),
                    onTap: () {
                      Navigator.pop(context);
                      _showEmployeeDetails(context, employee);
                    },
                  ),
                  const Divider(height: 0.5),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.business_center, color: Colors.white),
                    ),
                    title: const Text('Perfil de Propietario'),
                    subtitle: const Text(
                        'Tu cuenta tiene privilegios de administrador'),
                    enabled: false,
                    titleTextStyle: TextStyle(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w500,
                    ),
                    subtitleTextStyle: TextStyle(
                      color: Colors.amber[600],
                      fontSize: 12,
                    ),
                  ),
                  const Divider(height: 0.5),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.info_outline, color: Colors.white),
                    ),
                    title: const Text('Información'),
                    subtitle: const Text(
                        'Los propietarios se gestionan desde Ajustes'),
                    onTap: () {
                      Navigator.pop(context);
                      Get.dialog(
                        AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 10),
                              Text(
                                'Gestión de Propietario',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Como propietario del negocio, tu perfil tiene características especiales:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.security,
                                      size: 16, color: Colors.green),
                                  SizedBox(width: 8),
                                  Expanded(
                                      child: Text('No puede ser eliminado',
                                          style: TextStyle(fontSize: 14))),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.admin_panel_settings,
                                      size: 16, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Expanded(
                                      child: Text('Acceso completo al sistema',
                                          style: TextStyle(fontSize: 14))),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.settings,
                                      size: 16, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Expanded(
                                      child: Text('Configuración desde Ajustes',
                                          style: TextStyle(fontSize: 14))),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Para modificar tu información personal, ve a la sección de Ajustes en el menú principal.',
                                style:
                                    TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get
                                  .back(), // 🔧 CAMBIO: Usar Get.back() en lugar de Navigator.of(context).pop()
                              child: const Text('Entendido'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ]

                // CASO 3: Owner eliminado (caso especial, no debería pasar pero por seguridad)
                else if (_isEmployeeOwner(employee) && employee.isDeleted) ...[
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.error_outline, color: Colors.white),
                    ),
                    title: const Text('Error del Sistema'),
                    subtitle:
                        const Text('Un propietario no debería estar eliminado'),
                    enabled: false,
                  ),
                  const Divider(height: 0.5),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.support_agent, color: Colors.white),
                    ),
                    title: const Text('Contactar Soporte'),
                    subtitle:
                        const Text('Este es un error que debe ser reportado'),
                    onTap: () {
                      Navigator.pop(context);
                      Get.dialog(
                        AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Error del Sistema'),
                            ],
                          ),
                          content: const Text(
                            'Se ha detectado una inconsistencia en los datos. Un propietario no debería aparecer como eliminado. Por favor, contacta al soporte técnico.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ]

                // CASO 4: Empleado normal activo - Todas las opciones de gestión
                else ...[
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.visibility, color: Colors.white),
                    ),
                    title: const Text('Ver detalles'),
                    subtitle: const Text('Ver información completa'),
                    onTap: () {
                      Navigator.pop(context);
                      _showEmployeeDetails(context, employee);
                    },
                  ),
                  const Divider(height: 0.5),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.edit, color: Colors.white),
                    ),
                    title: const Text('Editar'),
                    subtitle: const Text('Modificar información'),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToEditScreen(employee.id);
                    },
                  ),
                  const Divider(height: 0.5),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          employee.isActive ? Colors.orange : Colors.green,
                      child: Icon(
                        employee.isActive ? Icons.person_off : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      employee.isActive ? 'Desactivar' : 'Activar',
                      style: TextStyle(
                        color: employee.isActive ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      employee.isActive
                          ? 'El profesional no estará disponible'
                          : 'El profesional estará disponible',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handleStatusToggle(context, employee, controller);
                    },
                  ),
                  const Divider(height: 0.5),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.delete_forever, color: Colors.white),
                    ),
                    title: const Text('Eliminar'),
                    subtitle: const Text('Eliminar profesional (soft delete)'),
                    onTap: () {
                      Navigator.pop(context);
                      controller.showDeleteEmployeeDialog(employee);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeletionReasonDialog(
      BuildContext context, EmployeeEntity employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 10),
              Text('Razón de Eliminación'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Empleado: ${employee.fullName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (employee.deletedAt != null)
                Text(
                  'Eliminado el: ${employee.deletedAt!.day}/${employee.deletedAt!.month}/${employee.deletedAt!.year}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              const SizedBox(height: 16),
              const Text(
                'Razón:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  employee.deletionReason ?? 'Sin razón especificada',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _handleStatusToggle(BuildContext context, EmployeeEntity employee,
      EmployeesController controller) {
    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ToggleStatusDialog(
        employee: employee,
        onConfirm: (newStatus) async {
          // Hacemos el callback onConfirm asíncrono
          // Cerrar el diálogo primero
          Navigator.pop(dialogContext);

          // 🆕 NUEVO: Lógica simplificada sin navegación
          await _performStatusToggle(
              controller, employee, newStatus); // Esperamos la ejecución
        },
      ),
    );
  }

  // Cambiamos el tipo de retorno de void a Future<void> y usamos async/await
  Future<void> _performStatusToggle(EmployeesController controller,
      EmployeeEntity employee, bool newStatus) async {
    // Mostrar SnackBar de progreso
    Get.snackbar(
      newStatus ? 'Activando...' : 'Desactivando...',
      'Procesando cambio de estado',
      snackPosition: SnackPosition.TOP,
      backgroundColor: newStatus
          ? Colors.green.withOpacity(0.8)
          : Colors.orange.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      showProgressIndicator: true,
      progressIndicatorBackgroundColor: Colors.white,
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
      icon: Icon(
        newStatus ? Icons.check_circle_outline : Icons.person_off_outlined,
        color: Colors.white,
      ),
    );

    try {
      // Llamar al método del controlador y esperar su resultado
      final success =
          await controller.toggleEmployeeStatus(employee.id, newStatus);

      // Cerrar el SnackBar de progreso
      Get.closeAllSnackbars();

      if (success) {
        // 🎯 CLAVE: Actualizar el empleado en la lista local directamente
        final employeeIndex =
            controller.employees.indexWhere((e) => e.id == employee.id);
        if (employeeIndex >= 0) {
          // Crear una copia actualizada del empleado
          final updatedEmployee = employee is EmployeeModel
              ? (employee as EmployeeModel).copyWith(isActive: newStatus)
              : employee; // Si no es EmployeeModel, usar el original

          // Actualizar en la lista
          controller.employees[employeeIndex] = updatedEmployee;

          // Actualizar listas filtradas y forzar la actualización de la UI
          controller.filterEmployees();
          controller.update(); // Forzar la actualización de GetBuilder
        }

        // Mostrar notificación de éxito
        Get.snackbar(
          newStatus ? 'Profesional Activado' : 'Profesional Desactivado',
          newStatus
              ? 'El profesional ha sido activado correctamente'
              : 'El profesional ha sido desactivado correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: newStatus
              ? Colors.green.withOpacity(0.8)
              : Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(10),
          borderRadius: 10,
          icon: Icon(
            newStatus ? Icons.check_circle : Icons.person_off,
            color: Colors.white,
          ),
        );
      } else {
        // Mostrar error si algo salió mal
        Get.snackbar(
          'Error',
          'No se pudo cambiar el estado del profesional',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(10),
          borderRadius: 10,
          icon: const Icon(Icons.error_outline, color: Colors.white),
        );
      }
    } catch (error) {
      // Cerrar el SnackBar de progreso
      Get.closeAllSnackbars();

      // Mostrar notificación de error
      Get.snackbar(
        'Error',
        'No se pudo ${newStatus ? "activar" : "desactivar"} al profesional: ${error.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    }
  }

  void _navigateToEditScreen(String employeeId) {
    // Usar navegación directa, no rutas nombradas
    Get.to(
      () => EditEmployeeScreen(employeeId: employeeId),
      transition: Transition.rightToLeft,
    );
  }

  void _showEmployeeDetails(BuildContext context, EmployeeEntity employee) {
    // Usar navegación directa, no rutas nombradas
    Get.to(
      () => EmployeeDetailsScreen(employee: employee),
      transition: Transition.rightToLeft,
    );
  }

  void _showDeleteConfirmation(BuildContext context, EmployeeEntity employee,
      EmployeesController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Eliminar Profesional'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  children: [
                    const TextSpan(
                        text: '¿Estás seguro que deseas eliminar a '),
                    TextSpan(
                      text: employee.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  await controller.deleteEmployee(employee.id);
                } catch (e) {
                  // El snackbar ya se muestra en el controller
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
