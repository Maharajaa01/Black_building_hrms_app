import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

/// Attaches Frappe auth credentials to every outgoing request.
///
/// Frappe accepts two auth modes:
///   * Cookie-based session — `sid=...` cookie set by `/api/method/login`.
///   * Token-based — `Authorization: token <api_key>:<api_secret>`.
///
/// We prefer the API token when available (longer-lived, survives session
/// expiry) and fall back to the session cookie.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final SecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final apiKey = await _storage.apiKey;
    final apiSecret = await _storage.apiSecret;

    if (apiKey != null && apiKey.isNotEmpty && apiSecret != null && apiSecret.isNotEmpty) {
      options.headers['Authorization'] = 'token $apiKey:$apiSecret';
    } else {
      final sid = await _storage.sessionId;
      if (sid != null && sid.isNotEmpty) {
        final existingCookie = options.headers['Cookie'] as String?;
        options.headers['Cookie'] =
            existingCookie == null ? 'sid=$sid' : '$existingCookie; sid=$sid';
      }
    }

    options.headers['X-Frappe-CSRF-Token'] = 'token';
    options.headers['Accept'] ??= 'application/json';
    handler.next(options);
  }
}
