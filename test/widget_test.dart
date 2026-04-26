import 'package:flutter_test/flutter_test.dart';

import 'package:agri_trade_farmer_app/main.dart';

void main() {
  testWidgets('shows the AgriTrade splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AgriTradeApp());

    expect(find.text('AgriTrade'), findsOneWidget);
    expect(find.text('Connecting farmers and buyers offline first'), findsOneWidget);
  });
}
