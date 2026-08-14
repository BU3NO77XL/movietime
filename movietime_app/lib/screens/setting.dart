import 'package:flutter/material.dart';

import 'screen_transitions.dart';
import 'video_quality.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  static const _bg = Color(0xFF0D0D0D);
  static const _card = Color(0xFF1A1A1A);
  static const _divider = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF525252);
  static const _danger = Color(0xFFFF4C61);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 42, 24, 0),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _BackButton(
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    const Text(
                      'Setting',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 75),
              const _SettingList(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SettingScreen._card, Color(0x330D0D0D)],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Icon(
          Icons.chevron_left_rounded,
          color: Color(0xFF9E9E9E),
          size: 30,
        ),
      ),
    );
  }
}

class _SettingList extends StatelessWidget {
  const _SettingList();

  static const _items = [
    'Account',
    'Subscription plan',
    'Notifications',
    'Quality',
    'About',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in _items)
          _SettingRow(
            label: item,
            showChevron: true,
            showDivider: true,
            onTap: item == 'Quality'
                ? () {
                    Navigator.of(
                      context,
                    ).push(cinematicPageRoute(const VideoQualityScreen()));
                  }
                : null,
          ),
        const _SettingRow(
          label: 'Log out',
          color: SettingScreen._danger,
          showChevron: false,
          showDivider: false,
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.showChevron,
    required this.showDivider,
    this.onTap,
    this.color = Colors.white,
  });

  final String label;
  final bool showChevron;
  final bool showDivider;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 61,
        decoration: BoxDecoration(
          border: Border(
            bottom: showDivider
                ? const BorderSide(color: SettingScreen._divider, width: 1)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.57,
                ),
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                color: SettingScreen._muted,
                size: 30,
              ),
          ],
        ),
      ),
    );
  }
}
