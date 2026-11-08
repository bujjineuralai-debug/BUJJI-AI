import 'package:flutter_test/flutter_test.dart';
import '../lib/tools/currency_converter.dart';

void main() {
  group('convertCurrencyAmount', () {
    test('converts an amount using USD-based exchange rates', () {
      final result = convertCurrencyAmount(
        amount: 100,
        fromRate: 1,
        toRate: 83,
      );

      expect(result, 8300);
    });

    test('converts in the reverse direction', () {
      final result = convertCurrencyAmount(
        amount: 8300,
        fromRate: 83,
        toRate: 1,
      );

      expect(result, 100);
    });

    test('returns null for a negative amount', () {
      final result = convertCurrencyAmount(
        amount: -10,
        fromRate: 1,
        toRate: 83,
      );

      expect(result, isNull);
    });

    test('returns null when a source rate is zero', () {
      final result = convertCurrencyAmount(
        amount: 10,
        fromRate: 0,
        toRate: 83,
      );

      expect(result, isNull);
    });
  });
}
