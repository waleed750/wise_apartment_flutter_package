import 'dart:convert';
import 'dart:io';

import 'package:wise_apartment/src/models/dna_info_model.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String _baseUrl = 'http://34.166.141.220:8090';

  // In-memory platform token stored until app closes
  String? _platformToken;

  Future<String?> platformLogin() async {
    if (_platformToken != null && _platformToken!.isNotEmpty)
      return _platformToken;

    final payload = {
      'method': 'platformLogin',
      'data': {'appKey': 'test_app_key', 'appSecret': 'test_app_secret'},
    };

    try {
      final uri = Uri.parse(_baseUrl);
      final httpClient = HttpClient();
      final req = await httpClient.postUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.add(utf8.encode(jsonEncode(payload)));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      httpClient.close();
      final Map<String, dynamic> j = jsonDecode(body) as Map<String, dynamic>;
      if ((j['resultCode'] ?? 1) == 0) {
        final data = j['data'] as Map<String, dynamic>?;
        final token = data != null ? (data['tokenId'] as String?) : null;
        _platformToken = token;
        return token;
      }
    } catch (_) {
      // ignore errors; caller handles null
    }
    return null;
  }

  Future<String?> hxjGetLockToken({
    required String platformToken,
    required String lockMac,
    required String? initFlag,
    required int? bleProtocolVersion,
    required int? menuFeature,
  }) async {
    final payload = {
      'method': 'hxjGetLockToken',
      'tokenId': platformToken,
      'data': {
        'lockMac': lockMac,
        'initFlag': initFlag ?? '',
        'bleProtocolVersion': bleProtocolVersion ?? 0,
        'menuFeature': menuFeature ?? 0,
      },
    };

    try {
      final uri = Uri.parse(_baseUrl);
      final httpClient = HttpClient();
      final req = await httpClient.postUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.add(utf8.encode(jsonEncode(payload)));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      httpClient.close();
      final Map<String, dynamic> j = jsonDecode(body) as Map<String, dynamic>;
      if ((j['resultCode'] ?? 1) == 0) {
        final data = j['data'] as Map<String, dynamic>?;
        final lockToken = data != null ? (data['tokenId'] as String?) : null;
        return lockToken;
      }
    } catch (_) {
      // ignore errors; caller handles null
    }
    return null;
  }

  /// Convenience: get a lock-specific token for [device].
  /// Ensures platform login runs once per app session.
  Future<String?> getLockTokenForDevice(DnaInfoModel device) async {
    final platform = await platformLogin();
    if (platform == null || platform.isEmpty) return null;
    final lockMac = device.mac ?? '';
    final initFlag = device.initTag;
    final bleProtocolVersion = device.protocolVer;
    final menuFeature = device.menuFeature;
    final lockToken = await hxjGetLockToken(
      platformToken: platform,
      lockMac: lockMac,
      initFlag: initFlag,
      bleProtocolVersion: bleProtocolVersion,
      menuFeature: menuFeature,
    );
    return lockToken ?? platform;
  }
}
