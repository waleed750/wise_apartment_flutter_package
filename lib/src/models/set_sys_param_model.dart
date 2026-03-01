/// Request model for the `setSysParam` / `setSystemParameters` BLE command.
///
/// All fields are **optional** — pass `null` (or omit) to leave the current
/// device setting unchanged for that field.
///
/// Field values follow the same semantics as [SysParamResult]:
/// - Unlock mode (`lockOpen`): 1 = single unlock, 2 = combination unlock
/// - Toggleable modes (isSound, normallyOpen, etc.): 1 = enable, 2 = disable
/// - Lock-core alarm (`isLockCoreWarn`): 0 = do not change, 1 = enable, 2 = disable
///
/// Android mapping  →  `SetSysParamAction` setters
/// iOS mapping      →  `HXSetSystemParameters` properties
class SetSysParamModel {
  // ── Unlock / normally-open ────────────────────────────────────────────────

  /// Unlock mode.
  /// 1 = single unlock ; 2 = combination unlock.
  ///
  /// Android: `setLockOpen` · iOS: `openMode`
  final int? lockOpen;

  /// Normally-open (passage) mode.
  /// 1 = enable ; 2 = disable.
  ///
  /// Android: `setNormallyOpen` · iOS: `normallyOpenMode`
  final int? normallyOpen;

  // ── Audio ─────────────────────────────────────────────────────────────────

  /// Door-open voice (beep / chime).
  /// 1 = on ; 2 = off.
  ///
  /// Android: `setIsSound` · iOS: `volumeEnable`
  final int? isSound;

  /// System volume (0 = do not change; 1–5 = set to level).
  /// Most locks do not support volume adjustment.
  ///
  /// Android: `setSysVolume` · iOS: `systemVolume`
  final int? sysVolume;

  // ── Security alarms ───────────────────────────────────────────────────────

  /// Anti-tamper / anti-smash alarm.
  /// 1 = enable ; 2 = disable.
  ///
  /// Android: `setIsTamperWarn` · iOS: `shackleAlarmEnable`
  final int? isTamperWarn;

  /// Lock-cylinder (core) alarm.
  /// 0 = do not change ; 1 = enable ; 2 = disable.
  ///
  /// Android: `setIsLockCoreWarn` · iOS: `lockCylinderAlarmEnable`
  final int? isLockCoreWarn;

  /// Anti-lock (deadbolt) function.
  /// 1 = enable ; 2 = disable.
  ///
  /// Android: `setIsLock` · iOS: `antiLockEnable`
  final int? isLock;

  /// Lock-cover alarm.
  /// 1 = enable ; 2 = disable.
  ///
  /// Android: `setIsLockCap` · iOS: `lockCoverAlarmEnable`
  final int? isLockCap;

  // ── Localisation ──────────────────────────────────────────────────────────

  /// System display language.
  /// 1 = Simplified Chinese ; 2 = Traditional Chinese ;
  /// 3 = English ; 4 = Vietnamese ; 5 = Thai.
  ///
  /// Android: `setSystemLanguage` · iOS: `systemLanguage`
  final int? systemLanguage;

  // ── Advanced / optional features ──────────────────────────────────────────

  /// Replace (substitution-key) function.
  /// 0x00 = do not change ; 0x01 = enable ; 0x02 = disable.
  ///
  /// Android: `setReplaceSet` · iOS: `replaceSet`
  final int? replaceSet;

  /// Anti-copy (key clone prevention).
  /// 0x00 = do not change ; 0x01 = enable ; 0x02 = disable.
  ///
  /// Android: `setAntiCopyFunction` · iOS: `antiCopyFunction`
  final int? antiCopyFunction;

  /// Trial-and-error alarm enable.
  /// 0x00 = do not change ; 0x01 = enable (default) ; 0x02 = disable.
  ///
  /// Android: `setKeyTrialErrorAlarmEn` · iOS: `keyTrialErrorAlarmEn`
  final int? keyTrialErrorAlarmEn;

  /// Door-not-closed voice alarm enable.
  /// 0x00 = do not change ; 0x01 = enable (default) ; 0x02 = disable.
  /// Note: disabling only silences the alert; the event is still reported.
  ///
  /// Android: `setNoneCloseVoiceAlarmEn` · iOS: `noneCloseVoiceAlarmEn`
  final int? noneCloseVoiceAlarmEn;
  // Additional fields from device docs
  /// Admin password (string) used for privileged operations.
  final String? adminPassword;

  /// Command type: 1 = normal lock, 2 = automatic lock.
  final int? cmdType;

  /// Automatic lock wait time level: allowed values {0,10,15,20}.
  final int? lockWaitTime;

  /// Bitmask indicating which options to set.
  final int? setFlag;

  /// Button long-press trigger time (ms). Default 50.
  final int? setKeyTriggerTime;

  /// Square tongue blocking current level. Default 30.
  final int? squareTongueBlockingCurrentLevel;

  /// Allowed time for square tongue movement. Default 50.
  final int? squareTongueExcerciseTime;

  /// Hold reversal time after square tongue sticks out. Default 3.
  final int? squareTongueHold;

  /// Slant tongue out time level (3..10).
  final int? tongueLockTime;

  /// Pause time after tongue is retracted: 30,40,50.
  final int? tongueUlockTime;

  /// Unlock direction: 0 = forward, 1 = reverse.
  final int? unLockDirection;

  // --- Allowed values / enums (lists and label maps) ----------------------
  // These constants enumerate the valid values for fields that accept a
  // constrained set of integers. Use them in UI dropdowns or validation.

  /// `lockOpen` options: 1 = single unlock, 2 = combination unlock.
  static const List<int> lockOpenOptions = [1, 2];
  static const Map<int, String> lockOpenLabels = {
    1: '1 – Single unlock',
    2: '2 – Combination unlock',
  };

  /// `normallyOpen` options: 1 = enable, 2 = disable.
  static const List<int> normallyOpenOptions = [1, 2];
  static const Map<int, String> normallyOpenLabels = {
    1: '1 – Enabled',
    2: '2 – Disabled',
  };

  /// Simple toggle lists used by many fields (1 = enable, 2 = disable).
  static const List<int> onOffOptions = [1, 2];

  /// `isLockCoreWarn` values: 0 = do not change, 1 = enable, 2 = disable.
  static const List<int> lockCoreWarnOptions = [0, 1, 2];

  /// `systemLanguage` options (documented): 1..5.
  static const List<int> systemLanguageOptions = [0, 1, 2,3,4];
  static const Map<int, String> systemLanguageLabels = {
    0: '0 – Simplified Chinese',
    1: '1 – Traditional Chinese',
    2: '2 – English',
    3: '3 – Vietnamese',
    4: '4 – Thai',
  };

  /// `sysVolume` values: 0 = do not change, 1..5 = volume levels.
  static const List<int> sysVolumeOptions = [0, 1, 2, 3, 4, 5];

  /// `cmdType` (command type) options: 1 = normal lock, 2 = automatic lock.
  static const List<int> cmdTypeOptions = [1, 2];

  /// `lockWaitTime` allowed values: 0 (no auto-lock), 10, 15, 20 seconds.
  static const List<int> lockWaitTimeOptions = [0, 10, 15, 20];

  /// `tongueLockTime` allowed integer levels: 3..10
  static final List<int> tongueLockTimeOptions = [for (var i = 3; i <= 10; i++) i];

  /// `tongueUlockTime` allowed pause times: 30, 40, 50
  static const List<int> tongueUlockTimeOptions = [30, 40, 50];

  /// `unLockDirection` options: 0 = forward, 1 = reverse
  static const List<int> unLockDirectionOptions = [0, 1];

  /// Generic triple-state fields that use 0/1/2 semantics (do not change/enable/disable)
  static const List<int> triStateOptions = [0, 1, 2];

  const SetSysParamModel({
    this.lockOpen,
    this.normallyOpen,
    this.isSound,
    this.sysVolume,
    this.isTamperWarn,
    this.isLockCoreWarn,
    this.isLock,
    this.isLockCap,
    this.systemLanguage,
    this.replaceSet,
    this.antiCopyFunction,
    this.keyTrialErrorAlarmEn,
    this.noneCloseVoiceAlarmEn,
    this.adminPassword,
    this.cmdType,
    this.lockWaitTime,
    this.setFlag,
    this.setKeyTriggerTime,
    this.squareTongueBlockingCurrentLevel,
    this.squareTongueExcerciseTime,
    this.squareTongueHold,
    this.tongueLockTime,
    this.tongueUlockTime,
    this.unLockDirection,
  });

  /// Populate a [SetSysParamModel] from a plain [Map] (e.g. JSON decode).
  /// Missing keys are treated as `null` (leave device value unchanged).
  factory SetSysParamModel.fromMap(Map<String, dynamic> map) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return SetSysParamModel(
      lockOpen: parseInt(map['lockOpen']),
      normallyOpen: parseInt(map['normallyOpen']),
      isSound: parseInt(map['isSound']),
      sysVolume: parseInt(map['sysVolume']),
      isTamperWarn: parseInt(map['isTamperWarn']),
      isLockCoreWarn: parseInt(map['isLockCoreWarn']),
      isLock: parseInt(map['isLock']),
      isLockCap: parseInt(map['isLockCap']),
      systemLanguage: parseInt(map['systemLanguage']),
      replaceSet: parseInt(map['replaceSet']),
      antiCopyFunction: parseInt(map['antiCopyFunction']),
      keyTrialErrorAlarmEn: parseInt(map['keyTrialErrorAlarmEn']),
      noneCloseVoiceAlarmEn: parseInt(map['noneCloseVoiceAlarmEn']),
      adminPassword: map['adminPassword'] is String ? map['adminPassword'] as String : null,
      cmdType: parseInt(map['cmdType']),
      lockWaitTime: parseInt(map['lockWaitTime']),
      setFlag: parseInt(map['setFlag']),
      setKeyTriggerTime: parseInt(map['setKeyTriggerTime']),
      squareTongueBlockingCurrentLevel: parseInt(map['squareTongueBlockingCurrentLevel']),
      squareTongueExcerciseTime: parseInt(map['squareTongueExcerciseTime']),
      squareTongueHold: parseInt(map['squareTongueHold']),
      tongueLockTime: parseInt(map['tongueLockTime']),
      tongueUlockTime: parseInt(map['tongueUlockTime']),
      unLockDirection: parseInt(map['unLockDirection']),
    );
  }

  /// Convenience factory to pre-fill a model from an existing [SysParamResult]
  /// so that a "save changes" flow starts with current device values.
  factory SetSysParamModel.fromSysParamResult(Map<String, dynamic> body) =>
      SetSysParamModel.fromMap(body);

  /// Serialize to a flat [Map] suitable for passing over the MethodChannel.
  /// Only non-null fields are included so the native side can skip them.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (lockOpen != null) map['lockOpen'] = lockOpen;
    if (normallyOpen != null) map['normallyOpen'] = normallyOpen;
    if (isSound != null) map['isSound'] = isSound;
    if (sysVolume != null) map['sysVolume'] = sysVolume;
    if (isTamperWarn != null) map['isTamperWarn'] = isTamperWarn;
    if (isLockCoreWarn != null) map['isLockCoreWarn'] = isLockCoreWarn;
    if (isLock != null) map['isLock'] = isLock;
    if (isLockCap != null) map['isLockCap'] = isLockCap;
    if (systemLanguage != null) map['systemLanguage'] = systemLanguage;
    if (replaceSet != null) map['replaceSet'] = replaceSet;
    if (antiCopyFunction != null) map['antiCopyFunction'] = antiCopyFunction;
    if (keyTrialErrorAlarmEn != null) {
      map['keyTrialErrorAlarmEn'] = keyTrialErrorAlarmEn;
    }
    if (noneCloseVoiceAlarmEn != null) {
      map['noneCloseVoiceAlarmEn'] = noneCloseVoiceAlarmEn;
    }
    if (adminPassword != null) map['adminPassword'] = adminPassword;
    if (cmdType != null) map['cmdType'] = cmdType;
    if (lockWaitTime != null) map['lockWaitTime'] = lockWaitTime;
    if (setFlag != null) map['setFlag'] = setFlag;
    if (setKeyTriggerTime != null) map['setKeyTriggerTime'] = setKeyTriggerTime;
    if (squareTongueBlockingCurrentLevel != null) {
      map['squareTongueBlockingCurrentLevel'] = squareTongueBlockingCurrentLevel;
    }
    if (squareTongueExcerciseTime != null) {
      map['squareTongueExcerciseTime'] = squareTongueExcerciseTime;
    }
    if (squareTongueHold != null) map['squareTongueHold'] = squareTongueHold;
    if (tongueLockTime != null) map['tongueLockTime'] = tongueLockTime;
    if (tongueUlockTime != null) map['tongueUlockTime'] = tongueUlockTime;
    if (unLockDirection != null) map['unLockDirection'] = unLockDirection;
    return map;
  }

  /// Returns a copy with selected fields overridden.
  SetSysParamModel copyWith({
    int? lockOpen,
    int? normallyOpen,
    int? isSound,
    int? sysVolume,
    int? isTamperWarn,
    int? isLockCoreWarn,
    int? isLock,
    int? isLockCap,
    int? systemLanguage,
    int? replaceSet,
    int? antiCopyFunction,
    int? keyTrialErrorAlarmEn,
    int? noneCloseVoiceAlarmEn,
    String? adminPassword,
    int? cmdType,
    int? lockWaitTime,
    int? setFlag,
    int? setKeyTriggerTime,
    int? squareTongueBlockingCurrentLevel,
    int? squareTongueExcerciseTime,
    int? squareTongueHold,
    int? tongueLockTime,
    int? tongueUlockTime,
    int? unLockDirection,
  }) {
    return SetSysParamModel(
      lockOpen: lockOpen ?? this.lockOpen,
      normallyOpen: normallyOpen ?? this.normallyOpen,
      isSound: isSound ?? this.isSound,
      sysVolume: sysVolume ?? this.sysVolume,
      isTamperWarn: isTamperWarn ?? this.isTamperWarn,
      isLockCoreWarn: isLockCoreWarn ?? this.isLockCoreWarn,
      isLock: isLock ?? this.isLock,
      isLockCap: isLockCap ?? this.isLockCap,
      systemLanguage: systemLanguage ?? this.systemLanguage,
      replaceSet: replaceSet ?? this.replaceSet,
      antiCopyFunction: antiCopyFunction ?? this.antiCopyFunction,
      keyTrialErrorAlarmEn: keyTrialErrorAlarmEn ?? this.keyTrialErrorAlarmEn,
      noneCloseVoiceAlarmEn:
          noneCloseVoiceAlarmEn ?? this.noneCloseVoiceAlarmEn,
      adminPassword: adminPassword ?? this.adminPassword,
      cmdType: cmdType ?? this.cmdType,
      lockWaitTime: lockWaitTime ?? this.lockWaitTime,
      setFlag: setFlag ?? this.setFlag,
      setKeyTriggerTime: setKeyTriggerTime ?? this.setKeyTriggerTime,
      squareTongueBlockingCurrentLevel: squareTongueBlockingCurrentLevel ?? this.squareTongueBlockingCurrentLevel,
      squareTongueExcerciseTime: squareTongueExcerciseTime ?? this.squareTongueExcerciseTime,
      squareTongueHold: squareTongueHold ?? this.squareTongueHold,
      tongueLockTime: tongueLockTime ?? this.tongueLockTime,
      tongueUlockTime: tongueUlockTime ?? this.tongueUlockTime,
      unLockDirection: unLockDirection ?? this.unLockDirection,
    );
  }

  @override
  String toString() => 'SetSysParamModel(${toMap()})';
}
