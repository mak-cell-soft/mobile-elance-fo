import 'package:flutter_test/flutter_test.dart';

import 'package:woodapp/core/config/env.dart';
import 'package:woodapp/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    EnvConfig.init(Flavor.development);

    await tester.pumpWidget(const WoodApp());
    await tester.pump(const Duration(milliseconds: 2000));

    expect(find.byType(WoodApp), findsOneWidget);
  });
}
