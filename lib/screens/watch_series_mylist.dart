import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WatchSeriesMyListScreen extends StatelessWidget {
  const WatchSeriesMyListScreen({super.key});

  static const _bg = Color(0xFF0D0D0D);
  static const _card = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF525252);
  static const _lightMuted = Color(0xFF9E9E9E);
  static const _primary = Color(0xFFA259FF);
  static const _primaryDark = Color(0xFF562199);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 390;
          final scaledHeight = 844 * scale;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: constraints.maxWidth,
              height: math.max(constraints.maxHeight, scaledHeight),
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: const SizedBox(
                    width: 390,
                    height: 844,
                    child: _WatchSeriesCanvas(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WatchSeriesCanvas extends StatelessWidget {
  const _WatchSeriesCanvas();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const ColoredBox(color: WatchSeriesMyListScreen._bg),
        Positioned(
          left: 0,
          top: 0,
          width: 390,
          height: 548,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/watch_series_mylist/images/rectangle-395047-f352f779.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              const ColoredBox(color: Color(0x330D0D0D)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x000D0D0D),
                      Color(0x080D0D0D),
                      Color(0x220D0D0D),
                      Color(0x520D0D0D),
                      Color(0x920D0D0D),
                      Color(0xD90D0D0D),
                      WatchSeriesMyListScreen._bg,
                    ],
                    stops: [0.0, 0.22, 0.42, 0.62, 0.78, 0.92, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 24,
          top: 306,
          width: 217,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The last of us',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 38 / 28,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Season 2',
                style: TextStyle(
                  color: WatchSeriesMyListScreen._lightMuted,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 24 / 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/watch_series_mylist/icons/star-1-29-622.svg',
                    width: 16,
                    height: 15,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '8.7  .  2025 .  102 min',
                    style: TextStyle(
                      color: WatchSeriesMyListScreen._lightMuted,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 16 / 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Positioned(
          left: 24,
          top: 405,
          width: 342,
          height: 40,
          child: _SeasonHeader(),
        ),
        const Positioned(
          left: 22,
          top: 460,
          width: 342,
          height: 96,
          child: _EpisodeCard(
            image:
                'assets/watch_series_mylist/images/rectangle-395048-957b6c88.png',
            title: 'Stick or twist',
            meta: 'E08 . 49 m',
            progressWidth: 52,
            filled: true,
          ),
        ),
        const Positioned(
          left: 22,
          top: 556,
          width: 342,
          height: 96,
          child: _EpisodeCard(
            image:
                'assets/watch_series_mylist/images/rectangle-395048-09a97061.png',
            title: 'Jigsaw puzzle',
            meta: 'E07 . 49 m',
            progressWidth: 0,
          ),
        ),
        const Positioned(
          left: 22,
          top: 652,
          width: 342,
          height: 96,
          child: _EpisodeCard(
            image:
                'assets/watch_series_mylist/images/rectangle-395048-edd533cd.png',
            title: 'Rat trap',
            meta: 'E07 . 49 m',
            progressWidth: 0,
          ),
        ),
        Positioned(
          left: 24,
          top: 756,
          width: 342,
          height: 50,
          child: _ContinueButton(onTap: () {}),
        ),
      ],
    );
  }
}

class _SeasonHeader extends StatelessWidget {
  const _SeasonHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Episode 8',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            height: 34 / 24,
          ),
        ),
        const Spacer(),
        Container(
          width: 121,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: ShapeDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [WatchSeriesMyListScreen._card, Color(0x330D0D0D)],
            ),
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: Color(0xFF2C2C2C)),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Season 1',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: WatchSeriesMyListScreen._lightMuted,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/watch_series_mylist/icons/icon-i43-587-62-1495-62-1485-1-1270-1007-9365.svg',
                width: 10,
                height: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.image,
    required this.title,
    required this.meta,
    required this.progressWidth,
    this.filled = false,
  });

  final String image;
  final String title;
  final String meta;
  final double progressWidth;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342,
      height: 96,
      padding: const EdgeInsets.all(10),
      decoration: filled
          ? ShapeDecoration(
              color: WatchSeriesMyListScreen._card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            )
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 1, color: Color(0x33FFFFFF)),
              ),
            ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              image,
              width: 115,
              height: 76,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: filled ? 1.5 : 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 22 / 14,
                    ),
                  ),
                  SizedBox(height: filled ? 1 : 5),
                  Text(
                    meta,
                    style: const TextStyle(
                      color: WatchSeriesMyListScreen._muted,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 16 / 12,
                    ),
                  ),
                  if (filled) ...[
                    const SizedBox(height: 11),
                    SizedBox(
                      width: 81,
                      height: 3,
                      child: Stack(
                        children: [
                          Container(
                            width: 81,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.40),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                          Container(
                            width: progressWidth,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  const _ContinueButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerCancel: (_) => setState(() => _pressed = false),
      onPointerUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 50,
          decoration: ShapeDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                WatchSeriesMyListScreen._primary,
                WatchSeriesMyListScreen._primaryDark,
              ],
            ),
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: Color(0xFFC49EFF)),
              borderRadius: BorderRadius.circular(40),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x33A259FF),
                blurRadius: 10,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Continue watching',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 22 / 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
