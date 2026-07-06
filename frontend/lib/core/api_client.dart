import 'package:dio/dio.dart';
import 'package:frontend/core/constants.dart';
import 'package:frontend/core/secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  ApiException({required this.message, this.statusCode, this.code});

  @override
  String toString() => message;
}

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: Constants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          await SecureStorage.clearToken();
          // The UI or AuthProvider should ideally redirect to login,
          // but clearing token ensures they are unauthenticated.
        }
        
        String errorMessage = 'An unexpected error occurred';
        String? errorCode;
        
        if (e.response?.data != null && e.response!.data is Map) {
          final errorData = e.response!.data['error'];
          if (errorData != null && errorData is Map) {
            errorMessage = errorData['message'] ?? errorMessage;
            errorCode = errorData['code'];
          }
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timed out';
        }

        return handler.next(DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: e.type,
          error: ApiException(
            message: errorMessage,
            statusCode: e.response?.statusCode,
            code: errorCode,
          ),
        ));
      },
    ));
  }

  Dio get dio => _dio;
}
