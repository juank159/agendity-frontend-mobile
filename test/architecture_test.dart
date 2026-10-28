import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reglas de dependencias de ARQUITECTURA §1.7 y §4 (5.02):
/// - `domain/` no importa Flutter, GetX, Dio ni nada de `data/`;
/// - `presentation/` no importa nada de `data/`.
///
/// Recorre `lib/` y resuelve también los imports relativos.
const _packagePrefix = 'package:login_signup/';
const _forbiddenInDomain = ['package:flutter/', 'package:get/', 'package:dio/'];

final _importPattern =
    RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

/// Ruta de [uri] relativa a `lib/` (o el propio uri si es de otro paquete).
String _resolve(String uri, String fileDir) {
  if (uri.startsWith(_packagePrefix)) return uri.substring(_packagePrefix.length);
  if (uri.contains(':')) return uri;
  final segments = [...fileDir.split('/'), ...uri.split('/')];
  final resolved = <String>[];
  for (final segment in segments) {
    if (segment == '..') {
      if (resolved.isNotEmpty) resolved.removeLast();
    } else if (segment != '.' && segment.isNotEmpty) {
      resolved.add(segment);
    }
  }
  return resolved.join('/');
}

bool _inLayer(String path, String layer) => path.split('/').contains(layer);

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// `archivo → import` que rompen una regla.
  List<String> violations(bool Function(String path, String target) breaks) {
    final found = <String>[];
    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/').substring('lib/'.length);
      final dir = path.contains('/') ? path.substring(0, path.lastIndexOf('/')) : '';
      for (final match in _importPattern.allMatches(file.readAsStringSync())) {
        final target = _resolve(match.group(1)!, dir);
        if (breaks(path, target)) found.add('$path → ${match.group(1)}');
      }
    }
    return found;
  }

  test('se recorren los archivos de lib/', () {
    expect(files.length, greaterThan(100));
  });

  test('domain/ no importa Flutter, GetX ni Dio', () {
    expect(
        violations((path, target) =>
            _inLayer(path, 'domain') &&
            _forbiddenInDomain.any(target.startsWith)),
        isEmpty);
  });

  test('domain/ no importa data/', () {
    expect(
        violations((path, target) =>
            _inLayer(path, 'domain') && _inLayer(target, 'data')),
        isEmpty);
  });

  test('presentation/ no importa data/', () {
    expect(
        violations((path, target) =>
            _inLayer(path, 'presentation') && _inLayer(target, 'data')),
        isEmpty);
  });

  test('los imports relativos se resuelven (control del propio test)', () {
    expect(_resolve('../../data/models/x.dart', 'features/a/presentation/w'),
        'features/a/data/models/x.dart');
    expect(_resolve('package:login_signup/features/a/data/x.dart', ''),
        'features/a/data/x.dart');
    expect(_inLayer('features/a/data/models/x.dart', 'data'), true);
    expect(_inLayer('features/a/metadata/x.dart', 'data'), false);
  });
}
