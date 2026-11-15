import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recipe_app/data/remote/api_client.dart';

void main() {
  final uri = Uri.parse('https://example.com/recipetypes.json');

  ApiClient clientReturning(Future<http.Response> Function() respond) {
    return ApiClient(
      client: MockClient((_) => respond()),
      timeout: const Duration(milliseconds: 50),
    );
  }

  test('returns the body as UTF-8 even without a charset header', () async {
    final client = clientReturning(
      () async => http.Response.bytes(utf8.encode('Crème brûlée'), 200),
    );

    expect(await client.getText(uri), 'Crème brûlée');
  });

  test('a non-200 status throws ServerException', () {
    final client = clientReturning(() async => http.Response('oops', 500));

    expect(
      client.getText(uri),
      throwsA(isA<ServerException>().having((e) => e.statusCode, 'code', 500)),
    );
  });

  test('a connection failure throws NoConnectionException', () {
    final client = clientReturning(
      () async => throw http.ClientException('Failed host lookup'),
    );

    expect(client.getText(uri), throwsA(isA<NoConnectionException>()));
  });

  test('a slow server throws RequestTimeoutException', () {
    final client = clientReturning(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return http.Response('late', 200);
    });

    expect(client.getText(uri), throwsA(isA<RequestTimeoutException>()));
  });
}
