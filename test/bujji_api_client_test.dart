import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bujji_ai/core/network/bujji_api_client.dart';

void main() {
  late HttpServer server;
  late int statusCode;
  late String responseBody;
  late Map<String, dynamic>? receivedPayload;

  setUp(() async {
    statusCode = 200;
    responseBody = jsonEncode({'success': true, 'reply': 'Hello from BUJJI'});
    receivedPayload = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final rawBody = await utf8.decoder.bind(request).join();
      receivedPayload = jsonDecode(rawBody) as Map<String, dynamic>;
      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.write(responseBody);
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
  });

  BujjiApiClient createClient() => BujjiApiClient(
        baseUrl: 'http://${server.address.address}:${server.port}',
      );

  test('sendChat posts the shared request contract and returns reply', () async {
    final reply = await createClient().sendChat(
      message: 'Hello',
      history: const [
        {'role': 'user', 'content': 'Previous message'},
      ],
    );

    expect(reply, 'Hello from BUJJI');
    expect(receivedPayload?['message'], 'Hello');
    expect(receivedPayload?['history'], [
      {'role': 'user', 'content': 'Previous message'},
    ]);
  });

  test('sendChat reports unsuccessful backend responses', () async {
    statusCode = 503;
    responseBody = jsonEncode({
      'success': false,
      'error': 'Service unavailable',
    });

    await expectLater(
      createClient().sendChat(message: 'Hello'),
      throwsA(isA<Exception>()),
    );
  });

  test('postJson rejects malformed JSON responses', () async {
    responseBody = 'not-json';

    await expectLater(
      createClient().postJson('/chat', {'message': 'Hello'}),
      throwsA(isA<FormatException>()),
    );
  });
}
