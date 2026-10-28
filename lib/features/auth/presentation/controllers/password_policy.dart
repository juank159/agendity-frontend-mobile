/// Requisitos de contraseña del backend (`create-auth.dto.ts` y
/// `reset-password.dto.ts`): al menos 8 caracteres con mayúscula, minúscula,
/// número y un carácter especial de `@$!%*?&`. Los usan el registro y el
/// cambio de contraseña para avisar antes de enviar.
enum PasswordRequirement {
  length('Al menos 8 caracteres'),
  uppercase('Una letra mayúscula'),
  lowercase('Una letra minúscula'),
  number('Un número'),
  special(r'Un carácter especial (@$!%*?&)');

  const PasswordRequirement(this.label);

  final String label;

  static final _upper = RegExp(r'[A-Z]');
  static final _lower = RegExp(r'[a-z]');
  static final _digit = RegExp(r'\d');
  static final _special = RegExp(r'[@$!%*?&]');

  bool isMetBy(String password) => switch (this) {
        length => password.length >= 8,
        uppercase => _upper.hasMatch(password),
        lowercase => _lower.hasMatch(password),
        number => _digit.hasMatch(password),
        special => _special.hasMatch(password),
      };
}

abstract final class PasswordPolicy {
  static const requiredMessage = 'La contraseña es obligatoria';
  static const weakMessage =
      'La contraseña debe cumplir todos los requisitos de seguridad';

  /// Estado de cada requisito para [password].
  static Map<PasswordRequirement, bool> check(String password) => {
        for (final requirement in PasswordRequirement.values)
          requirement: requirement.isMetBy(password),
      };

  /// Mensaje de error o `null` si la contraseña cumple todo.
  static String? validate(String password) {
    if (password.isEmpty) return requiredMessage;
    final allMet =
        PasswordRequirement.values.every((r) => r.isMetBy(password));
    return allMet ? null : weakMessage;
  }
}
