import 'package:get/get.dart';
import '../../../features/auth/presentation/controllers/user_info_controller.dart';

class UserModule {
  static Future<void> init() async {
    try {
      Get.put<UserInfoController>(
        UserInfoController(),
        permanent: true,
      );
    } catch (e) {
      print('Error initializing UserModule: $e');
      rethrow;
    }
  }
}
