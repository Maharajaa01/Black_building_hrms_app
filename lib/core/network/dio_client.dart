import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/env.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Single configured Dio instance for the entire app.
class DioClient {
  DioClient(this._dio);

  final Dio _dio;

  Dio get raw => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _wrap(() => _dio.get<T>(path, queryParameters: queryParameters, options: options));
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _wrap(() => _dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  Future<Response<T>> put<T>(String path, {Object? data}) async {
    return _wrap(() => _dio.put<T>(path, data: data));
  }

  Future<Response<T>> delete<T>(String path) async {
    return _wrap(() => _dio.delete<T>(path));
  }

  Future<Response<T>> _wrap<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiException _mapDioError(DioException e) {
    final response = e.response;
    final status = response?.statusCode;

    String message = 'Something went wrong. Please try again.';
    String? code;
    Map<String, dynamic>? details;

    final data = response?.data;
    if (data is Map<String, dynamic>) {
      // Frappe shapes errors as { exc_type, exception, _server_messages, message }
      final serverMessages = data['_server_messages'];
      if (serverMessages is String && serverMessages.isNotEmpty) {
        message = _extractFirstServerMessage(serverMessages) ?? message;
      } else if (data['message'] is String) {
        message = data['message'] as String;
      } else if (data['exception'] is String) {
        message = data['exception'] as String;
      }
      code = data['exc_type'] as String?;
      details = data;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        message = 'Connection timed out. Check your internet.';
        break;
      case DioExceptionType.connectionError:
        message = 'Unable to reach the server. Check your network.';
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        break;
      case DioExceptionType.badResponse:
        if (status == 401 || status == 403) {
          message = 'Your session has expired. Please log in again.';
        } else if (status == 404) {
          message = 'The requested resource was not found.';
        } else if (status != null && status >= 500) {
          message = 'Server error ($status). Please try again later.';
        }
        break;
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        break;
    }

    return ApiException(
      message: message,
      statusCode: status,
      code: code,
      details: details,
    );
  }

  /// Frappe encodes `_server_messages` as a JSON string of JSON strings.
  /// Pull the first user-facing message out of it.
  String? _extractFirstServerMessage(String raw) {
    try {
      final decoded = raw.replaceAll(r'\"', '"');
      final start = decoded.indexOf('"message":');
      if (start == -1) return null;
      final fragment = decoded.substring(start + 11);
      final end = fragment.indexOf('"');
      if (end == -1) return null;
      return fragment.substring(0, end).trim();
    } catch (_) {
      return null;
    }
  }
}

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: <String, String>{
        'X-Requested-With': 'XMLHttpRequest',
      },
    ),
  );

  dio.interceptors.add(AuthInterceptor(storage));

  if (kDebugMode && !Env.isProd) {
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: false,
      requestBody: true,
      responseBody: false,
      responseHeader: false,
      compact: true,
      maxWidth: 100,
    ));
  }

  return DioClient(dio);
});
