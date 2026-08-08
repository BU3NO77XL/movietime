import 'package:flutter/material.dart';

import 'screens/intro.dart';

void main() {
  runApp(const MovieTimeApp());
}

class MovieTimeApp extends StatelessWidget {
  const MovieTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieTime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5CE1E6),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Poppins',
      ),
      home: const Intro(),
    );
  }
}