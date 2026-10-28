import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/clients/domain/entities/client_import_result.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';

/// Máximo de rechazados que se listan en el resumen.
const maxListedRejections = 10;

/// Resumen de una importación: importados, rechazados con su motivo y no
/// enviados (si un lote se interrumpió).
Future<void> showClientImportSummary(ClientImportResult result) {
  final lines = <String>[
    for (final rejection in result.rejected.take(maxListedRejections))
      '• ${rejection.name.isEmpty ? rejection.phone : rejection.name}: '
          '${rejection.reason.replaceAll('\n', ', ')}',
    if (result.rejected.length > maxListedRejections)
      '… y ${result.rejected.length - maxListedRejections} más',
    if (result.notSent > 0)
      'No se enviaron ${result.notSent}'
          '${result.interruption == null ? '' : ': ${result.interruption!.message}'}',
  ];
  final complete = result.failed == 0;
  return AppDialogs.info(
    title: complete ? 'Contactos importados' : 'Importación parcial',
    message: _message(result),
    detail: lines.isEmpty ? null : lines.join('\n'),
    tone: complete ? AppTone.success : AppTone.warning,
    icon: complete ? Icons.check_circle_outline : Icons.info_outline,
  );
}

String _message(ClientImportResult result) {
  final parts = <String>[
    '${result.imported} importados',
    if (result.rejected.isNotEmpty) '${result.rejected.length} rechazados',
    if (result.notSent > 0) '${result.notSent} sin enviar',
  ];
  return '${parts.join(', ')} de ${result.requested} contactos.';
}
