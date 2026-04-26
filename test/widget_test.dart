import 'package:flutter_test/flutter_test.dart';

import 'package:agri_trade_farmer_app/shared/screens/main_shell_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('builds the navigation shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainShellScreen(),
      ),
    );

    expect(find.text('AgriTrade'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
  });
}
