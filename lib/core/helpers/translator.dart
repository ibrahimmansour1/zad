import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/networking/api_service.dart';
import 'package:zad_aldaia/core/networking/translation_request.dart';

class Translator {
  static Future<String?> text(text, language) async {
    try {
      var response = await getIt<ApiService>().translateText(TranslationRequest(text, language));
      return response.data.translations.first.translatedText;
    } catch (e) {
      return null;
    }
  }
}
