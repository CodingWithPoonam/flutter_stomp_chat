import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => message;
}

class ApiClient {
  late final Dio dio;

  ApiClient({required SecureStorageService storageService, void Function()? onUnauthorized}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(storageService, onUnauthorized: onUnauthorized),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) {}, // Keep logs clean or pipe to logger
      ),
    );
  }

  ApiException handleError(DioException e) {
    String message = 'An unexpected error occurred';
    if (e.response?.data is Map<String, dynamic>) {
      final map = e.response!.data as Map<String, dynamic>;
      if (map['message'] != null) {
        message = map['message'].toString();
      } else if (map['error'] != null) {
        message = map['error'].toString();
      }
    } else if (e.message != null && e.message!.isNotEmpty) {
      message = e.message!;
    }
    return ApiException(
      message: message,
      statusCode: e.response?.statusCode,
      data: e.response?.data is Map<String, dynamic> ? e.response!.data : null,
    );
  }
}
