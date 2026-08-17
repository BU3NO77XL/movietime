import 'package:flutter/material.dart';

class NetflixBadge extends StatelessWidget {
  const NetflixBadge({super.key, this.showSeries = false});

  final bool showSeries;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: showSeries ? 100 : 14,
      height: 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 26,
            child: Image(
              image: AssetImage('assets/watch/images/netflix-n-logo.png'),
              fit: BoxFit.fill,
            ),
          ),
          if (showSeries) ...[const SizedBox(width: 8), const SeriesBadge()],
        ],
      ),
    );
  }
}

class SeriesBadge extends StatelessWidget {
  const SeriesBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 78,
      height: 26,
      child: Center(
        child: DefaultTextStyle(
          style: TextStyle(
            color: Color(0xFFB7B7B7),
            fontSize: 15,
            height: 1,
            fontFamily: 'Netflix Sans',
            fontWeight: FontWeight.w700,
            letterSpacing: 3.6,
          ),
          child: Text('SÉRIES', maxLines: 1, softWrap: false),
        ),
      ),
    );
  }
}
