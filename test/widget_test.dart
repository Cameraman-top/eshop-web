import 'package:flutter_test/flutter_test.dart';

import 'package:eshop_flutter/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const EShopApp());
    expect(find.text('eShop 商城'), findsOneWidget);
  });
}
