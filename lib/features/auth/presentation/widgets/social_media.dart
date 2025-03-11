// import 'package:flutter/material.dart';
// import 'package:login_signup/features/auth/presentation/widgets/icon_social_media_form.dart';
// import 'package:login_signup/utils/global_colors.dart';

// class SocialMedia extends StatelessWidget {
//   final String text;
//   const SocialMedia({super.key, required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           alignment: Alignment.center,
//           child: Text(
//             text,
//             style: TextStyle(
//                 color: GlobalColors.textColor,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600),
//           ),
//         ),
//         const SizedBox(
//           height: 15,
//         ),
//         SizedBox(
//           width: MediaQuery.of(context).size.width * 0.8,
//           child: const Row(
//             children: [
//               IconSocialMediaForm(
//                 path: 'assets/images/google.svg',
//               ),
//               SizedBox(
//                 width: 10,
//               ),
//               IconSocialMediaForm(
//                 path: 'assets/images/facebook.svg',
//               ),
//               SizedBox(
//                 width: 10,
//               ),
//               IconSocialMediaForm(
//                 path: 'assets/images/apple.svg',
//               ),
//             ],
//           ),
//         )
//       ],
//     );
//   }
// }

// lib/features/auth/presentation/widgets/social_media.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/google_auth_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/icon_social_media_form.dart';
import 'package:login_signup/utils/global_colors.dart';

class SocialMedia extends StatelessWidget {
  final String text;
  const SocialMedia({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    // Obtener el controlador de autenticación de Google
    final GoogleAuthController googleAuthController =
        Get.find<GoogleAuthController>();

    return Column(
      children: [
        Container(
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
                color: GlobalColors.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Obx(() => Row(
                children: [
                  // Google sign in
                  IconSocialMediaForm(
                    path: 'assets/images/google.svg',
                    onTap: googleAuthController.signInWithGoogle,
                    isLoading: googleAuthController.isLoading.value,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  // Facebook (sin implementar aún)
                  const IconSocialMediaForm(
                    path: 'assets/images/facebook.svg',
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  // Apple (sin implementar aún)
                  const IconSocialMediaForm(
                    path: 'assets/images/apple.svg',
                  ),
                ],
              )),
        )
      ],
    );
  }
}
