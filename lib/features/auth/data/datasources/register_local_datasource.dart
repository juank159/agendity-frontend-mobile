import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class RegisterLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
}

class RegisterLocalDataSourceImpl implements RegisterLocalDataSource {
  final FlutterSecureStorage storage;
  static const String TOKEN_KEY = 'REGISTER_TOKEN';

  RegisterLocalDataSourceImpl({required this.storage});

  @override
  Future<void> saveToken(String token) async {
    await storage.write(key: TOKEN_KEY, value: token);
  }

  @override
  Future<String?> getToken() async {
    return await storage.read(key: TOKEN_KEY);
  }
}
