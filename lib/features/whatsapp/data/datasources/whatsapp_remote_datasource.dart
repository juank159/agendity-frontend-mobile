// lib/features/whatsapp/data/datasources/whatsapp_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:login_signup/core/errors/exceptions.dart';
import '../models/whatsapp_config_model.dart';
import '../../../../shared/local_storage/local_storage.dart';

abstract class WhatsappRemoteDataSource {
  Future<WhatsappConfigModel> getConfig();
  Future<WhatsappConfigModel> saveConfig(WhatsappConfigModel config);
  Future<bool> sendTestMessage();
  Future<bool> sendMessage(String phoneNumber, String message);
}

class WhatsappRemoteDataSourceImpl implements WhatsappRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;

  WhatsappRemoteDataSourceImpl({
    required this.dio,
    required this.localStorage,
  });

  @override
  Future<WhatsappConfigModel> getConfig() async {
    try {
      final token = await localStorage.getToken();
      final response = await dio.get(
        '/whatsapp/config',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return WhatsappConfigModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to load WhatsApp configuration',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Si no hay configuración, devolvemos una vacía
        throw NotFoundException('WhatsApp configuration not found');
      }
      throw ServerException(
        message: e.message ?? 'An error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<WhatsappConfigModel> saveConfig(WhatsappConfigModel config) async {
    try {
      final token = await localStorage.getToken();
      final response = await dio.post(
        '/whatsapp/config',
        data: config.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return WhatsappConfigModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to save WhatsApp configuration',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'An error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> sendTestMessage() async {
    try {
      final token = await localStorage.getToken();
      final response = await dio.post(
        '/whatsapp/test',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return data['success'] == true;
      } else {
        throw ServerException(
          message: 'Failed to send test message',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'An error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> sendMessage(String phoneNumber, String message) async {
    try {
      final token = await localStorage.getToken();
      final response = await dio.post(
        '/whatsapp/send',
        data: {
          'phoneNumber': phoneNumber,
          'message': message,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['success'] == true;
      } else {
        throw ServerException(
          message: 'Failed to send message',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'An error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
