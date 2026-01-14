class SysParamResult {
  final String? deviceStatusStr;
  final int? lockOpen;
  final int? normallyOpen;
  final int? isSound;
  final int? sysVolume;
  final int? isTamperWarn;
  final int? isLockCoreWarn;
  final int? isLock;
  final int? isLockCap;
  final int? initStatus;
  final String? sysTime;
  final int? sysTimestamp; // long on native
  // Note: native field name uses capital 'T' -> "TimezoneOffset"
  final int? timezoneOffset;
  final int? electricNum;
  final int? noPowerOpenNo;
  final int? noOpenKey;
  final int? normallyOpenFlag;
  final int? isLockFlag;
  final int? bigBoltFlag;
  final int? boltFlag;
  final int? isNoOpenFlag;
  final int? isCover;
  final int? isClose;
  final int? coreFlag;
  final int? systemLanguage;
  // longs on native side
  final int? lockSystemFunction;
  final int? lockNetSystemFunction2;

  const SysParamResult({
    this.deviceStatusStr,
    this.lockOpen,
    this.normallyOpen,
    this.isSound,
    this.sysVolume,
    this.isTamperWarn,
    this.isLockCoreWarn,
    this.isLock,
    this.isLockCap,
    this.initStatus,
    this.sysTime,
    this.sysTimestamp,
    this.timezoneOffset,
    this.electricNum,
    this.noPowerOpenNo,
    this.noOpenKey,
    this.normallyOpenFlag,
    this.isLockFlag,
    this.bigBoltFlag,
    this.boltFlag,
    this.isNoOpenFlag,
    this.isCover,
    this.isClose,
    this.coreFlag,
    this.systemLanguage,
    this.lockSystemFunction,
    this.lockNetSystemFunction2,
  });

  /// Build from the `body` map returned by the platform channel.
  factory SysParamResult.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SysParamResult();

    int? _i(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) return null;
        return int.tryParse(s);
      }
      return null;
    }

    String? _s(dynamic v) => v == null ? null : v.toString();

    // Native uses field name "TimezoneOffset" (capital T). Accept both keys.
    final tz = _i(map['TimezoneOffset'] ?? map['timezoneOffset']);

    return SysParamResult(
      deviceStatusStr: _s(map['deviceStatusStr']),
      lockOpen: _i(map['lockOpen']),
      normallyOpen: _i(map['normallyOpen']),
      isSound: _i(map['isSound']),
      sysVolume: _i(map['sysVolume']),
      isTamperWarn: _i(map['isTamperWarn']),
      isLockCoreWarn: _i(map['isLockCoreWarn']),
      isLock: _i(map['isLock']),
      isLockCap: _i(map['isLockCap']),
      initStatus: _i(map['initStatus']),
      sysTime: _s(map['sysTime']),
      sysTimestamp: _i(map['sysTimestamp']),
      timezoneOffset: tz,
      electricNum: _i(map['electricNum']),
      noPowerOpenNo: _i(map['noPowerOpenNo']),
      noOpenKey: _i(map['noOpenKey']),
      normallyOpenFlag: _i(map['normallyOpenFlag']),
      isLockFlag: _i(map['isLockFlag']),
      bigBoltFlag: _i(map['bigBoltFlag']),
      boltFlag: _i(map['boltFlag']),
      isNoOpenFlag: _i(map['isNoOpenFlag']),
      isCover: _i(map['isCover']),
      isClose: _i(map['isClose']),
      coreFlag: _i(map['coreFlag']),
      systemLanguage: _i(map['systemLanguage']),
      lockSystemFunction: _i(map['lockSystemFunction']),
      lockNetSystemFunction2: _i(map['lockNetSystemFunction2']),
    );
  }

  /// Build directly from the full platform response of getSysParam,
  /// which looks like { code, message, ackMessage, ..., body: {...} }.
  factory SysParamResult.fromResponse(Map<String, dynamic>? resp) {
    if (resp == null) return const SysParamResult();
    final body = resp['body'];
    if (body is Map) {
      return SysParamResult.fromMap(body.cast<String, dynamic>());
    }
    return const SysParamResult();
  }

  Map<String, dynamic> toJson() => {
    'deviceStatusStr': deviceStatusStr,
    'lockOpen': lockOpen,
    'normallyOpen': normallyOpen,
    'isSound': isSound,
    'sysVolume': sysVolume,
    'isTamperWarn': isTamperWarn,
    'isLockCoreWarn': isLockCoreWarn,
    'isLock': isLock,
    'isLockCap': isLockCap,
    'initStatus': initStatus,
    'sysTime': sysTime,
    'sysTimestamp': sysTimestamp,
    // Normalize to camelCase on output
    'timezoneOffset': timezoneOffset,
    'electricNum': electricNum,
    'noPowerOpenNo': noPowerOpenNo,
    'noOpenKey': noOpenKey,
    'normallyOpenFlag': normallyOpenFlag,
    'isLockFlag': isLockFlag,
    'bigBoltFlag': bigBoltFlag,
    'boltFlag': boltFlag,
    'isNoOpenFlag': isNoOpenFlag,
    'isCover': isCover,
    'isClose': isClose,
    'coreFlag': coreFlag,
    'systemLanguage': systemLanguage,
    'lockSystemFunction': lockSystemFunction,
    'lockNetSystemFunction2': lockNetSystemFunction2,
  };

  @override
  String toString() {
    final entries = toJson().entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    return 'SysParamResult($entries)';
  }
}
