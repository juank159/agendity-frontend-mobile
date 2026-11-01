/// Link de consentimiento de WhatsApp de un cliente (11.06): página pública
/// `/consentimiento/:token` (un solo uso, 30 días) que el negocio manda por
/// `wa.me`.
class ConsentLink {
  /// URL completa si el servidor conoce su base pública; si no, `null` y se
  /// arma con la base del API + [path].
  final String? url;
  final String path;
  final DateTime? expiresAt;

  /// El cliente ya aceptó: no hace falta pedirlo.
  final bool alreadyOptedIn;

  const ConsentLink({
    this.url,
    required this.path,
    this.expiresAt,
    this.alreadyOptedIn = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsentLink &&
          other.url == url &&
          other.path == path &&
          other.expiresAt == expiresAt &&
          other.alreadyOptedIn == alreadyOptedIn;

  @override
  int get hashCode => Object.hash(url, path, expiresAt, alreadyOptedIn);
}
