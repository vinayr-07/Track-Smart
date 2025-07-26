import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_smart/main.dart';

void main() {
  testWidgets('Track Smart app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);

    expect(find.text('Track Smart'), findsNothing);
  });
}
