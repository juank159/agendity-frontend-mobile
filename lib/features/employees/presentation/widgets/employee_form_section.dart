import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/features/employees/presentation/controllers/employee_form_controller.dart';
import 'package:login_signup/shared/widgets/app_section_card.dart';
import 'employee_schedule_section.dart';
import 'employee_services_section.dart';

/// Formulario de profesional, **único** para alta y edición, en tres
/// secciones de la guía: datos, servicios con su comisión (%) y horario
/// semanal (12 h, `AppTimePicker`). En edición el email es de solo lectura
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
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          AppSectionCard(
            icon: Icons.person_rounded,
            title: 'Datos',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Field(
                  label: 'Nombre *',
                  controller: controller.nameController,
                  icon: Icons.person_rounded,
                  textCapitalization: TextCapitalization.words,
                ),
                _Field(
                  label: 'Apellido *',
                  controller: controller.lastnameController,
                  icon: Icons.badge_rounded,
                  textCapitalization: TextCapitalization.words,
                ),
                _Field(
                  label: 'Email *',
                  controller: controller.emailController,
                  icon: Icons.email_rounded,
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
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  helper: '10 dígitos',
                ),
                _Field(
                  label: isEdit
                      ? 'Nueva contraseña (opcional)'
                      : 'Contraseña *',
                  controller: controller.passwordController,
                  icon: Icons.lock_rounded,
                  obscure: true,
                  helper: isEdit
                      ? 'Déjala en blanco para no cambiarla'
                      : 'Mínimo 8 caracteres con mayúscula, minúscula, número '
                          'y un carácter especial (@\$!%*?&)',
                ),
              ],
            ),
          ),
          AppSectionCard(
            icon: Icons.spa_rounded,
            title: 'Servicios y comisión',
            subtitle: 'Marca los servicios que atiende. Cada uno usa la '
                'comisión general o una propia.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CommissionField(controller: controller),
                const SizedBox(height: 12),
                EmployeeServicesSection(controller: controller),
              ],
            ),
          ),
          AppSectionCard(
            icon: Icons.schedule_rounded,
            title: 'Horario',
            subtitle: 'Días y horas en que se le pueden agendar citas.',
            child: EmployeeScheduleSection(controller: controller),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Obx(() => AppGradientButton(
                  label: submitLabel,
                  icon: isEdit
                      ? Icons.check_rounded
                      : Icons.person_add_alt_1_rounded,
                  expand: true,
                  loading: controller.isSaving.value,
                  onPressed: controller.submit,
                )),
          ),
        ],
      ),
    );
  }
}

/// Comisión general en % (D-16): campo numérico con sufijo "%" y el error en
/// vivo si no es un número de 0 a 100 (el mismo texto del use case).
class _CommissionField extends StatelessWidget {
  final EmployeeFormController controller;

  const _CommissionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.generalCommission.value; // se repinta con cada cambio
      return TextField(
        key: const Key('employee-general-commission'),
        controller: controller.generalCommissionController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          LengthLimitingTextInputFormatter(6),
        ],
        style: const TextStyle().tabular,
        decoration: InputDecoration(
          labelText: 'Comisión general (%)',
          prefixIcon: const Icon(Icons.percent_rounded),
          suffixText: '%',
          helperText: 'La que gana en cada servicio, salvo los que tengan '
              'una propia. De 0 a 100.',
          helperMaxLines: 3,
          errorText: controller.generalCommissionError,
          errorMaxLines: 2,
        ),
      );
    });
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
          suffixIcon: readOnly ? const Icon(Icons.lock_rounded) : null,
        ),
      ),
    );
  }
}
