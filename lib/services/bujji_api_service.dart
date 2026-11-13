import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

class BujjiApiResponse {
  final int statusCode;
  final Map<String, dynamic> data;

  const BujjiApiResponse({
    required this.statusCode,
    required this.data,
  });
}

/// Shared authenticated transport for all BUJJI AI Worker endpoints.
class BujjiApiService {
  BujjiApiService._();

  static Future<User> _ensureUser() async {
    final auth = FirebaseAuth.instance;
    final current = auth.currentUser;
    if (current != null) return current;

    final credential = await auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Unable to establish a secure BUJJI session.');
    }
    return user;
  }

  static Future<BujjiApiResponse> postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final user = await _ensureUser();
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Unable to obtain a Firebase session token. Please sign in again.');
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 30));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      final responseText = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 30));

      final dynamic decoded;
      try {
        decoded = jsonDecode(responseText);
      } on FormatException {
        throw FormatException(
          'BUJJI server returned invalid JSON (HTTP ${response.statusCode}).',
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('BUJJI server returned an invalid response.');
      }

      return BujjiApiResponse(
        statusCode: response.statusCode,
        data: decoded,
      );
    } finally {
      client.close(force: true);
    }
  }
}
