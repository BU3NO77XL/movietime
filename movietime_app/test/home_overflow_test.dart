import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appflutter/screens/home.dart';

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
    Widget screen,
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

    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump(const Duration(milliseconds: 500));

    while (tester.takeException() != null) {}
    return collected;
  }

  for (final (label, w, h) in sizes) {
    testWidgets('Home no overflow at $label', (tester) async {
      final errors = await pumpAndCollect(tester, const Home(), w, h);
      expect(
        errors,
        isEmpty,
        reason: 'Home overflow at $label\n${errors.join('\n')}',
      );
    });
  }
}