import 'package:dio/dio.dart';
import 'package:zad_aldaia/core/networking/api_constants.dart';

class DioFactory {

  DioFactory._();

  static Dio? _dio;

  static Dio getDio() {
    if (_dio == null) {
      _dio = Dio()
        ..options.connectTimeout = Duration(seconds: 30)
        ..options.receiveTimeout = Duration(seconds: 30)
        ..interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) {
            options.queryParameters.addAll({
              'key': ApiConstants.translateApiKey,
            });
            return handler.next(options);
          },
        ))
      ;

      return _dio!;
    }
    else {
      return _dio!;
    }
  }

}