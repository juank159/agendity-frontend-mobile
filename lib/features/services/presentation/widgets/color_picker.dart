// import 'package:flutter/material.dart';
// import '../../../../core/constants/app_colors.dart';

// class ColorPicker extends StatelessWidget {
//   final Color selectedColor;
//   final ValueChanged<Color> onColorSelected;

//   const ColorPicker({
//     required this.selectedColor,
//     required this.onColorSelected,
//     super.key,
//   });

//   static const List<Color> _colors = [
//     AppColors.primary,
//     Colors.red,
//     Colors.pink,
//     Colors.purple,
//     Colors.indigo,
//     Colors.blue,
//     Colors.teal,
//     Colors.green,
//     Colors.orange,
//     Colors.brown,
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Wrap(
//         spacing: 16,
//         runSpacing: 16,
//         children: _colors
//             .map((color) => _ColorDot(
//                   color: color,
//                   isSelected: color == selectedColor,
//                   onTap: () => onColorSelected(color),
//                 ))
//             .toList(),
//       ),
//     );
//   }
// }

// class _ColorDot extends StatelessWidget {
//   final Color color;
//   final bool isSelected;
//   final VoidCallback onTap;

//   const _ColorDot({
//     required this.color,
//     required this.isSelected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 40,
//         height: 40,
//         decoration: BoxDecoration(
//           color: color,
//           shape: BoxShape.circle,
//           border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
//           boxShadow: [
//             if (isSelected)
//               BoxShadow(
//                 color: color.withOpacity(0.4),
//                 blurRadius: 8,
//                 spreadRadius: 2,
//               ),
//           ],
//         ),
//         child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
//       ),
//     );
//   }
// }
