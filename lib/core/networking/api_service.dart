import 'package:dio/dio.dart';
import 'package:retrofit/error_logger.dart';
import 'package:retrofit/http.dart';
import 'package:zad_aldaia/core/networking/api_constants.dart';
import 'package:zad_aldaia/core/networking/translation_request.dart';
import 'package:zad_aldaia/core/networking/translation_response.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: ApiConstants.translateBaseUrl)
abstract class ApiService{

  factory ApiService(Dio dio,{String baseUrl}) = _ApiService;

  @POST("language/translate/v2")
  Future<TranslationResponse> translateText(
      @Body()TranslationRequest request
      );


}