import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/language_preferences.dart';
import '../features/home/dashboard_screen.dart';
import 'royal_dark_theme.dart';

class MirrorScorpionApp extends StatelessWidget {
  const MirrorScorpionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languagePreferences = context.watch<LanguagePreferences>();
    return MaterialApp(
      title: 'Mirror Scorpion v4',
      debugShowCheckedModeBanner: false,
      theme: royalDarkTheme(),
      locale: languagePreferences.deviceLocale,
      home: const DashboardScreen(),
    );
  }
}
