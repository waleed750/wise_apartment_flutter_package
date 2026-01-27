/// Result from unlock operation
class UnlockResult {
  final String mac;
  final int batteryLevel;
  final int? unlockDurationMs;

  const UnlockResult({
    required this.mac,
    required this.batteryLevel,
    this.unlockDurationMs,
  });

  factory UnlockResult.fromMap(Map<String, dynamic> map) {
    return UnlockResult(
      mac: map['mac'] as String? ?? '',
      batteryLevel:
          (map['batteryLevel'] as num?)?.toInt() ??
          (map['power'] as num?)?.toInt() ??
          0,
      unlockDurationMs:
          (map['unlockDurationMs'] as num?)?.toInt() ??
          (map['unlockingDuration'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mac': mac,
      'batteryLevel': batteryLevel,
      if (unlockDurationMs != null) 'unlockDurationMs': unlockDurationMs,
    };
  }

  @override
  String toString() => 'UnlockResult(mac: $mac, battery: $batteryLevel%)';
}
