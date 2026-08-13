import 'package:appflutter/screens/mylist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(const MaterialApp(home: MyListScreen()));
    await tester.pumpAndSettle();
  }

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('MyList no overflow at design 390x844', (tester) async {
    await pumpAtSize(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('MyList no overflow at small phone 320x568', (tester) async {
    await pumpAtSize(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('MyList no overflow at large phone 412x915', (tester) async {
    await pumpAtSize(tester, const Size(412, 915));
    expect(tester.takeException(), isNull);
  });
}
