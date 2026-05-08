import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'models/auth_user.dart';

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final DioClient _dio;
  final SecureStorage _storage;

  /// Logs the user in via Frappe's `/api/method/login`.
  ///
  /// On success Frappe sets `sid` as a Set-Cookie header; we extract and
  /// persist it for the [AuthInterceptor] to attach on later calls.
  Future<AuthUser> login({
    required String usr,
    required String pwd,
    bool remember = true,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.login,
      data: <String, dynamic>{'usr': usr, 'pwd': pwd},
      options: _formOptions(),
    );

    final cookies = response.headers.map['set-cookie'] ?? <String>[];
    final sid = _extractCookie(cookies, 'sid');
    if (sid == null) {
      throw ApiException(
        message: 'Login succeeded but no session was returned by the server.',
      );
    }

    await _storage.saveSession(sid: sid, user: usr);
    await _storage.setRememberLogin(remember: remember, username: remember ? usr : null);

    return fetchCurrentUser();
  }

  /// Calls our custom mobile API to fetch the rich user/employee profile.
  Future<AuthUser> fetchCurrentUser() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
    final data = response.data?['message'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(message: 'Unexpected response from server.');
    }
    return AuthUser.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await _dio.get<dynamic>(ApiEndpoints.logout);
    } catch (_) {
      // Even if the server call fails we still want to clear local state.
    }
    await _storage.clearSession();
  }

  Future<bool> hasSession() async {
    final sid = await _storage.sessionId;
    return sid != null && sid.isNotEmpty;
  }

  Future<String?> get rememberedUsername async {
    if (!await _storage.rememberLogin) return null;
    return _storage.savedUsername;
  }

  Options _formOptions() => Options(
        contentType: 'application/x-www-form-urlencoded',
      );

  String? _extractCookie(List<String> cookies, String name) {
    for (final raw in cookies) {
      for (final part in raw.split(';')) {
        final trimmed = part.trim();
        if (trimmed.startsWith('$name=')) {
          return trimmed.substring(name.length + 1);
        }
      }
    }
    return null;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(secureStorageProvider),
  );
});
