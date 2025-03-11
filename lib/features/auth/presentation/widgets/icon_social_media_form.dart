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

// lib/features/auth/presentation/widgets/icon_social_media_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class IconSocialMediaForm extends StatelessWidget {
  final String path;
  final VoidCallback? onTap;
  final bool isLoading;

  const IconSocialMediaForm({
    super.key,
    required this.path,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : SvgPicture.asset(
                  path,
                  height: 20,
                ),
        ),
      ),
    );
  }
}
