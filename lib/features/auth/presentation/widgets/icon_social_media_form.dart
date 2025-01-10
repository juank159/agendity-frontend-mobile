import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class IconSocialMediaForm extends StatelessWidget {
  final String path;
  const IconSocialMediaForm({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
        child: SvgPicture.asset(
          path,
          height: 20,
        ),
      ),
    );
  }
}
