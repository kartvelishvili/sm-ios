import 'dart:async';
import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../services/storage_service.dart';

/// Callback that the app can register to force-logout on 401
typedef OnUnauthorized = void Function();

class ApiClient {
  late final Dio _dio;
  final StorageService _storage;
  OnUnauthorized? onUnauthorized;

  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(seconds: AppConstants.receiveTimeout),
      headers: {
        'X-API-Key': AppConstants.apiKey,
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(_AuthInterceptor(_storage, this));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  // --- GET ---
  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return ApiResponse.fromDioResponse(response);
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  // --- POST (JSON) ---
  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return ApiResponse.fromDioResponse(response);
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  // --- POST (Multipart) ---
  Future<ApiResponse> upload(
    String path, {
    required FormData formData,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponse.fromDioResponse(response);
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }
}

// --- Auth Interceptor ---
class _AuthInterceptor extends Interceptor {
  final StorageService _storage;
  final ApiClient _client;

  _AuthInterceptor(this._storage, this._client);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid — trigger logout
      _storage.clearAll();
      _client.onUnauthorized?.call();
    }
    handler.next(err);
  }
}

// --- Unified API Response ---
class ApiResponse {
  final bool success;
  final String? message;
  final dynamic data;
  final List<String>? errors;
  final Map<String, dynamic>? pagination;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.pagination,
    this.statusCode = 200,
  });

  factory ApiResponse.fromDioResponse(Response response) {
    final body = response.data as Map<String, dynamic>? ?? {};
    return ApiResponse(
      success: body['success'] == true,
      message: body['message'] as String?,
      data: body['data'],
      errors: (body['errors'] as List?)?.cast<String>(),
      pagination: body['pagination'] as Map<String, dynamic>?,
      statusCode: response.statusCode ?? 200,
    );
  }

  factory ApiResponse.fromDioError(DioException error) {
    final body = error.response?.data;
    if (body is Map<String, dynamic>) {
      return ApiResponse(
        success: false,
        message: body['message'] as String? ?? 'კავშირის შეცდომა',
        errors: (body['errors'] as List?)?.cast<String>(),
        statusCode: error.response?.statusCode ?? 0,
      );
    }
    return ApiResponse(
      success: false,
      message: _getErrorMessage(error),
      statusCode: error.response?.statusCode ?? 0,
    );
  }

  static String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'კავშირი ვერ მოხერხდა. სცადეთ მოგვიანებით.';
      case DioExceptionType.connectionError:
        return 'ინტერნეტ კავშირი არ არის.';
      default:
        return 'დაფიქსირდა შეცდომა. სცადეთ მოგვიანებით.';
    }
  }
}
