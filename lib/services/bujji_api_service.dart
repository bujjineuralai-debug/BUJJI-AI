import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const String _diagnosticsKey = 'bujji_api_diagnostics_v1';

  static Future<void> _recordDiagnostic({
    required String endpoint,
    required int durationMs,
    int? statusCode,
    String? requestId,
    String? errorType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final previous = prefs.getStringList(_diagnosticsKey) ?? <String>[];
      final entry = <String, dynamic>{
        'endpoint': endpoint,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'durationMs': durationMs,
        'statusCode': statusCode,
        'requestId': requestId,
        'outcome': errorType == null &&
                statusCode != null &&
                statusCode >= 200 &&
                statusCode < 300
            ? 'success'
            : 'failure',
        if (errorType != null) 'errorType': errorType,
      };
      final updated = <String>[
        jsonEncode(entry),
        ...previous.take(49),
      ];
      await prefs.setStringList(_diagnosticsKey, updated);
    } catch (_) {
      // Diagnostics must never interrupt the user's request.
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentDiagnostics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = prefs.getStringList(_diagnosticsKey) ?? <String>[];
      return entries.map((entry) {
        final decoded = jsonDecode(entry);
        return decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{};
      }).where((entry) => entry.isNotEmpty).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<BujjiApiResponse> postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final stopwatch = Stopwatch()..start();
    final endpoint = uri.path;
    int? statusCode;
    String? requestId;
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
      statusCode = response.statusCode;
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
      requestId = decoded['requestId'] is String
          ? decoded['requestId'] as String
          : null;
      await _recordDiagnostic(
        endpoint: endpoint,
        durationMs: stopwatch.elapsedMilliseconds,
        statusCode: statusCode,
        requestId: requestId,
      );

      return BujjiApiResponse(
        statusCode: response.statusCode,
        data: decoded,
      );
    } catch (error) {
      await _recordDiagnostic(
        endpoint: endpoint,
        durationMs: stopwatch.elapsedMilliseconds,
        statusCode: statusCode,
        requestId: requestId,
        errorType: error.runtimeType.toString(),
      );
      rethrow;
    } finally {
      stopwatch.stop();
      client.close(force: true);
    }
  }
}
