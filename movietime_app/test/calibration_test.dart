import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appflutter/screens/choose_your_plan.dart';

void main() {
  final sizes = <(String, double, double)>[
    ('design 390x844', 390, 844),
    ('small phone 320x568', 320, 568),
    ('large phone 412x915', 412, 915),
    ('tablet 800x1280', 800, 1280),
    ('small 280x653', 280, 653),
  ];

  for (final (label, w, h) in sizes) {
    testWidgets('Highlights no overflow at $label', (tester) async {
      tester.view.physicalSize = Size(w, h);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: const ControlPlan()));
      await tester.pump(const Duration(milliseconds: 500));

      final overflowMessages = <String>[];
      dynamic exception;
      while ((exception = tester.takeException()) != null) {
        final s = exception.toString();
        if (s.contains('overflowed') || s.contains('RenderFlex')) {
          overflowMessages.add(s);
        }
      }

      expect(overflowMessages, isEmpty,
          reason: 'Overflow at $label\n${overflowMessages.join('\n---\n')}');
    });
  }
}
