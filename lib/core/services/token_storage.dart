import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(SharedPreferencesAsync());
});

class TokenStorage {
  const TokenStorage(this._preferences);

  static const _tokenKey = 'auth_token';

  final SharedPreferencesAsync _preferences;

  Future<String?> read() => _preferences.getString(_tokenKey);

  Future<void> save(String token) => _preferences.setString(_tokenKey, token);

  Future<void> clear() => _preferences.remove(_tokenKey);
}
