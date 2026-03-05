import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ValueNotifier<Locale> {
  LanguageController._() : super(const Locale('en'));

  static final LanguageController instance = LanguageController._();

  String get currentLanguage {
    switch (value.languageCode) {
      case 'om':
        return 'Afan Oromo';
      case 'am':
        return 'Amharic';
      default:
        return 'English';
    }
  }

  Future<void> setLanguage(String languageCode) async {
    value = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code');
    if (code != null) {
      value = Locale(code);
    }
  }
}
