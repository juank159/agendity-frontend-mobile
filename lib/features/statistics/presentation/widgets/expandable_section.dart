import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExpandableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final RxBool isExpanded;
  final VoidCallback onToggle;

  const ExpandableSection({
    Key? key,
    required this.title,
    required this.icon,
    required this.child,
    required this.isExpanded,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Encabezado que actúa como toggle
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                Icon(icon, size: 24, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Obx(() => Icon(
                      isExpanded.value
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    )),
              ],
            ),
          ),
        ),

        // Contenido expandible
        Obx(() => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isExpanded.value ? null : 0,
              curve: Curves.easeInOut,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: isExpanded.value ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: child,
                  ),
                ),
              ),
            )),
      ],
    );
  }
}
