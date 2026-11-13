import 'package:flutter_test/flutter_test.dart';
import 'package:bujji_ai/main.dart';

void main() {
  group('ChatMessage', () {
    test('serializes and restores a valid message', () {
      const original = ChatMessage(role: 'user', content: 'నమస్కారం');
      final restored = ChatMessage.fromJson(original.toJson());

      expect(restored.role, 'user');
      expect(restored.content, 'నమస్కారం');
    });

    test('rejects unsupported roles', () {
      expect(
        () => ChatMessage.fromJson({
          'role': 'system',
          'content': 'not a user-facing message',
        }),
        throwsFormatException,
      );
    });

    test('rejects non-string message content', () {
      expect(
        () => ChatMessage.fromJson({
          'role': 'assistant',
          'content': 42,
        }),
        throwsFormatException,
      );
    });
  });
}
