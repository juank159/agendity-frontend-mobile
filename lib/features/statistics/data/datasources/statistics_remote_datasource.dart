// lib/features/statistics/data/datasources/statistics_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../../shared/local_storage/local_storage.dart';
import '../models/payment_stats_model.dart';
import '../models/payment_comparison_model.dart';
import '../models/payment_method_stats_model.dart';
import '../models/professional_stats_model.dart';
import '../models/service_stats_model.dart';
import '../models/client_stats_model.dart';
import '../models/top_client_model.dart';

class StatisticsRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  StatisticsRemoteDataSource({
    required this.dio,
    required this.localStorage,
  });

  Future<PaymentStatsModel> getPaymentStats(
      DateTime startDate, DateTime endDate) async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/payments/stats',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'startDate': _dateFormat.format(startDate),
          'endDate': _dateFormat.format(endDate),
        },
      );

      if (response.statusCode == 200) {
        return PaymentStatsModel.fromJson(response.data);
      }

      throw Exception(
          'Failed to load payment stats: Status ${response.statusCode}');
    } catch (e) {
      debugPrint('Error en getPaymentStats: $e');
      throw Exception('Error loading payment stats: $e');
    }
  }

  Future<PaymentComparisonModel> getPaymentComparison(
      DateTime startDate, DateTime endDate) async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/payments/stats/comparison',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'startDate': _dateFormat.format(startDate),
          'endDate': _dateFormat.format(endDate),
        },
      );

      if (response.statusCode == 200) {
        return PaymentComparisonModel.fromJson(response.data);
      }

      throw Exception(
          'Failed to load payment comparison: Status ${response.statusCode}');
    } catch (e) {
      debugPrint('Error en getPaymentComparison: $e');
      throw Exception('Error loading payment comparison: $e');
    }
  }

  Future<List<PaymentMethodStatsModel>> getPaymentStatsByMethod(
      DateTime startDate, DateTime endDate) async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/payments/stats/by-method',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'startDate': _dateFormat.format(startDate),
          'endDate': _dateFormat.format(endDate),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((item) => PaymentMethodStatsModel.fromJson(item))
            .toList();
      }

      throw Exception(
          'Failed to load payment stats by method: Status ${response.statusCode}');
    } catch (e) {
      debugPrint('Error en getPaymentStatsByMethod: $e');
      throw Exception('Error loading payment stats by method: $e');
    }
  }

  Future<List<ProfessionalStatsModel>> getPaymentStatsByProfessional(
      DateTime startDate, DateTime endDate) async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/payments/stats/by-professional',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'startDate': _dateFormat.format(startDate),
          'endDate': _dateFormat.format(endDate),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((item) => ProfessionalStatsModel.fromJson(item))
            .toList();
      }

      throw Exception(
          'Failed to load payment stats by professional: Status ${response.statusCode}');
    } catch (e) {
      debugPrint('Error en getPaymentStatsByProfessional: $e');
      throw Exception('Error loading payment stats by professional: $e');
    }
  }

  Future<List<ServiceStatsModel>> getPaymentStatsByService(
      DateTime startDate, DateTime endDate) async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/payments/stats/by-service',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'startDate': _dateFormat.format(startDate),
          'endDate': _dateFormat.format(endDate),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => ServiceStatsModel.fromJson(item)).toList();
      }

      throw Exception(
          'Failed to load payment stats by service: Status ${response.statusCode}');
    } catch (e) {
      debugPrint('Error en getPaymentStatsByService: $e');
      throw Exception('Error loading payment stats by service: $e');
    }
  }

  Future<List<ClientStatsModel>> getPaymentStatsByClient(
      DateTime startDate, DateTime endDate,
      {int limit = 10}) async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/payments/stats/by-client',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'startDate': _dateFormat.format(startDate),
          'endDate': _dateFormat.format(endDate),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => ClientStatsModel.fromJson(item)).toList();
      }

      throw Exception(
          'Failed to load payment stats by client: Status ${response.statusCode}');
    } catch (e) {
      debugPrint('Error en getPaymentStatsByClient: $e');
      throw Exception('Error loading payment stats by client: $e');
    }
  }

  Future<List<TopClientModel>> getTopClients(
      DateTime startDate, DateTime endDate,
      {int limit = 5}) async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/payments/stats/top-clients',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'startDate': _dateFormat.format(startDate),
          'endDate': _dateFormat.format(endDate),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => TopClientModel.fromJson(item)).toList();
      }

      throw Exception(
          'Failed to load top clients: Status ${response.statusCode}');
    } catch (e) {
      debugPrint('Error en getTopClients: $e');
      throw Exception('Error loading top clients: $e');
    }
  }
}
