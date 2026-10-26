/// Tipo de precio de un servicio. Los valores del backend son textos en
/// español (`'Precio fijo'`, `'Precio variable'`) y se muestran tal cual.
enum ServicePriceType {
  fixed('Precio fijo'),
  variable('Precio variable');

  const ServicePriceType(this.apiValue);

  /// Valor del contrato (y etiqueta de la UI).
  final String apiValue;

  String toApi() => apiValue;

  /// `null` si no se reconoce (el llamador elige el valor por defecto).
  static ServicePriceType? fromApi(Object? value) {
    final text = value?.toString().trim().toLowerCase();
    for (final type in values) {
      if (type.apiValue.toLowerCase() == text) return type;
    }
    return null;
  }
}
