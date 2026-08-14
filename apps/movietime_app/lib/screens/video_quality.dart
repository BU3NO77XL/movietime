import 'package:flutter/material.dart';

class VideoQualityScreen extends StatefulWidget {
  const VideoQualityScreen({super.key});

  static const bg = Color(0xFF0D0D0D);
  static const card = Color(0xFF1A1A1A);
  static const border = Color(0xFF262626);
  static const muted = Color(0xFF525252);
  static const lightMuted = Color(0xFF9E9E9E);

  @override
  State<VideoQualityScreen> createState() => _VideoQualityScreenState();
}

class _VideoQualityScreenState extends State<VideoQualityScreen> {
  int _wifiQuality = 2;
  int _mobileQuality = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VideoQualityScreen.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 42, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Video quality',
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
              const SizedBox(height: 63),
              _QualitySection(
                title: 'Wi-Fi streaming',
                selectedIndex: _wifiQuality,
                onSelect: (index) => setState(() => _wifiQuality = index),
              ),
              const Divider(
                height: 60,
                thickness: 1,
                color: VideoQualityScreen.card,
              ),
              _QualitySection(
                title: 'Mobile streaming',
                selectedIndex: _mobileQuality,
                onSelect: (index) => setState(() => _mobileQuality = index),
              ),
              const SizedBox(height: 70),
              const _DataNotice(),
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
            colors: [VideoQualityScreen.card, Color(0x330D0D0D)],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Icon(
          Icons.chevron_left_rounded,
          color: VideoQualityScreen.lightMuted,
          size: 30,
        ),
      ),
    );
  }
}

class _QualitySection extends StatelessWidget {
  const _QualitySection({
    required this.title,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String title;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _labels = ['Low', 'Medium', 'High'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.57,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 40,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gap = constraints.maxWidth < 330 ? 10.0 : 20.0;
              final buttonWidth = (constraints.maxWidth - gap * 2) / 3;

              return Row(
                children: [
                  for (var index = 0; index < _labels.length; index++) ...[
                    SizedBox(
                      width: buttonWidth,
                      child: _QualityButton(
                        label: _labels[index],
                        selected: selectedIndex == index,
                        onTap: () => onSelect(index),
                      ),
                    ),
                    if (index < _labels.length - 1) SizedBox(width: gap),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QualityButton extends StatelessWidget {
  const _QualityButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: ShapeDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFA259FF), Color(0xFF562199)],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [VideoQualityScreen.card, Color(0x330D0D0D)],
                ),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: selected ? Colors.transparent : VideoQualityScreen.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : VideoQualityScreen.lightMuted,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.57,
            ),
          ),
        ),
      ),
    );
  }
}

class _DataNotice extends StatelessWidget {
  const _DataNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Icon(
          Icons.info_outline_rounded,
          color: VideoQualityScreen.muted,
          size: 20,
        ),
        SizedBox(width: 20),
        Expanded(
          child: Text(
            'Streaming higher video quality over a mobile\ndata connection will use more data.',
            style: TextStyle(
              color: VideoQualityScreen.muted,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.57,
            ),
          ),
        ),
      ],
    );
  }
}
