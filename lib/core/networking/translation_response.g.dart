// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TranslationResponse _$TranslationResponseFromJson(Map<String, dynamic> json) =>
    TranslationResponse(
      TranslationData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TranslationResponseToJson(
  TranslationResponse instance,
) => <String, dynamic>{'data': instance.data};

TranslationData _$TranslationDataFromJson(Map<String, dynamic> json) =>
    TranslationData(
      (json['translations'] as List<dynamic>)
          .map((e) => TranslatedText.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TranslationDataToJson(TranslationData instance) =>
    <String, dynamic>{'translations': instance.translations};

TranslatedText _$TranslatedTextFromJson(Map<String, dynamic> json) =>
    TranslatedText(json['translatedText'] as String);

Map<String, dynamic> _$TranslatedTextToJson(TranslatedText instance) =>
    <String, dynamic>{'translatedText': instance.translatedText};
