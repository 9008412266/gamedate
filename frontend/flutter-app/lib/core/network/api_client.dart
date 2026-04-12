import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Dio HTTP client with JWT interceptor, token refresh, and error handling.
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  final Logger _logger = Logger();

  static const String _accessTokenKey  = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  ApiClient._({required String baseUrl, required FlutterSecureStorage storage})
      : _storage = storage {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  factory ApiClient({required String baseUrl, required FlutterSecureStorage storage}) {
    _instance ??= ApiClient._(baseUrl: baseUrl, storage: storage);
    return _instance!;
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },

        onError: (error, handler) async {
          // Auto-refresh on 401
          if (error.response?.statusCode == 401) {
            try {
              final refreshed = await _refreshToken();
              if (refreshed) {
                // Retry the original request
                final token = await _storage.read(key: _accessTokenKey);
                error.requestOptions.headers['Authorization'] = 'Bearer $token';
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            } catch (_) {
              // Refresh failed — redirect to login
              await _clearTokens();
            }
          }
          handler.next(error);
        },
      ),
    );

    // Request/response logging in debug mode
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => _logger.d(obj),
      ),
    );
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;

    try {
      final response = await _dio.post(
        '/api/v1/auth/refresh',
        queryParameters: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': null}), // Skip auth interceptor
      );

      final data = response.data['data'];
      await saveTokens(data['accessToken'], data['refreshToken']);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> _clearTokens() async {
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);
  Future<bool> hasValidToken() async => await getAccessToken() != null;
}
