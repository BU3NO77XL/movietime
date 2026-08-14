import 'package:appflutter/screens/my_list_state.dart';
import 'package:appflutter/screens/watch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(const MaterialApp(home: WatchScreen()));
    await tester.pumpAndSettle();
  }

  tearDown(() {
    MyListState.hasCreatedList = false;
    MyListState.listName = MyListState.defaultName;

    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('Watch no overflow at design 390x844', (tester) async {
    await pumpAtSize(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Watch no overflow at small phone 320x568', (tester) async {
    await pumpAtSize(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Watch no overflow at large phone 412x915', (tester) async {
    await pumpAtSize(tester, const Size(412, 915));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Watch save button toggles filled bookmark', (tester) async {
    await pumpAtSize(tester, const Size(390, 844));

    expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
    await tester.tap(find.byKey(const ValueKey('watch-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Give your new list a name'), findsOneWidget);
    expect(find.text(MyListState.defaultName), findsOneWidget);

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
