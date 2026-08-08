# Motion Blur Carousel on Intro2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the static 3-poster `Stack` (390×220) inside `Intro2` with a looping horizontal reel of the same 3 posters that slides continuously with a real GPU **motion blur** (shader-based), preserving the current visual style (curved clippers, dark overlays, raised center poster).

**Architecture:** The carousel becomes its own `StatefulWidget` (`_CarouselReel`) nested inside the still-`StatelessWidget` `Intro2`. It owns a single `AnimationController.repeat()` (value 0..1, 9s). Each frame a horizontal shift is derived: `shift = value * _cycleWidth`. A fan of 6 posters — the 3 unique posters twice (`kind = i % 3`, i in 0..5) — is laid out at uniform slot centers spaced `_slotWidth`; because the image pattern repeats every 3 slots, sliding exactly `_cycleWidth = 3 * _slotWidth` returns an identical picture (seamless wrap). Each poster is wrapped in `MotionBlur` (shader samples the frame delta and renders directional blur) with horizontal `Padding` so the shader's bleed is not clipped. Overlay alpha per poster is derived from its current distance to the window center (195 px), recreating the design's 0 / 0.4 / 0.5 shading.

**Tech Stack:** Flutter SDK 3.44.8 (Dart 3.12.2), `motion_blur: ^0.0.2`, transitive `flutter_shaders 0.1.3`. Assets: `assets/images/rectangle-39504{3,4,5}-*.png`.

## Global Constraints

- Design frame 390×844; carousel lives at (x=0, y=202) inside a 390×220 clip box.
- Current poster geometry in `Intro2` (frame coords) — DO NOT lose the exact sizes/offsets:
  - Left (Rectangle 395045, `rectangle-395045-fc8f71de.png`): x=-333.96, y=0, 352.25×220, overlay alpha 0.4
  - Center (Rectangle 395043, `rectangle-395043-573e42d4.png`): x=33.29, y=9, 323.43×202, overlay alpha 0.0
  - Right (Rectangle 395044, `rectangle-395044-cd287cf5.png`): x=371.71, y=0, 352.25×220, overlay alpha 0.5
- See `_CarouselImage` / `_CurvedPosterClipper` remain untouched (curved top/bottom edges preserved).
- `Intro2` stays `StatelessWidget`; the animation lives in the nested `_CarouselReel` `StatefulWidget`.
- Add a `debugDisableBlur` constructor toggle on `Intro2` propagated to the reel `noBlur`, so `flutter test` does not depend on the GLSL shader asset.
- `MotionBlur` requires its wrapper's global position to actually change each frame to compute a delta → posters must be recomputed through an `AnimatedBuilder` reading `_controller.value` (slide the `Positioned.left`), NOT a static transform.
- Must keep `flutter analyze` at zero issues and the test suite green.

## Reference geometry (design → slot)

Center-to-center spacing in the design: center poster center is at x=195; side poster centers at 195 ± 352.84. So:

- `_slotWidth = 352.84`
- For poster i (0..5), `kind = i % 3` (0=square/left,1=center,2=square/right)
- Poster left: `left_i = 33.29 + i * _slotWidth - shift`
- Poster top: straight from `_rects[kind].top` (0, 9, 0)
- Poster center x: `cx = left_i + _rects[kind].width / 2`
- Overlay: `overlay = 0.5 * ((|cx - 195| / 176).clamp(0,1))` → center≈0, edges≈0.5. (Design is expressive; exact 0.4 vs 0.5 tune in Task 3.)

---

### Task 1: Register motion_blur shader and verify build

**Files:**
- Modify: `pubspec.yaml`
- Test: `test/widget_test.dart` (must keep passing, no edits now)

**Interfaces:**
- Consumes: nothing.
- Produces: asset key `packages/motion_blur/shaders/motion_blur.glsl` resolved at runtime by `MotionBlur` via `ShaderBuilder(assetKey: ...)`.

- [ ] **Step 1: Add the shader to pubspec**

Edit `pubspec.yaml`. Inside the `flutter:` section, immediately after `uses-material-design: true`:

```yaml
flutter:
  uses-material-design: true

  shaders:
    - packages/motion_blur/shaders/motion_blur.glsl

  assets:
```

(`flutter pub add motion_blur` already appended `motion_blur: ^0.0.2` at line 38.)

- [ ] **Step 2: Resolve**

Run: `flutter pub get`
Expected: resolves with no errors.

- [ ] **Step 3: Verify**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Existing smoke test**

Run: `flutter test test/widget_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build: register motion_blur shader"
```

> Note: this folder is not a git repo yet. If `git status` errors, run `git init` first (or skip the commit and note it).

---

### Task 2: Implement `_CarouselReel` with `MotionBlur`

**Files:**
- Modify: `lib/screens/intro2.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `IntroLogoMark`/`MovieTimeLabel` (untouched), `_CarouselImage` and `_CurvedPosterClipper` (existing at bottom of file, unchanged signature), the three asset paths.
- Produces:
  - `Intro2({ bool debugDisableBlur = false })` — new const constructor param forwarded to the reel.
  - `class _MotionCarousel extends StatelessWidget { const _MotionCarousel({required this.noBlur}); final bool noBlur; }` — thin bridge.
  - `class _CarouselReel extends StatefulWidget { const _CarouselReel({required this.noBlur}); final bool noBlur; }` — owns the controller.
  - `class _CarouselReelState extends State<_CarouselReel> with SingleTickerProviderStateMixin`
  - Helpers `Widget _poster(int i, double value)` and `double _overlayFor(int i, double value)`.
  - `ValueKey('carousel-post-$i')` on each `Positioned` (used by tests).

- [ ] **Step 1: Write the failing widget test**

Rewrite `test/widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appflutter/main.dart';
import 'package:appflutter/screens/intro2.dart';

void main() {
  testWidgets('Intro renders MovieTime', (tester) async {
    await tester.pumpWidget(const MovieTimeApp());
    expect(find.text('MovieTime'), findsOneWidget);
  });

  testWidgets('carousel posters slide continuously', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 844,
            child: Intro2(debugDisableBlur: true),
          ),
        ),
      ),
    );
    await tester.pump();

    final key0 = const ValueKey('carousel-post-0');
    final before = tester.getTopLeft(find.byKey(key0));

    await tester.pump(const Duration(seconds: 1));

    final after = tester.getTopLeft(find.byKey(key0));
    expect(after.dx, isNot(closeTo(before.dx, 0.1)));
  });
}
```

Run: `flutter test test/widget_test.dart`
Expected: FAIL (compile error: `Intro2` has no `debugDisableBlur`; `carousel-post-0` not found).

- [ ] **Step 2: Implement**

In `lib/screens/intro2.dart`:

(a) Add import at top, after `import 'signup.dart';`:

```dart
import 'package:motion_blur/motion_blur.dart';
```

(b) Change the `Intro2` class:

```dart
class Intro2 extends StatelessWidget {
  const Intro2({super.key, this.debugDisableBlur = false});

  final bool debugDisableBlur;
  ...
```

(c) Replace the carousel block — currently the `Positioned(left:…, top:…, Transform.scale ... SizedBox(390×220)/Stack` with three static `_CarouselImage` children — with:

```dart
// Carrousel de filmes com motion blur (Frame 2147224303, x=0, y=202, 390×220)
Positioned(
  left: transform.mapX(0),
  top: transform.mapY(202),
  child: Transform.scale(
    scale: transform.scale,
    alignment: Alignment.topLeft,
    child: _MotionCarousel(noBlur: debugDisableBlur),
  ),
),
```

(d) add the classes after `_Intro2State` (or near `_CarouselImage`). Full code:

```dart
/// Bridge que constrói o carrossel animado com blur.
class _MotionCarousel extends StatelessWidget {
  const _MotionCarousel({required this.noBlur});

  final bool noBlur;

  @override
  Widget build(BuildContext context) {
    return _CarouselReel(noBlur: noBlur);
  }
}

/// Rolha horizontal de 3 pôsters em rotação contínua com motion blur.
class _CarouselReel extends StatefulWidget {
  const _CarouselReel({required this.noBlur});

  final bool noBlur;

  @override
  State<_CarouselReel> createState() => _CarouselReelState();
}

class _CarouselReelState extends State<_CarouselReel>
    with SingleTickerProviderStateMixin {
  static const double _slotWidth = 352.84;
  static const double _cycleWidth = _slotWidth * 3;
  static const double _windowCenter = 195.0;
  static const double _reach = 176.0;

  static const List<String> _assets = <String>[
    'assets/images/rectangle-395045-fc8f71de.png', // left
    'assets/images/rectangle-395043-573e42d4.png', // center
    'assets/images/rectangle-395044-cd287cf5.png', // right
  ];

  static const List<Rect> _rects = <Rect>[
    Rect.fromLTWH(0, 0, 352.25, 220), // side
    Rect.fromLTWH(0, 9, 323.43, 202), // center (raised)
    Rect.fromLTWH(0, 0, 352.25, 220), // side
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        final shift = value * _cycleWidth;
        final base = 33.29 - shift;
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < 6; i++)
                Positioned(
                  key: ValueKey('carousel-post-$i'),
                  left: base + i * _slotWidth,
                  top: _rects[i % 3].top,
                  child: _poster(i),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _poster(int i) {
    final kind = i % 3;
    final rect = _rects[kind];
    final child = _CarouselImage(
      image: _assets[kind],
      width: rect.width,
      height: rect.height,
      overlayOpacity: _overlayFor(i),
    );
    if (widget.noBlur) return child;
    return RepaintBoundary(
      child: MotionBlur(
        intensity: 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: child,
        ),
      ),
    );
  }

  double _overlayFor(int i) {
    final rect = _rects[i % 3];
    final cx = 33.29 + i * _slotWidth - _controller.value * _cycleWidth + rect.width / 2;
    final d = (cx - _windowCenter).abs() / _reach;
    final t = d.clamp(0.0, 1.0);
    return 0.5 * t;
  }
}
```

Notes:
- `base = 33.29 - shift` positions poster 1 (center kind) at the design's center x at t=0.
- The `MotionBlur` wrapper sits inside the moving `Positioned`, so its own `RenderBox` moves; the shader measures the delta and blurs.
- `ClipRect` keeps the reel to 390×220 as before.
- Remove the formerly static three `Positioned` carousel children (retain the `Stack` replaced wholly by `_MotionCarousel`).

- [ ] **Step 3: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS (both).

- [ ] **Step 4: analyze**

Run: `flutter analyze`
Expected: `No issues found!` (exclude lint only in catch if flutter_shaders emits deprecation warnings — verify they’re transitive not ours.)

- [ ] **Step 5: Manual visual check**

Run: `flutter run -d windows` (or chosen device). Verify:
  - Posters glide smoothly left→right→? (they scroll leftward, enter from right) — infinite.
  - Blur trails visible during slide (not a hard jump).
  - At any moment one poster ~brightest about x=195, others dimmed toward edges.
  - No visible seam at the loop wrap (`t=1 → t=0`).
  - Text/logo/buttons below unaffected.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/intro2.dart test/widget_test.dart
git commit -m "feat(intro2): looping motion-blur carousel"
```

---

### Task 3: Polish overlay ramp and confirm zero issues

**Files:**
- Modify: `lib/screens/intro2.dart` (only `_overlayFor`; optionally `_reach`, `_slotWidth`)

**Interfaces:**
- Consumes: Task 2 produce `_overlayFor`, `_rects`, `_controller`.
- Produces: final overlay curve matching the design signature.

- [ ] **Step 1: Review**

The current formula `0.5 * clamp(|cx-195|/176,0,1)` yields side alphas ≈0.5 for both kinds. The mock-fidelity behind `_CarouselImage`.: left=0.4, right=0.5. Decide in visual: if both sides look equal, implement:

```dart
double _overlayFor(int i) {
  final kind = i % 3;
  final rect = _rects[kind];
  final cx = 33.29 + i * _slotWidth - _controller.value * _cycleWidth + rect.width / 2;
final d = (cx - _windowCenter).abs() / _reach;
    final t = d.clamp(0.0, 1.0);
    final max = kind == 2 ? 0.4 : 0.5;
  return max * t;
}
```

(center stays 0 by the clamp reach because `cx` near 195 → t≈0.)

- [ ] **Step 2: Visual reconfirm**

Run: `flutter run -d windows`
Check both darkening and wrap continuity. Optionally slow to `Duration(seconds: 12)` for review, restore 9s after.

- [ ] **Step 3: Full verification**

Run: `flutter analyze && flutter test`
Expected: analyze clean; tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/intro2.dart
git commit -m "refactor(intro2): tune carousel overlay ramp"
```

---

## Self-Review

- **Spec coverage:** shader registration (T1); stateful reel + `repeat()` + styling preserved + loop seamless (T2); overlay tune to 0.4/0.5 (T3); all in Global Constraints.
- **Placeholder scan:** all steps contain real code; no TBD/TODO/similar-to-task stubs.
- **Type/name consistency:** `Intro2.debugDisableBlur` → `_MotionCarousel(noBlur:)` → `_CarouselReel(noBlur:)` — consistent in every snippet; `_poster(i)`, `_overlayFor(i)`, `ValueKey('carousel-post-$i')`, `_CarouselImage(image,width,height,overlayOpacity)` names match task to task.
- **Risk:** `flutter_shaders 0.1.3` is a legacy transitive dep; compile-gated in T1/T2 and `noBlur` isolates tests. Web perf caveat from readme (not target platform).

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-07-motion-blur-carousel.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — execute tasks in this session with checkpoints.

Which approach?