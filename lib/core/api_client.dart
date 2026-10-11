import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config.dart';
import 'token_store.dart';

/// Mark a request with `Options(extra: {kNoAuth: true})` to skip the Bearer
/// header and the automatic token refresh (used for login / register).
const kNoAuth = 'noAuth';
const _kRetried = 'retried';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final dioProvider = Provider<Dio>((ref) {
  final store = ref.watch(tokenStoreProvider);
  final dio = Dio(_baseOptions());
  dio.interceptors.add(_AuthInterceptor(dio, store));
  return dio;
});

BaseOptions _baseOptions() => BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    );

/// Adds the Bearer token and, on a 401, refreshes the tokens once and retries.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio, this._store);

  final Dio _dio;
  final TokenStore _store;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[kNoAuth] != true) {
      final token = await _store.readAccess();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final req = err.requestOptions;
    final skip = err.response?.statusCode != 401 ||
        req.extra[kNoAuth] == true ||
        req.extra[_kRetried] == true;
    if (skip) {
      handler.next(err);
      return;
    }

    if (!await _tryRefresh()) {
      handler.next(err);
      return;
    }

    try {
      final token = await _store.readAccess();
      req.headers['Authorization'] = 'Bearer $token';
      req.extra[_kRetried] = true;
      final response = await _dio.fetch<dynamic>(req);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _store.readRefresh();
    if (refresh == null) return false;
    try {
      // A separate Dio without interceptors, so a failed refresh cannot loop.
      final plain = Dio(_baseOptions());
      final res = await plain.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final data = res.data!;
      await _store.save(
        data['access_token'] as String,
        data['refresh_token'] as String,
      );
      return true;
    } on DioException {
      await _store.clear();
      return false;
    }
  }
}

const _knownErrors = {
  'incorrect email or password': 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
  'email already registered': 'อีเมลนี้ถูกใช้สมัครไว้แล้ว',
  'an item is no longer available': 'มีเมนูที่หมดแล้ว กรุณาตรวจสอบตะกร้าอีกครั้ง',
  'order can no longer be cancelled': 'ออเดอร์นี้ยกเลิกไม่ได้แล้ว',
  'order not found': 'ไม่พบออเดอร์นี้',
  'admin only': 'เฉพาะเจ้าของร้านเท่านั้น',
};

/// Turns an API / network error into a short Thai message for the user.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      final msg = data['error'] as String;
      return _knownErrors[msg] ?? _fallback(error.response?.statusCode);
    }
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต';
      default:
        return _fallback(error.response?.statusCode);
    }
  }
  return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
}

String _fallback(int? status) {
  if (status == 401) return 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
  if (status == 400) return 'ข้อมูลไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง';
  if (status == 409) return 'ทำรายการนี้ไม่ได้ในตอนนี้ กรุณารีเฟรชแล้วลองใหม่';
  return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
}
