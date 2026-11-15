import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Why a request failed, so callers can react without parsing messages.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NoConnectionException extends ApiException {
  const NoConnectionException(super.message);
}

class RequestTimeoutException extends ApiException {
  const RequestTimeoutException(super.message);
}

class ServerException extends ApiException {
  const ServerException(this.statusCode, super.message);

  final int statusCode;
}

/// Thin wrapper around [http.Client] that adds a timeout and turns every
/// failure into an [ApiException].
class ApiClient {
  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 5)})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Kept short: the UI waits on the first request, and the app has local
  /// fallbacks, so a slow network should not hold the screen for long.
  final Duration timeout;

  /// GETs [uri] and returns the response body.
  Future<String> getText(Uri uri) async {
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw RequestTimeoutException('No response from $uri within $timeout');
    } on SocketException catch (error) {
      throw NoConnectionException(error.message);
    } on http.ClientException catch (error) {
      throw NoConnectionException(error.message);
    }

    if (response.statusCode != HttpStatus.ok) {
      throw ServerException(
        response.statusCode,
        'GET $uri returned ${response.statusCode}',
      );
    }
    // response.body assumes Latin-1 when the server sends no charset.
    return utf8.decode(response.bodyBytes);
  }
}
