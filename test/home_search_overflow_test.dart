import 'package:appflutter/screens/home_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(const MaterialApp(home: HomeSearchScreen()));
    await tester.pumpAndSettle();
  }

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('Home search no overflow at design 390x844', (tester) async {
    await pumpAtSize(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home search no overflow at small phone 320x568', (tester) async {
    await pumpAtSize(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home search filters by query and category', (tester) async {
    await pumpAtSize(tester, const Size(390, 844));

    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Artists, Films, Tv shows ...'), findsOneWidget);

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('Series'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home_search_settings_filter')));
    await tester.pumpAndSettle();
    expect(find.text('Choose category'), findsOneWidget);
    expect(find.text('Sci-Fi'), findsOneWidget);
    await tester.tap(find.text('Sci-Fi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Movies'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();
    expect(find.text('List'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Dune');
    await tester.pumpAndSettle();

    expect(find.text('No results found'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
