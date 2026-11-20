import 'package:flutter_test/flutter_test.dart';
import 'package:bujji_ai/services/bujji_api_service.dart';

void main() {
  group('BujjiApiService.isSuccessfulApplicationResponse', () {
    test('accepts a successful 2xx application response', () {
      expect(
        BujjiApiService.isSuccessfulApplicationResponse(
          statusCode: 200,
          data: {'success': true},
        ),
        isTrue,
      );
    });

    test('rejects an application failure returned with HTTP 200', () {
      expect(
        BujjiApiService.isSuccessfulApplicationResponse(
          statusCode: 200,
          data: {'success': false, 'error': 'provider_unavailable'},
        ),
        isFalse,
      );
    });

    test('keeps legacy 2xx responses without a success field compatible', () {
      expect(
        BujjiApiService.isSuccessfulApplicationResponse(
          statusCode: 204,
          data: <String, dynamic>{},
        ),
        isTrue,
      );
    });

    test('rejects non-2xx responses even when success is true', () {
      expect(
        BujjiApiService.isSuccessfulApplicationResponse(
          statusCode: 503,
          data: {'success': true},
        ),
        isFalse,
      );
    });
  });
}
