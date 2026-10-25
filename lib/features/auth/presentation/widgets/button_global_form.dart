// import 'package:flutter/material.dart';
// import 'package:get/route_manager.dart';
// import 'package:login_signup/core/routes/routes.dart';
// import 'package:login_signup/utils/global_colors.dart';

// class ButtonGlobalForm extends StatelessWidget {
//   final String textButton;
//   final VoidCallback? onPressed;
//   const ButtonGlobalForm({super.key, required this.textButton, this.onPressed});

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () {
//         onPressed;
//         //Get.toNamed(GetRoutes.home);
//       },
//       child: Container(
//         alignment: Alignment.center,
//         height: 55,
//         decoration: BoxDecoration(
//           color: GlobalColors.mainColor,
//           borderRadius: BorderRadius.circular(6),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//             ),
//           ],
//         ),
//         child: Text(
//           textButton,
//           style: const TextStyle(
//               color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:login_signup/utils/global_colors.dart';

class ButtonGlobalForm extends StatelessWidget {
  final String textButton;
  final VoidCallback? onPressed; // Función personalizada para el botón

  const ButtonGlobalForm({
    super.key,
    required this.textButton,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed, // Llama a la función personalizada si está definida
      child: Container(
        alignment: Alignment.center,
        height: 55,
        decoration: BoxDecoration(
          color: GlobalColors.mainColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Text(
          textButton,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
