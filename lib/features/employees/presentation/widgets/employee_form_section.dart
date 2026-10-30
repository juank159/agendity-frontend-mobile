import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/employees/presentation/controllers/employee_form_controller.dart';
import 'employee_schedule_section.dart';
import 'employee_services_section.dart';

/// Formulario de profesional, **único** para alta y edición: datos básicos,
/// servicios con comisión y horario. En edición el email es de solo lectura
/// y la contraseña es opcional.
class EmployeeFormSection extends StatelessWidget {
  final EmployeeFormController controller;
  final bool isEdit;
  final String submitLabel;

  const EmployeeFormSection({
    super.key,
    required this.controller,
    required this.submitLabel,
    this.isEdit = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle(icon: Icons.person_outline, title: 'Datos'),
          _Field(
            label: 'Nombre *',
            controller: controller.nameController,
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
          ),
          _Field(
            label: 'Apellido *',
            controller: controller.lastnameController,
            icon: Icons.people_outline,
            textCapitalization: TextCapitalization.words,
          ),
          _Field(
            label: 'Email *',
            controller: controller.emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            readOnly: isEdit,
            helper: isEdit
                ? 'El email no se puede cambiar: es su usuario y ya se '
                    'verificó (o está pendiente de verificar).'
                : 'Le enviaremos un código para verificarlo.',
          ),
          _Field(
            label: 'Teléfono *',
            controller: controller.phoneController,
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            helper: '10 dígitos',
          ),
          _Field(
            label: isEdit ? 'Nueva contraseña (opcional)' : 'Contraseña *',
            controller: controller.passwordController,
            icon: Icons.lock_outline,
            obscure: true,
            helper: isEdit
                ? 'Déjala en blanco para no cambiarla'
                : 'Mínimo 8 caracteres con mayúscula, minúscula, número y '
                    'un carácter especial (@\$!%*?&)',
          ),
          const SizedBox(height: 8),
          const _SectionTitle(icon: Icons.spa_outlined, title: 'Servicios'),
          _Field(
            label: 'Comisión general (%)',
            controller: controller.generalCommissionController,
            icon: Icons.percent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            helper: 'La que gana en cada servicio, salvo los que tengan una '
                'propia. De 0 a 100.',
          ),
          EmployeeServicesSection(controller: controller),
          const SizedBox(height: 8),
          const _SectionTitle(icon: Icons.schedule, title: 'Horario'),
          EmployeeScheduleSection(controller: controller),
          const SizedBox(height: 16),
          Obx(() => FilledButton.icon(
                onPressed:
                    controller.isSaving.value ? null : controller.submit,
                icon: controller.isSaving.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(isEdit ? Icons.save : Icons.person_add_alt_1),
                label: Text(submitLabel),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final bool obscure;
  final bool readOnly;
  final String? helper;
  final TextCapitalization textCapitalization;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.formatters,
    this.obscure = false,
    this.readOnly = false,
    this.helper,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        obscureText: obscure,
        readOnly: readOnly,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
          prefixIcon: Icon(icon),
          suffixIcon: readOnly ? const Icon(Icons.lock_outline) : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
