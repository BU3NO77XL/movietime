import 'dart:io';

import 'package:appflutter/screens/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadRealFonts() async {
  Future<void> loadFamily(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await loadFamily('Inter', [
    'assets/fonts/Inter-Regular.otf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.otf',
  ]);
}

void main() {
  const testProfile = ProfileScreenData(
    id: 7,
    name: 'Ryan Clark',
    email: 'ryan.clark@example.com',
    role: 'client',
    avatarIndex: 1,
    genres: ['Action', 'Drama', 'Sci-Fi'],
    createdAt: '2024-07-12T00:00:00.000Z',
  );

  final sizes = <(String, double, double)>[
    ('design 390x844', 390, 844),
    ('small phone 320x568', 320, 568),
    ('large phone 412x915', 412, 915),
    ('tablet 800x1280', 800, 1280),
    ('small 280x653', 280, 653),
  ];

  setUpAll(loadRealFonts);

  Future<List<String>> pumpAndCollect(
    WidgetTester tester,
    double w,
    double h,
  ) async {
    final collected = <String>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final s = details.exception.toString();
      if (s.contains('overflowed')) {
        collected.add(s.split('\n').first);
      }
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);

    tester.view.physicalSize = Size(w, h);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(
          initialProfile: testProfile,
          useRemoteAvatars: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    while (tester.takeException() != null) {}
    return collected;
  }

  for (final (label, w, h) in sizes) {
    testWidgets('Profile no overflow at $label', (tester) async {
      final errors = await pumpAndCollect(tester, w, h);
      expect(
        errors,
        isEmpty,
        reason: 'Profile overflow at $label\n${errors.join('\n')}',
      );
    });
  }

  testWidgets('Profile edit drawer opens from pencil action', (tester) async {
    final errors = await pumpAndCollect(tester, 390, 844);
    expect(errors, isEmpty);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Edit profile'), findsWidgets);
    expect(find.text('Ryan Clark'), findsWidgets);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsWidgets);
  });

  testWidgets('Profile edit drawer no overflow on small phone', (tester) async {
    final errors = await pumpAndCollect(tester, 320, 568);
    expect(errors, isEmpty);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    while (tester.takeException() != null) {}
    expect(find.text('Edit profile'), findsWidgets);
  });

  testWidgets('Profile avatar menu opens from edit profile photo', (
    tester,
  ) async {
    final errors = await pumpAndCollect(tester, 390, 844);
    expect(errors, isEmpty);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.photo_camera_outlined));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('edit_avatar_menu')), findsOneWidget);
    expect(find.text('Edit avatar'), findsOneWidget);
    expect(find.text('Anime'), findsOneWidget);
    expect(find.text('Emoji'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
  });

  testWidgets('Profile settings icon opens setting page', (tester) async {
    final errors = await pumpAndCollect(tester, 390, 844);
    expect(errors, isEmpty);

    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Setting'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Subscription plan'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });
}
