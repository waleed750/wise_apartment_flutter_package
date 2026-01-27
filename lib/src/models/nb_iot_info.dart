/// NB-IoT module information
class NBIoTInfo {
  final int rssi;
  final String imsi;
  final String imei;

  const NBIoTInfo({required this.rssi, required this.imsi, required this.imei});

  factory NBIoTInfo.fromMap(Map<String, dynamic> map) {
    return NBIoTInfo(
      rssi: (map['rssi'] as num?)?.toInt() ?? 0,
      imsi: map['imsi'] as String? ?? '',
      imei: map['imei'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'rssi': rssi, 'imsi': imsi, 'imei': imei};
  }

  @override
  String toString() => 'NBIoTInfo(imei: $imei, rssi: $rssi)';
}
