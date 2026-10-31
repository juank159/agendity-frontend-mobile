import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  /// `--dart-define=API_URL=…` (pruebas contra otro backend sin tocar
  /// `.env`); vacío = el de `.env`.
  static const _definedApiUrl = String.fromEnvironment('API_URL');

  static String get apiUrl {
    if (_definedApiUrl.isNotEmpty) return _definedApiUrl;
    final url = dotenv.env['API_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('API_URL not found in environment variables');
    }
    return url;
  }

  static String get apiVersion {
    return dotenv.env['API_VERSION'] ?? 'v1';
  }

  static Duration get connectionTimeout {
    final timeout = dotenv.env['CONNECTION_TIMEOUT'];
    return Duration(seconds: int.parse(timeout ?? '5'));
  }

  static Duration get receiveTimeout {
    final timeout = dotenv.env['RECEIVE_TIMEOUT'];
    return Duration(seconds: int.parse(timeout ?? '3'));
  }

  static void validateEnv() {
    final requiredVars = ['API_URL'];
    final missingVars = requiredVars
        .where((var_) => dotenv.env[var_] == null || dotenv.env[var_]!.isEmpty)
        .toList();

    if (missingVars.isNotEmpty) {
      throw Exception(
          'Missing required environment variables: ${missingVars.join(', ')}');
    }
  }
}
