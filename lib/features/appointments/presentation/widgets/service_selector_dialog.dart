// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../controllers/appointments_controller.dart';

// class ServiceSelectorDialog extends StatelessWidget {
//   final AppointmentsController controller;

//   const ServiceSelectorDialog({
//     Key? key,
//     required this.controller,
//   }) : super(key: key);

//   static Future<List<String>?> show(
//     BuildContext context,
//     AppointmentsController controller,
//   ) async {
//     // Guarda los IDs seleccionados originalmente para restaurarlos si el usuario cancela
//     final originalSelectedIds = [...controller.selectedServiceIds];

//     final result = await showDialog<bool>(
//       context: context,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Container(
//           width: MediaQuery.of(context).size.width * 0.9,
//           height: MediaQuery.of(context).size.height * 0.7,
//           padding: const EdgeInsets.all(16),
//           child: ServiceSelectorDialog(controller: controller),
//         ),
//       ),
//     );

//     // Si el usuario canceló, restaura la selección original
//     if (result != true) {
//       controller.selectedServiceIds.clear();
//       controller.selectedServiceIds.addAll(originalSelectedIds);
//       controller.updateTotalPrice();
//       return null;
//     }

//     // Retorna los IDs seleccionados
//     return controller.selectedServiceIds.toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final searchController = TextEditingController();
//     final searchQuery = ''.obs;

//     return Column(
//       children: [
//         Text(
//           'Seleccionar Servicios',
//           style: TextStyle(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             color: Theme.of(context).primaryColor,
//           ),
//         ),
//         const SizedBox(height: 20),

//         // Barra de búsqueda
//         TextField(
//           controller: searchController,
//           decoration: InputDecoration(
//             labelText: 'Buscar Servicios',
//             prefixIcon: const Icon(Icons.search),
//             suffixIcon: IconButton(
//               icon: const Icon(Icons.clear),
//               onPressed: () {
//                 searchController.clear();
//                 searchQuery.value = '';
//               },
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(30),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(30),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(30),
//               borderSide: BorderSide(color: Theme.of(context).primaryColor),
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: const EdgeInsets.symmetric(horizontal: 20),
//           ),
//           onChanged: (value) => searchQuery.value = value,
//         ),

//         const SizedBox(height: 16),

//         // Lista de servicios
//         Expanded(
//           child: Obx(() {
//             final filteredServices = controller.services.where((service) {
//               final name = service['name'].toString().toLowerCase();
//               return name.contains(searchQuery.value.toLowerCase());
//             }).toList();

//             if (filteredServices.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
//                     const SizedBox(height: 16),
//                     Text(
//                       'No se encontraron servicios',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return ListView.separated(
//               itemCount: filteredServices.length,
//               separatorBuilder: (context, index) => Divider(height: 1),
//               itemBuilder: (context, index) {
//                 final service = filteredServices[index];
//                 final serviceId = service['id'].toString();
//                 final price = double.parse(service['price'].toString());
//                 final formattedPrice = NumberFormat.currency(
//                   locale: 'es',
//                   symbol: '\$',
//                   decimalDigits: 0,
//                 ).format(price);

//                 return Obx(() {
//                   final isSelected =
//                       controller.selectedServiceIds.contains(serviceId);

//                   return Material(
//                     color: isSelected
//                         ? Theme.of(context).primaryColor.withOpacity(0.08)
//                         : Colors.transparent,
//                     child: InkWell(
//                       onTap: () => controller.toggleServiceSelection(serviceId),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(
//                             vertical: 8, horizontal: 4),
//                         child: Row(
//                           children: [
//                             // Checkbox personalizado
//                             Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Container(
//                                 width: 24,
//                                 height: 24,
//                                 decoration: BoxDecoration(
//                                   color: isSelected
//                                       ? Theme.of(context).primaryColor
//                                       : Colors.white,
//                                   borderRadius: BorderRadius.circular(6),
//                                   border: Border.all(
//                                     color: isSelected
//                                         ? Theme.of(context).primaryColor
//                                         : Colors.grey[400]!,
//                                     width: 2,
//                                   ),
//                                   boxShadow: isSelected
//                                       ? [
//                                           BoxShadow(
//                                             color: Theme.of(context)
//                                                 .primaryColor
//                                                 .withOpacity(0.3),
//                                             blurRadius: 4,
//                                             offset: const Offset(0, 2),
//                                           )
//                                         ]
//                                       : null,
//                                 ),
//                                 child: isSelected
//                                     ? const Icon(Icons.check,
//                                         size: 16, color: Colors.white)
//                                     : null,
//                               ),
//                             ),

//                             // Información del servicio
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     service['name'].toString(),
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: isSelected
//                                           ? FontWeight.bold
//                                           : FontWeight.w500,
//                                       color: isSelected
//                                           ? Theme.of(context).primaryColor
//                                           : Colors.black87,
//                                     ),
//                                   ),
//                                   if (service['description'] != null &&
//                                       service['description']
//                                           .toString()
//                                           .isNotEmpty)
//                                     Padding(
//                                       padding: const EdgeInsets.only(top: 4),
//                                       child: Text(
//                                         service['description'].toString(),
//                                         style: TextStyle(
//                                           fontSize: 12,
//                                           color: Colors.grey[600],
//                                         ),
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                             ),

//                             // Precio
//                             Padding(
//                               padding: const EdgeInsets.only(right: 8),
//                               child: Text(
//                                 formattedPrice,
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: isSelected
//                                       ? Theme.of(context).primaryColor
//                                       : Colors.black87,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 });
//               },
//             );
//           }),
//         ),

//         // Total y botones
//         Container(
//           padding: const EdgeInsets.only(top: 16),
//           decoration: BoxDecoration(
//             border: Border(
//               top: BorderSide(color: Colors.grey[300]!),
//             ),
//           ),
//           child: Column(
//             children: [
//               // Total
//               Obx(() => AnimatedContainer(
//                     duration: const Duration(milliseconds: 300),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 12),
//                     decoration: BoxDecoration(
//                       color: controller.totalPrice.value > 0
//                           ? Theme.of(context).primaryColor.withOpacity(0.1)
//                           : Colors.transparent,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Total:',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: controller.totalPrice.value > 0
//                                 ? Theme.of(context).primaryColor
//                                 : Colors.grey[800],
//                           ),
//                         ),
//                         Text(
//                           NumberFormat.currency(
//                             locale: 'es',
//                             symbol: '\$',
//                             decimalDigits: 0,
//                           ).format(controller.totalPrice.value),
//                           style: TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                             color: controller.totalPrice.value > 0
//                                 ? Theme.of(context).primaryColor
//                                 : Colors.grey[800],
//                           ),
//                         ),
//                       ],
//                     ),
//                   )),

//               const SizedBox(height: 16),

//               // Botones
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context, false),
//                     style: TextButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 24, vertical: 12),
//                       foregroundColor: Colors.grey[700],
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text(
//                       'Cancelar',
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: () => Navigator.pop(context, true),
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 36, vertical: 12),
//                       backgroundColor: Theme.of(context).primaryColor,
//                       foregroundColor: Colors.white,
//                       elevation: 2,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text(
//                       'Confirmar',
//                       style:
//                           TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/appointments_controller.dart';

class ServiceSelectorDialog extends StatelessWidget {
  final AppointmentsController controller;

  const ServiceSelectorDialog({
    Key? key,
    required this.controller,
  }) : super(key: key);

  static Future<List<String>?> show(
    BuildContext context,
    AppointmentsController controller,
  ) async {
    // Guarda los IDs seleccionados originalmente para restaurarlos si el usuario cancela
    final originalSelectedIds = [...controller.selectedServiceIds];

    // Adaptar el tamaño según la plataforma y orientación
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width * 0.9;
    final maxHeight = size.height * 0.7;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: maxWidth,
          height: maxHeight,
          padding: const EdgeInsets.all(16),
          child: ServiceSelectorDialog(controller: controller),
        ),
      ),
    );

    // Si el usuario canceló, restaura la selección original
    if (result != true) {
      controller.selectedServiceIds.clear();
      controller.selectedServiceIds.addAll(originalSelectedIds);
      controller.updateTotalPrice();
      return null;
    }

    // Retorna los IDs seleccionados
    return controller.selectedServiceIds.toList();
  }

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    final searchQuery = ''.obs;

    // Personalizar el formato para mostrar el símbolo de peso a la izquierda
    final currencyFormat = NumberFormat.currency(
      locale: 'es',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Column(
      children: [
        Text(
          'Seleccionar Servicios',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 20),

        // Barra de búsqueda
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: 'Buscar Servicios',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                searchController.clear();
                searchQuery.value = '';
              },
            ),
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
          onChanged: (value) => searchQuery.value = value,
        ),

        const SizedBox(height: 16),

        // Lista de servicios
        Expanded(
          child: Obx(() {
            final filteredServices = controller.services.where((service) {
              final name = service['name'].toString().toLowerCase();
              return name.contains(searchQuery.value.toLowerCase());
            }).toList();

            if (filteredServices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No se encontraron servicios',
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
              itemCount: filteredServices.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final service = filteredServices[index];
                final serviceId = service['id'].toString();
                final price = double.parse(service['price'].toString());

                // Formatear precio con el símbolo a la izquierda
                final formattedPrice = currencyFormat.format(price);

                return Obx(() {
                  final isSelected =
                      controller.selectedServiceIds.contains(serviceId);

                  // Define el color de fondo basado en la selección
                  // Alternando colores para una visualización más agradable
                  final backgroundColor = isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : (index % 2 == 0 ? Colors.grey[50] : Colors.white);

                  return Material(
                    color: backgroundColor,
                    child: InkWell(
                      onTap: () => controller.toggleServiceSelection(serviceId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Checkbox personalizado
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),

                            // Información del servicio - dar más espacio
                            Expanded(
                              flex: 3, // Dar más espacio al nombre del servicio
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service['name'].toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.black87,
                                    ),
                                    // Permitir hasta 2 líneas para nombres largos
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (service['description'] != null &&
                                      service['description']
                                          .toString()
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        service['description'].toString(),
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

                            // Espacio entre nombre y precio
                            const SizedBox(width: 8),

                            // Precio (con símbolo $ a la izquierda)
                            Text(
                              formattedPrice,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                });
              },
            );
          }),
        ),

        // Total y botones
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Column(
            children: [
              // Total
              Obx(() => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: controller.totalPrice.value > 0
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: controller.totalPrice.value > 0
                                ? Theme.of(context).primaryColor
                                : Colors.grey[800],
                          ),
                        ),
                        Text(
                          currencyFormat.format(controller.totalPrice.value),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: controller.totalPrice.value > 0
                                ? Theme.of(context).primaryColor
                                : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 16),

              // Botones - modificados para adaptarse a diferentes tamaños
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 300) {
                    // Para pantallas muy pequeñas, usar column
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Confirmar',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Para pantallas más grandes, usar row con expanded
                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Confirmar',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
