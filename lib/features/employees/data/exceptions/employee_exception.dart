class EmployeeException implements Exception {
  final String message;
  final int? code;

  EmployeeException({required this.message, this.code});

  @override
  String toString() =>
      'EmployeeException: $message ${code != null ? '(Code: $code)' : ''}';
}
