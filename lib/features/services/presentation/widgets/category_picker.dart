import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';

class CategoryPicker extends StatelessWidget {
  final List<Category> categories;
  final Rxn<Category> selectedCategory;
  final Function(Category) onChanged;

  const CategoryPicker({
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Categoría',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Obx(() => ListWheelScrollView.useDelegate(
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
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.grey.shade200
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              category.name,
                              style: TextStyle(
                                fontSize: isSelected ? 22 : 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'ACEPTAR',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
