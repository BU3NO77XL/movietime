import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    Future<String?> Function()? accessTokenProvider,
  }) : _httpClient = httpClient ?? http.Client(),
       _baseUri = Uri.parse(baseUrl ?? ApiConfig.baseUrl),
       // ignore: prefer_initializing_formals
       _accessTokenProvider = accessTokenProvider;

  final http.Client _httpClient;
  final Uri _baseUri;
  final Future<String?> Function()? _accessTokenProvider;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> query = const {},
  }) {
    return _sendJson('GET', path, query: query);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _sendJson('POST', path, body: body);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _sendJson('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _sendJson('DELETE', path, body: body);
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    String path, {
    Map<String, String?> query = const {},
    Map<String, dynamic>? body,
  }) async {
    final uri = _resolve(path, query);
    final request = http.Request(method, uri)
      ..headers.addAll({'Accept': 'application/json'});

    final accessToken = await _accessTokenProvider?.call();
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      final streamed = await _httpClient.send(request);
      response = await http.Response.fromStream(streamed);
    } on Exception {
      throw const ApiException('Erro na comunicação com o servidor.');
    }

    final decoded = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _resolveErrorMessage(path, response.statusCode, decoded),
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  Uri _resolve(String path, Map<String, String?> query) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = _baseUri.resolve(cleanPath);
    final queryParameters = {
      ...uri.queryParameters,
      for (final entry in query.entries)
        if (entry.value != null) entry.key: entry.value!,
    };

    return uri.replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      if (response.statusCode >= 400) {
        return const <String, dynamic>{};
      }

      throw ApiException(
        'Resposta inesperada do servidor.',
        statusCode: response.statusCode,
      );
    }

    throw ApiException(
      'Resposta inesperada do servidor.',
      statusCode: response.statusCode,
    );
  }

  String _resolveErrorMessage(
    String path,
    int statusCode,
    Map<String, dynamic> decoded,
  ) {
    if (_shouldSanitizeServerError(path, statusCode)) {
      return 'Erro na comunicação com o servidor.';
    }

    final error = decoded['error']?.toString().trim();
    if (error != null && error.isNotEmpty) {
      return _sanitizeBackendMessage(error, path, statusCode);
    }

    return 'Erro na comunicação com o servidor.';
  }

  bool _shouldSanitizeServerError(String path, int statusCode) {
    if (statusCode >= 500) {
      return true;
    }

    if (statusCode == 404 && path.startsWith('/api/')) {
      return true;
    }

    return false;
  }

  String _sanitizeBackendMessage(String message, String path, int statusCode) {
    final normalized = message.trim();
    final lowered = normalized.toLowerCase();

    if (_shouldSanitizeServerError(path, statusCode)) {
      return 'Erro na comunicação com o servidor.';
    }

    const deployMarkers = <String>[
      '<!doctype html',
      '<html',
      'vercel',
      'deployment',
      'deploy',
      'cannot get ',
      'route not found',
      'not found',
      'function_invocation_failed',
      'internal server error',
      'unexpected token <',
    ];

    for (final marker in deployMarkers) {
      if (lowered.contains(marker)) {
        return 'Erro na comunicação com o servidor.';
      }
    }

    if (normalized.length > 180) {
      return 'Erro na comunicação com o servidor.';
    }

    return normalized;
  }

  void close() => _httpClient.close();
}
