import 'dart:async';
import 'package:flutter/services.dart';
import 'package:wise_apartment/src/storage/secure_storage.dart';

class WiseApartmentApi {
  static const MethodChannel _channel = MethodChannel('wise_apartment/methods');

  /// Save authentication info securely in Flutter (flutter_secure_storage)
  static Future<void> saveAuth(Map<String, dynamic> auth) async {
    await SecureStorageService.instance.saveAuth(auth);
  }

  /// Clear stored auth
  static Future<void> clearAuth() async {
    await SecureStorageService.instance.clearAuth();
    await _channel.invokeMethod('clearSdkState');
  }

  /// Internal: read stored auth and merge into args
  static Future<Map<String, dynamic>> _mergeAuth(
    Map<String, dynamic>? args,
  ) async {
    final auth = await SecureStorageService.instance.readAuth();
    final Map<String, dynamic> merged = {};
    if (args != null) merged.addAll(args);
    // copy non-null auth values
    auth.forEach((k, v) {
      if (v != null && v.isNotEmpty) merged[k] = v;
    });
    return merged;
  }

  static Future<dynamic> openLock(Map<String, dynamic>? args) async {
    final merged = await _mergeAuth(args);
    return _channel.invokeMethod('openLock', merged);
  }

  static Future<dynamic> getDna(Map<String, dynamic>? args) async {
    final merged = await _mergeAuth(args);
    return _channel.invokeMethod('getDna', merged);
  }

  static Future<dynamic> pairSuccessInd(Map<String, dynamic>? args) async {
    final merged = await _mergeAuth(args);
    return _channel.invokeMethod('pairSuccessInd', merged);
  }

  // Add other wrappers as needed, following the same pattern
}
