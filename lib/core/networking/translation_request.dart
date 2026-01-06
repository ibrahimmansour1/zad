import 'package:json_annotation/json_annotation.dart';

part 'translation_request.g.dart';

@JsonSerializable()
class TranslationRequest{
  final String q;
  final String target;

  TranslationRequest(this.q, this.target);

  Map<String, dynamic> toJson() => _$TranslationRequestToJson(this);

}