import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../auth/jwt_service.dart';
import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin wrapper around [http.Client] for the refetch.io REST API.
///
/// Handles JSON encoding/decoding, error mapping to [ApiException], and
/// injecting the cached Appwrite JWT as a Bearer token on authenticated calls.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.jwtService,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final JwtService jwtService;
  final http.Client _http;

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    return _send(() async => _http.get(uri, headers: await _headers(auth)));
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$path');
    return _send(
      () async => _http.post(
        uri,
        headers: await _headers(auth),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$path');
    return _send(() async => _http.delete(uri, headers: await _headers(auth)));
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request();
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(0, 'Network error: $error');
    }
    return _handle(response);
  }

  Future<Map<String, String>> _headers(bool auth) async {
    final headers = <String, String>{'content-type': 'application/json'};
    if (auth) {
      final token = await jwtService.getToken();
      if (token == null) {
        throw const ApiException(401, 'You need to sign in to do that.');
      }
      headers['authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _handle(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok) return decoded;

    final message = decoded is Map
        ? (decoded['message'] ?? decoded['error'] ?? 'Request failed')
        : 'Request failed';
    throw ApiException(response.statusCode, message.toString());
  }

  void close() => _http.close();
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    jwtService: ref.watch(jwtServiceProvider),
  );
  ref.onDispose(client.close);
  return client;
});
