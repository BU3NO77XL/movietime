import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appflutter/screens/choose_your_plan.dart';
import 'package:appflutter/screens/highlights.dart';

Future<void> loadRealFonts() async {
  Future<void> loadFamily(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await loadFamily('Poppins', [
    'assets/fonts/Poppins-Regular.ttf',
    'assets/fonts/Poppins-Medium.ttf',
    'assets/fonts/Poppins-SemiBold.ttf',
    'assets/fonts/Poppins-Bold.ttf',
  ]);
  await loadFamily('Inter', ['assets/fonts/Inter-Medium.ttf']);
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
      // Sempre repassa ao handler original do binding para mantê-lo coerente.
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);

    tester.view.physicalSize = Size(w, h);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump(const Duration(milliseconds: 500));

    // Limpa exceções pendentes para o binding não reclamar.
    while (tester.takeException() != null) {}
    return collected;
  }

  for (final (label, w, h) in sizes) {
    testWidgets('Highlights no overflow at $label', (tester) async {
      final errors = await pumpAndCollect(tester, const Highlights(), w, h);
      expect(
        errors,
        isEmpty,
        reason: 'Highlights overflow at $label\n${errors.join('\n')}',
      );
    });
  }

  for (final (label, w, h) in sizes) {
    testWidgets('ControlPlan (reference) overflow at $label', (tester) async {
      final errors = await pumpAndCollect(tester, const ControlPlan(), w, h);
      expect(
        errors,
        isEmpty,
        reason: 'ControlPlan overflow at $label\n${errors.join('\n')}',
      );
    });
  }
}
