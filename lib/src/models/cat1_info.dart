/// Cat1 module information
class Cat1Info {
  final String iccid;
  final String imei;
  final String imsi;
  final String rssi;
  final String rsrp;
  final String sinr;

  const Cat1Info({
    required this.iccid,
    required this.imei,
    required this.imsi,
    required this.rssi,
    required this.rsrp,
    required this.sinr,
  });

  factory Cat1Info.fromMap(Map<String, dynamic> map) {
    return Cat1Info(
      iccid: map['iccid'] as String? ?? '',
      imei: map['imei'] as String? ?? '',
      imsi: map['imsi'] as String? ?? '',
      rssi: map['rssi']?.toString() ?? '',
      rsrp: map['rsrp']?.toString() ?? '',
      sinr: map['sinr']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'iccid': iccid,
      'imei': imei,
      'imsi': imsi,
      'rssi': rssi,
      'rsrp': rsrp,
      'sinr': sinr,
    };
  }

  @override
  String toString() => 'Cat1Info(imei: $imei, rssi: $rssi)';
}
