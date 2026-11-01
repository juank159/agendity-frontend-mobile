import 'package:dio/dio.dart';
import 'package:login_signup/features/reminders/data/models/reminder_models.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_delivery.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_settings.dart';

/// `/reminders/*` (solo Owner) sobre el Dio `api`. Sin try/catch: los
/// errores los traduce `safeCall`.
abstract class RemindersRemoteDataSource {
  Future<ReminderSettings> getSettings();
  Future<ReminderSettings> updateSettings(ReminderSettings settings);
  Future<List<ReminderRule>> getRules();
  Future<ReminderRule> createRule(ReminderRule rule);
  Future<ReminderRule> updateRule(String id, ReminderRule rule);
  Future<void> deleteRule(String id);
  Future<String> preview(ReminderKind kind, String template);
  Future<List<ReminderDelivery>> getDeliveries(DeliveriesQuery query);
}

class RemindersRemoteDataSourceImpl implements RemindersRemoteDataSource {
  final Dio _dio;

  RemindersRemoteDataSourceImpl(this._dio);

  @override
  Future<ReminderSettings> getSettings() async =>
      ReminderSettingsModel.fromJson((await _dio
              .get<Map<String, dynamic>>('/reminders/settings'))
          .data!);

  @override
  Future<ReminderSettings> updateSettings(ReminderSettings settings) async =>
      ReminderSettingsModel.fromJson((await _dio.put<Map<String, dynamic>>(
              '/reminders/settings',
              data: ReminderSettingsModel.toJson(settings)))
          .data!);

  @override
  Future<List<ReminderRule>> getRules() async {
    final response = await _dio.get<List<dynamic>>('/reminders/rules');
    return [
      for (final row in response.data!)
        ReminderRuleModel.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
  }

  @override
  Future<ReminderRule> createRule(ReminderRule rule) async =>
      ReminderRuleModel.fromJson((await _dio.post<Map<String, dynamic>>(
              '/reminders/rules',
              data: ReminderRuleModel.toJson(rule, create: true)))
          .data!);

  @override
  Future<ReminderRule> updateRule(String id, ReminderRule rule) async =>
      ReminderRuleModel.fromJson((await _dio.patch<Map<String, dynamic>>(
              '/reminders/rules/$id',
              data: ReminderRuleModel.toJson(rule, create: false)))
          .data!);

  @override
  Future<void> deleteRule(String id) =>
      _dio.delete<void>('/reminders/rules/$id');

  @override
  Future<String> preview(ReminderKind kind, String template) async {
    final response = await _dio.post<Map<String, dynamic>>(
        '/reminders/rules/preview',
        data: {
          'kind': kind.apiValue,
          if (template.isNotEmpty) 'template': template,
        });
    return response.data?['text']?.toString() ?? '';
  }

  @override
  Future<List<ReminderDelivery>> getDeliveries(DeliveriesQuery query) async {
    final response = await _dio.get<List<dynamic>>('/reminders/deliveries',
        queryParameters: {
          if (query.status != null) 'status': query.status!.apiValue,
          if (query.clientId != null) 'client_id': query.clientId,
          'limit': query.limit,
          'offset': query.offset,
        });
    return [
      for (final row in response.data!)
        ReminderDeliveryModel.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
  }
}
