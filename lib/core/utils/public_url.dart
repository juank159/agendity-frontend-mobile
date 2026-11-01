/// Páginas públicas que sirve el backend fuera de `/api` (reservas 9.02,
/// consentimiento 11.06): la base del API (`…/api`) sin `/api` + [path].
String publicWebUrl(String apiUrl, String path) {
  var base = apiUrl.trim();
  while (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }
  if (base.endsWith('/api')) base = base.substring(0, base.length - 4);
  return '$base${path.startsWith('/') ? '' : '/'}$path';
}
