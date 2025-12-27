import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureDeviceStorage {
  static const _storageKey = 'wise_saved_devices';
  static final _secureStorage = FlutterSecureStorage();

  static Future<List<Map<String, dynamic>>> loadDevices() async {
    final jsonStr = await _secureStorage.read(key: _storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDevices(List<Map<String, dynamic>> devices) async {
    final jsonStr = json.encode(devices);
    await _secureStorage.write(key: _storageKey, value: jsonStr);
  }

  static Future<void> addDevice(Map<String, dynamic> device) async {
    final devices = await loadDevices();
    devices.removeWhere((d) => d['mac'] == device['mac']);
    devices.add(device);
    await saveDevices(devices);
  }

  static Future<void> removeDevice(String mac) async {
    final devices = await loadDevices();
    devices.removeWhere((d) => d['mac'] == mac);
    await saveDevices(devices);
  }
}
