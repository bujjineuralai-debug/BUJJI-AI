
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bujji_ai/tools/smart_calculator.dart';

void main() {
  Future<void> openCalculator(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SmartCalculator(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterBasicNumbers(
    WidgetTester tester,
    String first,
    String second,
  ) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), first);
    await tester.enterText(fields.at(1), second);
  }

  testWidgets('Calculator opens correctly', (tester) async {
    await openCalculator(tester);

    expect(find.text('Smart Calculator'), findsOneWidget);
    expect(find.text('BUJJI AI Calculator'), findsOneWidget);
  });

  testWidgets('Basic addition calculates 25 + 15 = 40', (tester) async {
    await openCalculator(tester);
    await enterBasicNumbers(tester, '25', '15');

    await tester.ensureVisible(find.text('CALCULATE  ='));
    await tester.tap(find.text('CALCULATE  ='));
    await tester.pumpAndSettle();

    expect(find.text('40'), findsOneWidget);
  });

  testWidgets('Division by zero shows error', (tester) async {
    await openCalculator(tester);
    await enterBasicNumbers(tester, '25', '0');

    await tester.tap(find.text('÷'));
    await tester.pump();

    await tester.ensureVisible(find.text('CALCULATE  ='));
    await tester.tap(find.text('CALCULATE  ='));
    await tester.pumpAndSettle();

    expect(find.text('Cannot divide by zero'), findsOneWidget);
  });

  testWidgets('GST addition calculates correctly', (tester) async {
    await openCalculator(tester);

    await tester.tap(find.text('GST'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1000');
    await tester.enterText(fields.at(1), '18');

    await tester.ensureVisible(find.text('Add GST'));
    await tester.tap(find.text('Add GST'));
    await tester.pumpAndSettle();

    expect(find.text('1180'), findsOneWidget);
  });

  testWidgets('GST removal calculates correctly', (tester) async {
    await openCalculator(tester);

    await tester.tap(find.text('GST'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1180');
    await tester.enterText(fields.at(1), '18');

    await tester.ensureVisible(find.text('Remove GST'));
    await tester.tap(find.text('Remove GST'));
    await tester.pumpAndSettle();

    expect(find.text('1000'), findsOneWidget);
  });

  testWidgets('EMI calculation works with zero interest', (tester) async {
    await openCalculator(tester);

    await tester.tap(find.text('EMI'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '12000');
    await tester.enterText(fields.at(1), '0');
    await tester.enterText(fields.at(2), '12');

    await tester.ensureVisible(find.text('Calculate EMI'));
    await tester.tap(find.text('Calculate EMI'));
    await tester.pumpAndSettle();

    expect(find.text('1000'), findsOneWidget);
  });

  testWidgets('Calculation appears in History', (tester) async {
    await openCalculator(tester);
    await enterBasicNumbers(tester, '25', '15');

    await tester.ensureVisible(find.text('CALCULATE  ='));
    await tester.tap(find.text('CALCULATE  ='));
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('25.0 + 15.0 = 40'), findsOneWidget);
  });
}
