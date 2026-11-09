import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bujji_ai/tools/currency_converter.dart';

void main() {
  testWidgets('Currency converter screen opens', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CurrencyConverter()),
    );
    await tester.pump();

    expect(find.text('Currency Converter'), findsOneWidget);
    expect(find.text('CONVERT CURRENCIES'), findsOneWidget);
    expect(find.text('YOU SEND'), findsOneWidget);
    expect(find.text('YOU RECEIVE'), findsOneWidget);
  });

  testWidgets('Currency picker can search currency codes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CurrencyConverter()),
    );
    await tester.pump();

    await tester.tap(find.text('USD').first);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Select currency'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'INR');
    await tester.pump();

    expect(find.text('INR'), findsWidgets);
    expect(find.text('Indian Rupee'), findsOneWidget);
  });
}
