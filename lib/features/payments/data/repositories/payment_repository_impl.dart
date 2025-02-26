import 'package:login_signup/features/payments/data/datasources/payment_remote_datasource.dart';
import 'package:login_signup/features/payments/data/models/payment_model.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<PaymentEntity> createPayment(PaymentEntity payment) async {
    final paymentModel = PaymentModel.fromEntity(payment);
    return await remoteDataSource.createPayment(paymentModel);
  }
}
