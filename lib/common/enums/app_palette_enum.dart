/// Paleta de color de la app (D-22). La usan dos features: `theme` (la que
/// elige el dispositivo) y `settings` (la del negocio, `theme_palette` de
/// `GET/PATCH /settings`); por eso vive en `common/` (ARQUITECTURA §1.5).
///
/// [id] es el valor estable del contrato: igual al del backend
/// (`backend/src/settings/theme-palette.ts`, `THEME_PALETTES`) y al que se
/// guarda en el dispositivo. No cambiarlo sin migrar ambos lados.
///
/// Sin colores ni textos de UI: las semillas, los tokens y el nombre visible
/// son de presentation (12.03).
enum AppPalette {
  lavanda('lavanda'),
  rosa('rosa'),
  azul('azul'),
  turquesa('turquesa'),
  coral('coral'),
  grafito('grafito');

  const AppPalette(this.id);

  final String id;

  /// La que se usa cuando ni el dispositivo ni el negocio eligieron una.
  static const AppPalette fallback = AppPalette.lavanda;

  /// `id` → paleta. `null`, vacío o desconocido → `null` (sin elegir), como
  /// hace el backend (`storedThemePalette`). Tolera espacios y mayúsculas.
  static AppPalette? fromId(Object? value) {
    if (value is! String) return null;
    final id = value.trim().toLowerCase();
    for (final palette in values) {
      if (palette.id == id) return palette;
    }
    return null;
  }
}
