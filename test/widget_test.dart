import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'package:woodapp/core/config/env.dart';
import 'package:woodapp/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await GetStorage.init();
    EnvConfig.init(Flavor.development);

    await tester.pumpWidget(const WoodApp());
    await tester.pump();

    expect(find.byType(WoodApp), findsOneWidget);
  });
}
