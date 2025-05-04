// lib/features/subscriptions/data/repositories/subscription_repository_impl.dart

import 'package:login_signup/core/errors/exceptions.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:login_signup/features/subscriptions/data/models/subscription_model.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/features/subscriptions/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;

  SubscriptionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> checkSubscriptionStatus() async {
    try {
      return await remoteDataSource.checkSubscriptionStatus();
    } on ServerException catch (e) {
      print('ServerException en checkSubscriptionStatus: ${e.message}');
      return {
        'canCreateAppointment': false,
        'message': e.message,
      };
    } catch (e) {
      print('Exception general en checkSubscriptionStatus: $e');
      return {
        'canCreateAppointment': false,
        'message': 'Error al verificar estado de suscripción.',
      };
    }
  }

  @override
  Future<List<SubscriptionPlanEntity>> getAllPlans() async {
    try {
      final planModels = await remoteDataSource.getAllPlans();
      return planModels;
    } on ServerException catch (e) {
      print('ServerException en getAllPlans: ${e.message}');
      throw ServerFailure(message: e.message);
    } catch (e) {
      print('Exception general en getAllPlans: $e');
      throw ServerFailure(message: 'Error inesperado al obtener planes');
    }
  }

  @override
  Future<SubscriptionPlanEntity> getPlanById(String id) async {
    try {
      return await remoteDataSource.getPlanById(id);
    } on ServerException catch (e) {
      print('ServerException en getPlanById: ${e.message}');
      throw ServerFailure(message: e.message);
    } catch (e) {
      print('Exception general en getPlanById: $e');
      throw ServerFailure(message: 'Error inesperado al obtener plan');
    }
  }

  @override
  Future<SubscriptionEntity> getCurrentSubscription() async {
    try {
      return await remoteDataSource.getCurrentSubscription();
    } on ServerException catch (e) {
      print('ServerException en getCurrentSubscription: ${e.message}');
      throw ServerFailure(message: e.message);
    } catch (e) {
      print('Exception general en getCurrentSubscription: $e');
      throw ServerFailure(message: 'Error inesperado al obtener suscripción');
    }
  }

  @override
  Future<Map<String, dynamic>> createPaidSubscription(
      String planId, String redirectUrl) async {
    try {
      return await remoteDataSource.createPaidSubscription(planId, redirectUrl);
    } on ServerException catch (e) {
      print('ServerException en createPaidSubscription: ${e.message}');
      throw ServerFailure(message: e.message);
    } catch (e) {
      print('Exception general en createPaidSubscription: $e');
      throw ServerFailure(message: 'Error inesperado al crear suscripción');
    }
  }
}
