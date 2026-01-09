import 'package:dio/dio.dart';
import 'package:streaming_dashboard/core/config/log_service.dart';
import 'package:streaming_dashboard/core/constants/api_constants.dart';
import 'package:streaming_dashboard/features/views/login/model/login_model.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;
  late Dio _dio;

  // Store the access token
  String? _accessToken;
  // Singleton pattern
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // You can add authorization headers or logging here
          if (_accessToken != null && _accessToken!.isNotEmpty) {
            options.headers['Authorization'] = '$_accessToken';
            LogService.debug('🔑 Token Added to Request ${options.headers}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // You can log responses here
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          // You can handle errors globally here
          if (error.response?.statusCode == 401) {
            LogService.debug('🔒 Token Expired - User needs to login again');
            // You can add logout logic here or trigger a callback
          }
          return handler.next(error);
        },
      ),
    );
  }
  // Set the access token (call this after successful login)
  void setAccessToken(String token) {
    _accessToken = token;
  }

  // Get the current access token
  String? getAccessToken() {
    return _accessToken;
  }

  // Clear the access token (call this on logout)
  void clearAccessToken() {
    _accessToken = null;
  }

  // Check if user is authenticated
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  // Login API
  Future<ApiResponse<LoginModel>> formLoginAPI({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final loginModel = LoginModel.fromJson(response.data);
        return ApiResponse<LoginModel>(data: loginModel, error: null);
      } else {
        LogService.debug('❌ API Error: Status ${response.statusCode}');
        return ApiResponse<LoginModel>(
          data: null,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      LogService.debug('❌ DioException Caught');
      LogService.debug('Error Message: ${e.message}');
      String errorMessage = _handleDioError(e);
      return ApiResponse<LoginModel>(data: null, error: errorMessage);
    } catch (e, _) {
      LogService.debug('❌ Unexpected Error');
      LogService.debug('Error: $e');
      return ApiResponse<LoginModel>(data: null, error: 'Unexpected error: $e');
    }
  }

  // Generic GET method
  Future<ApiResponse<T>> get<T>({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      LogService.debug('🔵 GET Request Started');
      LogService.debug('Endpoint: $endpoint');
      LogService.debug('Query Parameters: $queryParameters');
      LogService.debug('═══════════════════════════════════');

      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );

      LogService.debug('🟢 GET Response Received');
      LogService.debug('Status Code: ${response.statusCode}');
      LogService.debug('Response Data: ${response.data}');
      LogService.debug('═══════════════════════════════════');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = fromJson(response.data);
        LogService.debug('✅ Parsing Successful');
        return ApiResponse<T>(data: data, error: null);
      } else {
        LogService.debug('❌ API Error: Status ${response.statusCode}');
        return ApiResponse<T>(
          data: null,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      LogService.debug('❌ DioException Caught');
      LogService.debug('Error Type: ${e.type}');
      LogService.debug('Error Message: ${e.message}');
      LogService.debug('Response: ${e.response?.data}');
      LogService.debug('═══════════════════════════════════');

      String errorMessage = _handleDioError(e);
      return ApiResponse<T>(data: null, error: errorMessage);
    } catch (e, stackTrace) {
      LogService.debug('❌ Unexpected Error');
      LogService.debug('Error: $e');
      LogService.debug('Stack Trace: $stackTrace');
      LogService.debug('═══════════════════════════════════');

      return ApiResponse<T>(data: null, error: 'Unexpected error: $e');
    }
  }

  // Generic POST method with optional headers
  Future<ApiResponse<T>> post<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    required T Function(Map<String, dynamic>) fromJson,
    // Option to disable auth for specific calls
  }) async {
    try {
      LogService.debug('🔵 POST Request Started');
      LogService.debug('Endpoint: $endpoint');
      LogService.debug('Request Data: $data');
      LogService.debug('═══════════════════════════════════');

      final response = await _dio.post(endpoint, data: data);

      LogService.debug('🟢 POST Response Received');
      LogService.debug('Status Code: ${response.statusCode}');
      LogService.debug('Response Data: ${response.data}');
      LogService.debug('═══════════════════════════════════');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = fromJson(response.data);
        LogService.debug('✅ Parsing Successful');
        return ApiResponse<T>(data: responseData, error: null);
      } else {
        LogService.debug('❌ API Error: Status ${response.statusCode}');
        return ApiResponse<T>(
          data: null,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      LogService.debug('❌ DioException Caught');
      LogService.debug('Error Type: ${e.type}');
      LogService.debug('Error Message: ${e.message}');
      LogService.debug('Response: ${e.response?.data}');
      LogService.debug('═══════════════════════════════════');

      String errorMessage = _handleDioError(e);
      return ApiResponse<T>(data: null, error: errorMessage);
    } catch (e, stackTrace) {
      LogService.debug('❌ Unexpected Error');
      LogService.debug('Error: $e');
      LogService.debug('Stack Trace: $stackTrace');
      LogService.debug('═══════════════════════════════════');

      return ApiResponse<T>(data: null, error: 'Unexpected error: $e');
    }
  }

  // Generic PUT method (token automatically added via interceptor)
  Future<ApiResponse<T>> put<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? headers,
    required T Function(Map<String, dynamic>) fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      if (requiresAuth && !isAuthenticated) {
        return ApiResponse<T>(
          data: null,
          error: 'Authentication required. Please login.',
        );
      }

      LogService.debug('🔵 PUT Request Started');
      LogService.debug('Endpoint: $endpoint');
      LogService.debug('Request Data: $data');
      LogService.debug('═══════════════════════════════════');

      final response = await _dio.put(
        endpoint,
        data: data,
        options: headers != null ? Options(headers: headers) : null,
      );

      LogService.debug('🟢 PUT Response Received');
      LogService.debug('Status Code: ${response.statusCode}');
      LogService.debug('═══════════════════════════════════');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = fromJson(response.data);
        LogService.debug('✅ Parsing Successful');
        return ApiResponse<T>(data: responseData, error: null);
      } else {
        LogService.debug('❌ API Error: Status ${response.statusCode}');
        return ApiResponse<T>(
          data: null,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage = _handleDioError(e);
      return ApiResponse<T>(data: null, error: errorMessage);
    } catch (e) {
      return ApiResponse<T>(data: null, error: 'Unexpected error: $e');
    }
  }

  // Helper method to get Bearer token header
  static Map<String, dynamic> getBearerHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Helper method to handle Dio errors
  String _handleDioError(DioException e) {
    try {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timeout. Please check your internet connection.';

        case DioExceptionType.sendTimeout:
          return 'Request timeout. Please try again.';

        case DioExceptionType.receiveTimeout:
          return 'Server response timeout. Please try again.';

        case DioExceptionType.badResponse:
          // Handle 401 specifically
          if (e.response?.statusCode == 401) {
            return 'Authentication failed. Please login again.';
          }

          // Safely access response data
          final responseData = e.response?.data;
          if (responseData != null) {
            // If response is a Map, try to get error message
            if (responseData is Map<String, dynamic>) {
              return responseData['message'] ??
                  responseData['error'] ??
                  'Server error: ${e.response?.statusCode}';
            }
            // If response is a String
            if (responseData is String) {
              return responseData.isNotEmpty
                  ? responseData
                  : 'Server error: ${e.response?.statusCode}';
            }
          }
          return 'Server error: ${e.response?.statusCode ?? 'Unknown'}';

        case DioExceptionType.cancel:
          return 'Request cancelled.';

        case DioExceptionType.connectionError:
          return 'Connection error. Please check your internet connection.';

        case DioExceptionType.badCertificate:
          return 'Security certificate error.';

        case DioExceptionType.unknown:
        // ignore: unreachable_switch_default
        default:
          return e.message ?? 'Unknown error occurred.';
      }
    } catch (error) {
      LogService.debug('❌ Error in _handleDioError: $error');
      return 'An unexpected error occurred.';
    }
  }
}

// Response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;

  ApiResponse({this.data, this.error});

  bool get isSuccess => data != null && error == null;
  bool get isError => error != null;
}
