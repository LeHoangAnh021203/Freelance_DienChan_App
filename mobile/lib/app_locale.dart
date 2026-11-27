import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { vi, en }

const _prefsKey = 'app_language_v1';

final ValueNotifier<AppLanguage> appLanguage = ValueNotifier(AppLanguage.vi);

Future<void> loadAppLanguage() async {
  final preferences = await SharedPreferences.getInstance();
  final raw = preferences.getString(_prefsKey);
  appLanguage.value = raw == 'en' ? AppLanguage.en : AppLanguage.vi;
}

Future<void> setAppLanguage(AppLanguage language) async {
  if (appLanguage.value == language) return;
  appLanguage.value = language;
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(_prefsKey, language == AppLanguage.en ? 'en' : 'vi');
}

Future<void> toggleAppLanguage() async {
  await setAppLanguage(
    appLanguage.value == AppLanguage.vi ? AppLanguage.en : AppLanguage.vi,
  );
}

bool get isEnglish => appLanguage.value == AppLanguage.en;

/// Compact bilingual copy for chrome that already listens to [appLanguage].
String tr(String vi, String en) => isEnglish ? en : vi;
