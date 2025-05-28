class EmployeeException implements Exception {
  final String message;
  final int? code;

  EmployeeException({required this.message, this.code});

  // Modificar el toString para que no agregue el prefijo
  @override
  String toString() => message; // Solo devuelve el mensaje exacto
}
