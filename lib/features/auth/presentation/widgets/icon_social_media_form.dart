// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';

// class IconSocialMediaForm extends StatelessWidget {
//   final String path;
//   const IconSocialMediaForm({super.key, required this.path});

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Container(
//         alignment: Alignment.center,
//         height: 55,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(6),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//             ),
//           ],
//         ),
//         child: SvgPicture.asset(
//           path,
//           height: 20,
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class IconSocialMediaForm extends StatelessWidget {
  final String path;
  final VoidCallback? onTap;
  final bool isLoading;
  final String? label;

  const IconSocialMediaForm({
    super.key,
    required this.path,
    this.onTap,
    this.isLoading = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          height: 55,
          // decoration: BoxDecoration(
          //   color: Colors.white,
          //   borderRadius: BorderRadius.circular(12),
          //   border: Border.all(
          //     color: Colors.grey[200]!,
          //     width: 1,
          //   ),
          //   boxShadow: [
          //     BoxShadow(
          //       color: Colors.black.withOpacity(0.05),
          //       blurRadius: 8,
          //       offset: const Offset(0, 2),
          //     ),
          //   ],
          // ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      path,
                      height: 24,
                      width: 24,
                    ),
                    if (label != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        label!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
