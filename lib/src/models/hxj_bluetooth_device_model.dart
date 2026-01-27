import 'dart:io';

class HxjBluetoothDeviceModel {
  final String? mac;
  final String? address;
  final String? name;
  final int? rssi;
  final int? chipType;
  final int? lockType;
  final bool? isPaired;
  final bool? isDiscoverable;
  final bool? isNewProtocol;
  final bool? hasLockEvent;
  final bool? isSupported;
  final bool? settedMac;
  final bool? isSupportReSetMac;
  final List<String>? serviceUUIDs;

  const HxjBluetoothDeviceModel({
    this.mac,
    this.address,
    this.name,
    this.rssi,
    this.chipType,
    this.lockType,
    this.isPaired,
    this.isDiscoverable,
    this.isNewProtocol,
    this.hasLockEvent,
    this.isSupported,
    this.settedMac,
    this.isSupportReSetMac,
    this.serviceUUIDs,
  });
  factory HxjBluetoothDeviceModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const HxjBluetoothDeviceModel();
    if (Platform.isIOS) {
      return HxjBluetoothDeviceModel._iosFromMap(map);
    }
    return HxjBluetoothDeviceModel._fromAndroidMap(map);
  }
  factory HxjBluetoothDeviceModel._iosFromMap(Map<String, dynamic> map) {
    return HxjBluetoothDeviceModel(
      mac: (map['mac'] ?? '') as String,
      isPaired: (map['isPairedFlag'] ?? false) as bool,
      isDiscoverable: (map['discoverableFlag'] ?? false) as bool,
      name: (map['name'] ?? '') as String,
      serviceUUIDs: ((map['serviceUUIDs'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      rssi: _numToInt(map['RSSI'] ?? map['rssi']),
      chipType: _numToInt(map['chipType']),
      isNewProtocol: (map['modernProtocol'] ?? false) as bool,
      lockType: _numToInt(map['lockType']),
    );
  }
  factory HxjBluetoothDeviceModel._fromAndroidMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const HxjBluetoothDeviceModel();
    return HxjBluetoothDeviceModel(
      mac: map['mac'] as String?,
      address: map['address'] as String?,
      name: map['name'] as String?,
      rssi: map['rssi'] is int
          ? map['rssi'] as int
          : (map['rssi'] is num ? (map['rssi'] as num).toInt() : null),
      chipType: map['chipType'] is int
          ? map['chipType'] as int
          : (map['chipType'] is num ? (map['chipType'] as num).toInt() : null),
      lockType: map['lockType'] is int
          ? map['lockType'] as int
          : (map['lockType'] is num ? (map['lockType'] as num).toInt() : null),
      isPaired: map['isPaired'] as bool?,
      isDiscoverable: map['isDiscoverable'] as bool?,
      isNewProtocol: map['isNewProtocol'] as bool?,
      hasLockEvent: map['hasLockEvent'] as bool?,
      isSupported: map['isSupported'] as bool?,
      settedMac: map['settedMac'] as bool?,
      isSupportReSetMac: map['isSupportReSetMac'] as bool?,
    );
  }

  /// ✅ ONLY ONE toMap (platform-based)
  Map<String, dynamic> toMap() {
    if (Platform.isIOS) {
      return _toIosMap();
    }

    // iOS map = android map + iOS keys (NO deletes, NO overwrites existing)
    return _toAndroidMap();
  }

  Map<String, dynamic> _toIosMap() {
    return {
      'mac': mac,
      'isPairedFlag': isPaired,
      'discoverableFlag': isDiscoverable,
      'name': name,
      'serviceUUIDs': serviceUUIDs,
      'RSSI': rssi, // keep as RSSI to match iOS model property name
      'chipType': chipType,
      'modernProtocol': isNewProtocol,
      'lockType': lockType,
    };
  }

  Map<String, dynamic> _toAndroidMap() {
    return {
      'mac': mac,
      'address': address,
      'name': name,
      'rssi': rssi,
      'chipType': chipType,
      'lockType': lockType,
      'isPaired': isPaired,
      'isDiscoverable': isDiscoverable,
      'isNewProtocol': isNewProtocol,
      'hasLockEvent': hasLockEvent,
      'isSupported': isSupported,
      'settedMac': settedMac,
      'isSupportReSetMac': isSupportReSetMac,
    };
  }

  HxjBluetoothDeviceModel copyWith({
    String? mac,
    String? address,
    String? name,
    int? rssi,
    int? chipType,
    int? lockType,
    bool? isPaired,
    bool? isDiscoverable,
    bool? isNewProtocol,
    bool? hasLockEvent,
    bool? isSupported,
    bool? settedMac,
    bool? isSupportReSetMac,
  }) {
    return HxjBluetoothDeviceModel(
      mac: mac ?? this.mac,
      address: address ?? this.address,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      chipType: chipType ?? this.chipType,
      lockType: lockType ?? this.lockType,
      isPaired: isPaired ?? this.isPaired,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
      isNewProtocol: isNewProtocol ?? this.isNewProtocol,
      hasLockEvent: hasLockEvent ?? this.hasLockEvent,
      isSupported: isSupported ?? this.isSupported,
      settedMac: settedMac ?? this.settedMac,
      isSupportReSetMac: isSupportReSetMac ?? this.isSupportReSetMac,
    );
  }

  @override
  String toString() {
    return 'HxjBluetoothDeviceModel(mac: $mac, chipType: $chipType, rssi: $rssi, name: $name)';
  }

  /// Returns the MAC without separators (lowercased), matching the Java
  /// `HxjBluetoothDevice.getMac()` behaviour. If the Dart `mac` field is
  /// present it's returned directly; otherwise it's derived from `address`.
  String? getMac() {
    if (mac != null && mac!.isNotEmpty) return mac;
    if (address == null || address!.isEmpty) return null;
    final normalized = address!.replaceAll(':', '').toLowerCase();
    return normalized.isEmpty ? null : normalized;
  }

  // =========================
  // Helpers
  // =========================
  static int _numToInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
