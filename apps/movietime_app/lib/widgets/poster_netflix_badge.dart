import 'package:flutter/material.dart';

import '../services/netflix_cache.dart';

class PosterNetflixBadge extends StatelessWidget {
  const PosterNetflixBadge({
    super.key,
    required this.tmdbId,
    required this.mediaType,
  });

  final int tmdbId;
  final String mediaType;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: NetflixCache.isOnNetflix(tmdbId, mediaType),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return const Positioned(
          top: 6,
          left: 6,
          child: SizedBox(
            width: 14,
            height: 18,
            child: Image(
              image: AssetImage('assets/watch/images/netflix-n-logo.png'),
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}
