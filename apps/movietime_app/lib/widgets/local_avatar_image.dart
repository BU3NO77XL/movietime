import 'package:flutter/material.dart';

import '../services/avatar_catalog.dart';

class LocalAvatarImage extends StatelessWidget {
  const LocalAvatarImage({
    required this.avatarIndex,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    super.key,
  });

  final int avatarIndex;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final safeIndex = avatarIndex.clamp(0, totalAvatars - 1).toInt();
    return Image.asset(
      localAvatarAsset(safeIndex),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => Container(
        width: width,
        height: height,
        color: const Color(0xFF1A1A1A),
        child: const Icon(Icons.person_rounded, color: Colors.white54),
      ),
    );
  }
}
