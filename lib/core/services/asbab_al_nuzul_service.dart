import 'package:flutter/foundation.dart';

class QuranStoryItem {
  final String title;
  final String surah;
  final int ayah;
  final String text;
  final String soundEffect;

  const QuranStoryItem({
    required this.title,
    required this.surah,
    required this.ayah,
    required this.text,
    required this.soundEffect,
  });
}

class AsbabAlNuzulService extends ChangeNotifier {
  final List<QuranStoryItem> _stories = const [
    QuranStoryItem(
      title: 'سبب نزول سورة الفيل',
      surah: 'الفيل',
      ayah: 1,
      text: 'نزلت في قصة أصحاب الفيل وأبرهة الأشرم وعناية الله بالبيت الحرام.',
      soundEffect: 'wind_sand',
    ),
    QuranStoryItem(
      title: 'سبب نزول سورة الكوثر',
      surah: 'الكوثر',
      ayah: 1,
      text: 'نزلت رداً على العاص بن وائل السهمي لما قال عن النبي ﷺ إنه أبتر.',
      soundEffect: 'sea_waves',
    ),
  ];

  List<QuranStoryItem> get stories => List.unmodifiable(_stories);

  QuranStoryItem? findBySurah(String surahName) {
    try {
      return _stories.firstWhere((s) => s.surah == surahName);
    } catch (_) {
      return null;
    }
  }
}
