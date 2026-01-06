import 'package:json_annotation/json_annotation.dart';

part 'translation_response.g.dart';

@JsonSerializable()
class TranslationResponse {
  final TranslationData data;

  TranslationResponse(this.data);
  factory TranslationResponse.fromJson(Map<String, dynamic> json) => _$TranslationResponseFromJson(json);
}

@JsonSerializable()
class TranslationData {
  final List<TranslatedText> translations;

  TranslationData(this.translations);

  factory TranslationData.fromJson(Map<String, dynamic> json) => _$TranslationDataFromJson(json);

}

@JsonSerializable()
class TranslatedText {
  final String translatedText;

  TranslatedText(this.translatedText);

  factory TranslatedText.fromJson(Map<String, dynamic> json) => _$TranslatedTextFromJson(json);
}
