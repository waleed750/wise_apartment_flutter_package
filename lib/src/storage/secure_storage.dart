import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _authKeys = {
    'authCode': 'authCode',
    'dnaKey': 'dnaKey',
    'mac': 'mac',
    'keyGroupId': 'keyGroupId',
    'bleProtocolVer': 'bleProtocolVer',
  };

  final FlutterSecureStorage _storage;

  SecureStorageService._(this._storage);
  static final SecureStorageService instance = SecureStorageService._(
    const FlutterSecureStorage(),
  );

  Future<void> saveAuth(Map<String, dynamic> auth) async {
    for (final entry in _authKeys.entries) {
      final key = entry.key;
      final storageKey = entry.value;
      if (auth.containsKey(key) && auth[key] != null) {
        await _storage.write(key: storageKey, value: auth[key].toString());
      }
    }
  }

  Future<Map<String, String?>> readAuth() async {
    final Map<String, String?> out = {};
    for (final storageKey in _authKeys.values) {
      out[storageKey] = await _storage.read(key: storageKey);
    }
    return out;
  }

  Future<void> clearAuth() async {
    for (final storageKey in _authKeys.values) {
      await _storage.delete(key: storageKey);
    }
  }
}
