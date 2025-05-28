// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/services/domain/entities/category.dart';

// class CategoryPicker extends StatelessWidget {
//   final List<CategoryEntity> categories;
//   final Rxn<CategoryEntity> selectedCategory;
//   final Function(CategoryEntity) onChanged;

//   const CategoryPicker({
//     required this.categories,
//     required this.selectedCategory,
//     required this.onChanged,
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(28),
//       ),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'Categoría',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               height: 250,
//               child: Obx(() => ListWheelScrollView.useDelegate(
//                     itemExtent: 50,
//                     perspective: 0.006,
//                     diameterRatio: 1.6,
//                     physics: const FixedExtentScrollPhysics(),
//                     onSelectedItemChanged: (index) {
//                       onChanged(categories[index]);
//                     },
//                     controller: FixedExtentScrollController(
//                       initialItem: selectedCategory.value != null
//                           ? categories.indexOf(selectedCategory.value!)
//                           : 0,
//                     ),
//                     childDelegate: ListWheelChildBuilderDelegate(
//                       childCount: categories.length,
//                       builder: (context, index) {
//                         final category = categories[index];
//                         final isSelected =
//                             selectedCategory.value?.id == category.id;
//                         return Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           decoration: BoxDecoration(
//                             color: isSelected
//                                 ? Colors.grey.shade200
//                                 : Colors.transparent,
//                           ),
//                           child: Center(
//                             child: Text(
//                               category.name,
//                               style: TextStyle(
//                                 fontSize: isSelected ? 22 : 16,
//                                 fontWeight: isSelected
//                                     ? FontWeight.bold
//                                     : FontWeight.normal,
//                                 color: isSelected
//                                     ? Colors.black
//                                     : Colors.grey[500],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   )),
//             ),
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed: () => Get.back(),
//                     child: const Text(
//                       'CANCELAR',
//                       style: TextStyle(
//                         color: Colors.deepPurple,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   TextButton(
//                     onPressed: () => Get.back(),
//                     child: const Text(
//                       'ACEPTAR',
//                       style: TextStyle(
//                         color: Colors.deepPurple,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';

class CategoryPicker extends StatelessWidget {
  final List<CategoryEntity> categories;
  final Rxn<CategoryEntity> selectedCategory;
  final Function(CategoryEntity) onChanged;

  const CategoryPicker({
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.category_outlined,
                  size: 24,
                  color: Colors.grey,
                ),
                const SizedBox(width: 12),
                const Text(
                  "Seleccionar Categoría",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Category Picker
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                // Selector highlight (fixed bar, doesn't move)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      height: 50,
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),

                // Scrollable list of categories
                Obx(() => ListWheelScrollView.useDelegate(
                      itemExtent: 50,
                      perspective: 0.006,
                      diameterRatio: 1.6,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        onChanged(categories[index]);
                      },
                      controller: FixedExtentScrollController(
                        initialItem: selectedCategory.value != null
                            ? categories.indexOf(selectedCategory.value!)
                            : 0,
                      ),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: categories.length,
                        builder: (context, index) {
                          final category = categories[index];
                          final isSelected =
                              selectedCategory.value?.id == category.id;
                          return Center(
                            child: Text(
                              category.name,
                              style: TextStyle(
                                fontSize: isSelected ? 20 : 18,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade600,
                              ),
                            ),
                          );
                        },
                      ),
                    )),
              ],
            ),
          ),

          // Buttons
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel button
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.grey.shade700,
                    ),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                // Confirm button
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'ACEPTAR',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
