import 'dart:convert';

/// JWT sin firma válida (la app no la verifica): header.payload.firma.
String fakeJwt(Map<String, Object?> payload) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part(payload)}.firma';
}

int epochSeconds(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;
