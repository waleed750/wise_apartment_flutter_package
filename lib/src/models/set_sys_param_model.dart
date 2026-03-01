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
    if (lockOpen != null)            map['lockOpen']            = lockOpen;
    if (normallyOpen != null)        map['normallyOpen']        = normallyOpen;
    if (isSound != null)             map['isSound']             = isSound;
    if (sysVolume != null)           map['sysVolume']           = sysVolume;
    if (isTamperWarn != null)        map['isTamperWarn']        = isTamperWarn;
    if (isLockCoreWarn != null)      map['isLockCoreWarn']      = isLockCoreWarn;
    if (isLock != null)              map['isLock']              = isLock;
    if (isLockCap != null)           map['isLockCap']           = isLockCap;
    if (systemLanguage != null)      map['systemLanguage']      = systemLanguage;
    if (replaceSet != null)          map['replaceSet']          = replaceSet;
    if (antiCopyFunction != null)    map['antiCopyFunction']    = antiCopyFunction;
    if (keyTrialErrorAlarmEn != null)  map['keyTrialErrorAlarmEn']  = keyTrialErrorAlarmEn;
    if (noneCloseVoiceAlarmEn != null) map['noneCloseVoiceAlarmEn'] = noneCloseVoiceAlarmEn;
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
      noneCloseVoiceAlarmEn: noneCloseVoiceAlarmEn ?? this.noneCloseVoiceAlarmEn,
    );
  }

  @override
  String toString() => 'SetSysParamModel(${toMap()})';
}
