// lib/features/services/presentation/widgets/category_picker.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';

class CategoryPicker extends StatefulWidget {
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
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  CategoryEntity? tempSelectedCategory;

  @override
  void initState() {
    super.initState();
    // Inicializar con la categoría actualmente seleccionada
    tempSelectedCategory = widget.selectedCategory.value;
    
    // Si hay categorías disponibles y no hay selección, seleccionar la primera
    if (widget.categories.isNotEmpty && tempSelectedCategory == null) {
      tempSelectedCategory = widget.categories.first;
    }
  }

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
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 24,
                  color: Colors.grey,
                ),
                SizedBox(width: 12),
                Text(
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
            child: widget.categories.length == 1
                ? _buildSingleCategoryView()
                : _buildMultipleCategoryView(),
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
                    onPressed: () {
                      if (tempSelectedCategory != null) {
                        widget.onChanged(tempSelectedCategory!);
                      }
                      Get.back();
                    },
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

  Widget _buildSingleCategoryView() {
    final category = widget.categories.first;
    // Asegurar que la única categoría está seleccionada
    if (tempSelectedCategory == null) {
      tempSelectedCategory = category;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          category.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.check_circle,
          color: Colors.blue.shade600,
          size: 28,
        ),
        onTap: () {
          setState(() {
            tempSelectedCategory = category;
          });
        },
      ),
    );
  }

  Widget _buildMultipleCategoryView() {
    return Stack(
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
        ListWheelScrollView.useDelegate(
          itemExtent: 50,
          perspective: 0.006,
          diameterRatio: 1.6,
          physics: const FixedExtentScrollPhysics(),
          controller: FixedExtentScrollController(
            initialItem: tempSelectedCategory != null
                ? widget.categories.indexOf(tempSelectedCategory!)
                : 0,
          ),
          onSelectedItemChanged: (index) {
            setState(() {
              tempSelectedCategory = widget.categories[index];
            });
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.categories.length,
            builder: (context, index) {
              final category = widget.categories[index];
              final isSelected = tempSelectedCategory?.id == category.id;
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
        ),
      ],
    );
  }
}
