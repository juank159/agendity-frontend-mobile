import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/reminders/data/datasources/reminders_remote_datasource.dart';
import 'package:login_signup/features/reminders/data/repositories/reminders_repository_impl.dart';
import 'package:login_signup/features/reminders/domain/repositories/reminders_repository.dart';
import 'package:login_signup/features/reminders/domain/usecases/delete_reminder_rule_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/get_reminder_deliveries_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/get_reminder_rules_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/get_reminder_settings_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/preview_reminder_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/save_reminder_rule_usecase.dart';
import 'package:login_signup/features/reminders/domain/usecases/update_reminder_settings_usecase.dart';

/// Datasource, repositorio y use cases de recordatorios automáticos
/// (ARQUITECTURA §4, Fase 11; con conexión y solo Owner). El binding de la
/// ruta (FP) registra solo el controller.
abstract final class RemindersDependencies {
  static void init() {
    Get.lazyPut<RemindersRemoteDataSource>(
      () => RemindersRemoteDataSourceImpl(Get.find<Dio>(tag: apiClientTag)),
      fenix: true,
    );
    Get.lazyPut<RemindersRepository>(
      () => RemindersRepositoryImpl(Get.find<RemindersRemoteDataSource>()),
      fenix: true,
    );
    RemindersRepository repository() => Get.find<RemindersRepository>();
    Get.lazyPut(() => GetReminderSettingsUseCase(repository()), fenix: true);
    Get.lazyPut(() => UpdateReminderSettingsUseCase(repository()),
        fenix: true);
    Get.lazyPut(() => GetReminderRulesUseCase(repository()), fenix: true);
    Get.lazyPut(() => SaveReminderRuleUseCase(repository()), fenix: true);
    Get.lazyPut(() => DeleteReminderRuleUseCase(repository()), fenix: true);
    Get.lazyPut(() => PreviewReminderUseCase(repository()), fenix: true);
    Get.lazyPut(() => GetReminderDeliveriesUseCase(repository()), fenix: true);
  }
}
