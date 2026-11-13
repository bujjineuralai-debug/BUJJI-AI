import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';

class BujjiApiResponse {
  final int statusCode;
  final Map<String, dynamic> data;

  const BujjiApiResponse({
    required this.statusCode,
    required this.data,
  });

  bool get isSuccessful =>
      statusCode >= 200 && statusCode < 300 && data['success'] == true;

  String get errorMessage =>
      data['error']?.toString() ??
      data['message']?.toString() ??
      'The BUJJI AI service returned an error.';

  String? get detail => data['detail']?.toString();

  String? get requestId => data['requestId']?.toString();

  String textValue(String key) => data[key]?.toString().trim() ?? '';
}

/// The single HTTP boundary for BUJJI AI backend requests.
class BujjiApiClient {
  final String _baseUrl;

  const BujjiApiClient({String? baseUrl})
      : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Future<BujjiApiResponse> postJson(
    String path,
    Map<String, dynamic> payload, {
    Duration connectionTimeout = const Duration(seconds: 20),
    Duration requestTimeout = const Duration(seconds: 30),
    Duration responseTimeout = const Duration(seconds: 60),
    Duration bodyTimeout = const Duration(seconds: 30),
  }) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$normalizedPath');
    final client = HttpClient()..connectionTimeout = connectionTimeout;

    try {
      final request =
          await client.postUrl(uri).timeout(requestTimeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close().timeout(responseTimeout);
      final responseBody = await utf8.decoder
          .bind(response)
          .join()
          .timeout(bodyTimeout);

      dynamic decoded;
      try {
        decoded = jsonDecode(responseBody);
      } on FormatException {
        throw FormatException(
          'HTTP ${response.statusCode}: Invalid JSON response.',
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw FormatException(
          'HTTP ${response.statusCode}: Invalid server response.',
        );
      }

      return BujjiApiResponse(
        statusCode: response.statusCode,
        data: decoded,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<String> sendChat({
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    final response = await postJson('/chat', {
      'message': message,
      'history': history,
    });

    if (!response.isSuccessful) {
      throw Exception(
        'HTTP ${response.statusCode}: ${response.errorMessage}',
      );
    }

    final reply = response.textValue('reply');
    if (reply.isEmpty) {
      throw Exception('AI returned an empty response.');
    }
    return reply;
  }
}
