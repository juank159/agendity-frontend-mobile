import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/services/domain/failures/services_failures.dart';
import 'package:login_signup/shared/controller/session_controller.dart';

/// Reglas de la UI del catálogo (servicios y categorías) comunes a los
/// controllers de la feature.
abstract final class CatalogAccess {
  /// Texto que ve el usuario al intentar borrar una categoría con servicios.
  static const categoryHasServicesMessage =
      'No puedes eliminar una categoría que tiene servicios. '
      'Muévelos o elimínalos primero.';

  static const forbiddenMessage =
      'Solo el propietario del negocio puede modificar el catálogo.';

  /// Solo el Owner crea, edita o borra; el Employee ve el catálogo en solo
  /// lectura. Sin sesión registrada, solo lectura. Leído dentro de un `Obx`
  /// reacciona a los cambios de sesión.
  static bool canManage() =>
      Get.isRegistered<SessionController>() &&
      Get.find<SessionController>().isOwner;

  /// Mensaje para el usuario de un fallo del catálogo.
  static String messageFor(Failure failure) {
    if (failure is CategoryHasServicesFailure) {
      return categoryHasServicesMessage;
    }
    if (failure is ForbiddenFailure) return forbiddenMessage;
    return failure.message;
  }
}
