// import 'package:flutter/material.dart';

// class InputGlobalForm extends StatelessWidget {
//   final TextEditingController controller;
//   final String text;
//   final TextInputType textInputType;
//   final bool obscureText;

//   const InputGlobalForm(
//       {super.key,
//       required this.controller,
//       required this.text,
//       required this.textInputType,
//       required this.obscureText});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         height: 50,
//         padding: const EdgeInsets.only(top: 3, left: 15),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(6),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 7,
//             ),
//           ],
//         ),
//         child: TextFormField(
//           controller: controller,
//           keyboardType: textInputType,
//           obscureText: obscureText,
//           decoration: InputDecoration(
//             hintText: text,
//             border: InputBorder.none,
//             contentPadding: const EdgeInsets.all(0),
//             hintStyle: const TextStyle(height: 1),
//           ),
//         ));
//   }
// }

// lib/features/auth/presentation/widgets/input_global_form.dart
import 'package:flutter/material.dart';

class InputGlobalForm extends StatelessWidget {
  final TextEditingController controller;
  final String text;
  final TextInputType textInputType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final String? errorText;

  const InputGlobalForm({
    super.key,
    required this.controller,
    required this.text,
    required this.textInputType,
    required this.obscureText,
    this.validator,
    this.suffixIcon,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 55,
          padding: const EdgeInsets.only(top: 3, left: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: textInputType,
            obscureText: obscureText,
            validator: validator,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: text,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              suffixIcon: suffixIcon,
              errorStyle: const TextStyle(height: 0),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
