import 'package:flutter/material.dart';

import '../features/home/dashboard_screen.dart';
import 'royal_dark_theme.dart';

class MirrorScorpionApp extends StatelessWidget {
  const MirrorScorpionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mirror Scorpion v4',
      debugShowCheckedModeBanner: false,
      theme: royalDarkTheme(),
      home: const DashboardScreen(),
    );
  }
}
