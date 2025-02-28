abstract class Failure {
  final String message;

  Failure({required this.message});
}

class ServerFailure extends Failure {
  ServerFailure({required super.message});
}

class CacheFailure extends Failure {
  CacheFailure({required super.message});
}

class StorageFailure extends Failure {
  StorageFailure({required super.message});
}

class NetworkFailure extends Failure {
  NetworkFailure({super.message = 'Error de conexión a internet'});
}
