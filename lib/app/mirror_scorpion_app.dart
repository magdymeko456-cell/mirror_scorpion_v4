import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/language_preferences.dart';
import '../core/speech/elevenlabs_voice_service.dart';
import '../features/home/dashboard_screen.dart';
import 'royal_dark_theme.dart';

class MirrorScorpionApp extends StatelessWidget {
  const MirrorScorpionApp({this.languagePreferences, super.key});

  final LanguagePreferences? languagePreferences;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguagePreferences>.value(
          value: languagePreferences ?? LanguagePreferences(),
        ),
        ChangeNotifierProvider(create: (_) => ElevenLabsVoiceService()),
      ],
      child: Builder(
        builder: (context) {
          final preferences = context.watch<LanguagePreferences>();
          return MaterialApp(
            title: 'Mirror Scorpion v4',
            debugShowCheckedModeBanner: false,
            theme: royalDarkTheme(),
            locale: preferences.deviceLocale,
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}
