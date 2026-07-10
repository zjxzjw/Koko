import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:koko/main.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const BalanceMonitorApp());
    // The app should render without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
