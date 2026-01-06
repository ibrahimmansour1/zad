import 'package:shared_preferences/shared_preferences.dart';

class Lang {
  static const List<String> values = ["english", "espanol", "portugues", "francais", "filipino"];
  static const defaultLang = 'english';
  static String? _currentLang;
  static Future<String> get() async {
    if (_currentLang != null) {
      return _currentLang!;
    }
    try {
      final sp = await SharedPreferences.getInstance();
      _currentLang = sp.getString('language');
    } catch (e) {
      print(e);
    }
    return _currentLang ?? defaultLang;
  }

  static Future set(String lang) async {
    try {
      final sp = await SharedPreferences.getInstance();
      sp.setString('language', lang);
      _currentLang = lang;
    } catch (e) {
      print(e);
    }
  }
}
