import 'package:appflutter/screens/see_all_mylist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(const MaterialApp(home: SeeAllMyListScreen()));
    await tester.pumpAndSettle();
  }

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('See all my list no overflow at design 390x844', (tester) async {
    await pumpAtSize(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('See all my list no overflow at small phone 320x568', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('See all my list no overflow at large phone 412x915', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(412, 915));
    expect(tester.takeException(), isNull);
  });

  testWidgets('See all my list filters open contextual popovers', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(390, 844));

    await tester.tap(find.text('G\u00EAnero'));
    await tester.pumpAndSettle();
    expect(find.text('A\u00E7\u00E3o'), findsOneWidget);
    await tester.tap(find.text('A\u00E7\u00E3o'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('A\u00E7\u00E3o', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    expect(find.text('2024'), findsWidgets);
    await tester.tap(find.text('2024').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Year:', findRichText: true), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('see_all_filter_scroll')),
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rate'));
    await tester.pumpAndSettle();
    expect(find.text('Mais avaliados'), findsOneWidget);
    await tester.tap(find.text('Top trending'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('see_all_filter_scroll')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(320, 132));
    await tester.pumpAndSettle();
    expect(find.text('Portugu\u00EAs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('See all my list search overlay opens and filters results', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(390, 844));

    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Results'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Severance');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('search_result_Severance')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('search_result_You')), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Search'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
