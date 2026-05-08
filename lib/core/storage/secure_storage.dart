import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps `flutter_secure_storage` so the rest of the app uses one named
/// API and we can swap the backing store in tests.
class SecureStorage {
  SecureStorage(this._storage);

  static const _kSessionId = 'frappe_sid';
  static const _kApiKey = 'frappe_api_key';
  static const _kApiSecret = 'frappe_api_secret';
  static const _kUser = 'frappe_user';
  static const _kRememberLogin = 'remember_login';
  static const _kSavedUsername = 'saved_username';

  final FlutterSecureStorage _storage;

  Future<void> saveSession({
    required String sid,
    String? apiKey,
    String? apiSecret,
    String? user,
  }) async {
    await Future.wait(<Future<void>>[
      _storage.write(key: _kSessionId, value: sid),
      if (apiKey != null) _storage.write(key: _kApiKey, value: apiKey),
      if (apiSecret != null) _storage.write(key: _kApiSecret, value: apiSecret),
      if (user != null) _storage.write(key: _kUser, value: user),
    ]);
  }

  Future<String?> get sessionId => _storage.read(key: _kSessionId);
  Future<String?> get apiKey => _storage.read(key: _kApiKey);
  Future<String?> get apiSecret => _storage.read(key: _kApiSecret);
  Future<String?> get user => _storage.read(key: _kUser);

  Future<void> setRememberLogin({required bool remember, String? username}) async {
    await _storage.write(key: _kRememberLogin, value: remember ? '1' : '0');
    if (remember && username != null) {
      await _storage.write(key: _kSavedUsername, value: username);
    } else {
      await _storage.delete(key: _kSavedUsername);
    }
  }

  Future<bool> get rememberLogin async =>
      (await _storage.read(key: _kRememberLogin)) == '1';

  Future<String?> get savedUsername => _storage.read(key: _kSavedUsername);

  Future<void> clearSession() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _kSessionId),
      _storage.delete(key: _kApiKey),
      _storage.delete(key: _kApiSecret),
      _storage.delete(key: _kUser),
    ]);
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  return SecureStorage(storage);
});
