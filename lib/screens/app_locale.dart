import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kLangCodeKey = 'lang_code';

// Default: English
final ValueNotifier<Locale> localeNotifier =
    ValueNotifier<Locale>(const Locale('en'));

Future<void> loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString(kLangCodeKey) ?? 'en';
  localeNotifier.value = Locale(code);
}

Future<void> setAppLocale(String languageCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kLangCodeKey, languageCode);
  localeNotifier.value = Locale(languageCode);
}