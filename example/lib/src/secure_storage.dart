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
    // Ensure uniqueness by a stable key (prefer mac, fallback to deviceDnaInfoStr).
    final Map<String, Map<String, dynamic>> byKey = {};
    for (final d in devices) {
      final k = _uniqueKeyForDevice(d);
      if (k == null) continue;
      // later entries override earlier ones
      byKey[k] = d;
    }
    final uniqueList = byKey.values.toList();
    final jsonStr = json.encode(uniqueList);
    await _secureStorage.write(key: _storageKey, value: jsonStr);
  }

  static Future<void> addDevice(Map<String, dynamic> device) async {
    final devices = await loadDevices();
    final key = _uniqueKeyForDevice(device);
    if (key == null) {
      // fallback: just append
      devices.add(device);
      await saveDevices(devices);
      return;
    }

    // Remove any existing entry with same unique key
    devices.removeWhere((d) {
      final k = _uniqueKeyForDevice(d);
      return k != null && k == key;
    });

    // Add new device (putting it last so it becomes newest)
    devices.add(device);
    await saveDevices(devices);
  }

  static String? _uniqueKeyForDevice(Map<String, dynamic>? d) {
    if (d == null) return null;
    final mac = d['mac'];
    if (mac is String && mac.trim().isNotEmpty) return mac.trim();
    final dna = d['deviceDnaInfoStr'];
    if (dna is String && dna.trim().isNotEmpty) return dna.trim();
    return null;
  }

  static Future<void> removeDevice(String mac) async {
    final devices = await loadDevices();
    devices.removeWhere((d) => d['mac'] == mac);
    await saveDevices(devices);
  }
}
