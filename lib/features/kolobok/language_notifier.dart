import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KolobokLanguageNotifier extends StateNotifier<String> {
  KolobokLanguageNotifier() : super('ru') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('language') ?? 'ru';
  }

  Future<void> setLanguage(String lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }
}

final kolobokLanguageProvider = StateNotifierProvider<KolobokLanguageNotifier, String>(
  (ref) => KolobokLanguageNotifier(),
);
