import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/models.dart';

/// Holds the signed-in user (null = signed out). Restores the session from
/// secure storage on app start.
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final store = ref.read(tokenStoreProvider);
    if (await store.readAccess() == null) return null;
    try {
      final res =
          await ref.read(dioProvider).get<Map<String, dynamic>>('/api/v1/me');
      return AppUser.fromJson(res.data!);
    } on DioException {
      // Expired / unreachable: show the login screen. Tokens are cleared by the
      // interceptor when the refresh itself is rejected.
      return null;
    }
  }

  /// Returns an error message to show, or null on success.
  Future<String?> login(String email, String password) => _authenticate(
        '/api/v1/auth/login',
        {'email': email, 'password': password},
      );

  Future<String?> register(String email, String password, String name) =>
      _authenticate(
        '/api/v1/auth/register',
        {'email': email, 'password': password, 'name': name},
      );

  Future<String?> _authenticate(String path, Map<String, dynamic> body) async {
    try {
      final res = await ref.read(dioProvider).post<Map<String, dynamic>>(
            path,
            data: body,
            options: Options(extra: {kNoAuth: true}),
          );
      final data = res.data!;
      await ref.read(tokenStoreProvider).save(
            data['access_token'] as String,
            data['refresh_token'] as String,
          );
      state = AsyncData(AppUser.fromJson(data['user'] as Map<String, dynamic>));
      return null;
    } on DioException catch (e) {
      return apiErrorMessage(e);
    } catch (_) {
      // e.g. secure storage unavailable: show a message instead of spinning forever.
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);
