/// Represents a key entry returned by the native HXJ SDK.
///
/// Fields mirror the original Android `LockKeyResult` entity. Most fields
/// are integers describing key metadata (type, validity, schedule, IDs).
class LockKeyResult {
  /// Whether there are more keys available beyond this result page.
  bool isMore;

  /// Number of the key in the result set (index/sequence).
  int keyNum;

  /// Last modification timestamp (milliseconds since epoch).
  int modifyTimestamp;

  /// Authorization/validity mode.
  /// 0: Validity period authorization
  /// 1: Periodic repetition authorization
  int vaildMode;

  /// Week bitmap used when `vaildMode == 1` (bits 0..6 correspond to days).
  int weeks;

  /// Start minute of day (minutes since 00:00) for daily validity window.
  int dayStartTimes;

  /// End minute of day (minutes since 00:00) for daily validity window.
  int dayEndTimes;

  /// Key type or addedKeyType depending on context. Typical values:
  /// - When adding fingerprint/card/remote/password, this indicates the type.
  int keyType;

  /// ID of the application-level user associated with the key.
  int appUserID;

  /// Key identifier (unique key id on the lock).
  int keyID;

  /// Number of authorizations allowed for this key.
  /// 0x01 = 1 time, 0xFF = unlimited, 0x00 = disabled.
  int vaildNumber;

  /// Validity start timestamp (seconds). 0 indicates unlimited start.
  int vaildStartTime;

  /// Validity end timestamp (seconds). 0xFFFFFFFF indicates unlimited end.
  int vaildEndTime;

  /// Delete mode (native SDK meaning).
  int deleteMode;

  /// The raw key material (e.g., password, card number) when present.
  String? key;

  /// Additional fields used during key addition flows.
  /// `authorMode` selects the adding method; may be `null` when not present.
  /// 0: Enter fingerprint/card/remote control reading mode
  /// 1: Add password or card number
  int? authorMode;

  /// Added key type (more explicit than `keyType` for add operations):
  /// - When `authorMode==0`: 1=fingerprint, 4=card, 8=remote control
  /// - When `authorMode==1`: 2=password, 4=card number
  int addedKeyType;

  /// When `authorMode==1`, the password or card number to add (6-12 digits).
  String? password;

  /// Group id corresponding to the key (the user group the key belongs to).
  int addedKeyGroupId;

  LockKeyResult({
    this.isMore = false,
    this.keyNum = 0,
    this.modifyTimestamp = 0,
    this.vaildMode = 0,
    this.weeks = 0,
    this.dayStartTimes = 0,
    this.dayEndTimes = 0,
    this.keyType = 0,
    this.appUserID = 0,
    this.keyID = 0,
    this.vaildNumber = 0,
    this.vaildStartTime = 0,
    this.vaildEndTime = 0,
    this.deleteMode = 0,
    this.key,
    this.authorMode,
    this.addedKeyType = 0,
    this.password,
    this.addedKeyGroupId = 0,
  });

  factory LockKeyResult.fromMap(Map<String, dynamic>? m) {
    if (m == null) return LockKeyResult();
    return LockKeyResult(
      isMore: m['isMore'] == true || m['more'] == true,
      keyNum: (m['keyNum'] is int)
          ? m['keyNum']
          : int.tryParse('${m['keyNum']}') ?? 0,
      modifyTimestamp: (m['modifyTimestamp'] is int)
          ? m['modifyTimestamp']
          : int.tryParse('${m['modifyTimestamp']}') ?? 0,
      vaildMode: (m['vaildMode'] is int)
          ? m['vaildMode']
          : int.tryParse('${m['vaildMode']}') ?? 0,
      weeks: (m['weeks'] is int)
          ? m['weeks']
          : int.tryParse('${m['weeks']}') ?? 0,
      dayStartTimes: (m['dayStartTimes'] is int)
          ? m['dayStartTimes']
          : int.tryParse('${m['dayStartTimes']}') ?? 0,
      dayEndTimes: (m['dayEndTimes'] is int)
          ? m['dayEndTimes']
          : int.tryParse('${m['dayEndTimes']}') ?? 0,
      keyType: (m['keyType'] is int)
          ? m['keyType']
          : int.tryParse('${m['keyType']}') ?? 0,
      appUserID: (m['appUserID'] is int)
          ? m['appUserID']
          : int.tryParse('${m['appUserID']}') ?? 0,
      keyID: (m['keyID'] is int)
          ? m['keyID']
          : int.tryParse('${m['keyID']}') ?? 0,
      vaildNumber: (m['vaildNumber'] is int)
          ? m['vaildNumber']
          : int.tryParse('${m['vaildNumber']}') ?? 0,
      vaildStartTime: (m['vaildStartTime'] is int)
          ? m['vaildStartTime']
          : int.tryParse('${m['vaildStartTime']}') ?? 0,
      vaildEndTime: (m['vaildEndTime'] is int)
          ? m['vaildEndTime']
          : int.tryParse('${m['vaildEndTime']}') ?? 0,
      deleteMode: (m['deleteMode'] is int)
          ? m['deleteMode']
          : int.tryParse('${m['deleteMode']}') ?? 0,
      key: m['key']?.toString(),
      authorMode: m.containsKey('authorMode')
          ? ((m['authorMode'] is int)
                ? m['authorMode']
                : int.tryParse('${m['authorMode']}'))
          : null,
      addedKeyType: (m['addedKeyType'] is int)
          ? m['addedKeyType']
          : int.tryParse('${m['addedKeyType']}') ?? 0,
      password: m['password']?.toString(),
      addedKeyGroupId: (m['addedKeyGroupId'] is int)
          ? m['addedKeyGroupId']
          : int.tryParse('${m['addedKeyGroupId']}') ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'isMore': isMore,
    'keyNum': keyNum,
    'modifyTimestamp': modifyTimestamp,
    'vaildMode': vaildMode,
    'weeks': weeks,
    'dayStartTimes': dayStartTimes,
    'dayEndTimes': dayEndTimes,
    'keyType': keyType,
    'appUserID': appUserID,
    'keyID': keyID,
    'vaildNumber': vaildNumber,
    'vaildStartTime': vaildStartTime,
    'vaildEndTime': vaildEndTime,
    'deleteMode': deleteMode,
    'key': key,
    'authorMode': authorMode,
    'addedKeyType': addedKeyType,
    'password': password,
    'addedKeyGroupId': addedKeyGroupId,
  };

  @override
  String toString() {
    return 'LockKeyResult{isMore=$isMore, keyNum=$keyNum, modifyTimestamp=$modifyTimestamp, vaildMode=$vaildMode, weeks=$weeks, dayStartTimes=$dayStartTimes, dayEndTimes=$dayEndTimes, keyType=$keyType, appUserID=$appUserID, keyID=$keyID, vaildNumber=$vaildNumber, vaildStartTime=$vaildStartTime, vaildEndTime=$vaildEndTime, deleteMode=$deleteMode, key=$key, authorMode=$authorMode, addedKeyType=$addedKeyType, password=$password, addedKeyGroupId=$addedKeyGroupId}';
  }

  // -----------------
  // Helper methods
  // -----------------

  /// Returns true when this key's validNumber represents unlimited uses.
  bool isUnlimitedUses() => vaildNumber == 0xFF;

  /// Returns true when this key is explicitly disabled (0x00).
  bool isDisabled() => vaildNumber == 0x00;

  /// Returns true when this key allows exactly one use.
  bool isSingleUse() => vaildNumber == 0x01;

  /// Returns the numeric allowed uses, or `null` when unlimited.
  int? allowedUses() => isUnlimitedUses() ? null : vaildNumber;

  // Key type flags (bitmask values used by the native SDK)
  static const int _KEY_FINGERPRINT = 0x01;
  static const int _KEY_PASSWORD = 0x02;
  static const int _KEY_CARD = 0x04;
  static const int _KEY_REMOTE = 0x08;

  int get _effectiveKeyType => (addedKeyType != 0) ? addedKeyType : keyType;

  /// True if the key represents a fingerprint.
  bool isFingerprint() => (_effectiveKeyType & _KEY_FINGERPRINT) != 0;

  /// True if the key represents a password entry.
  bool isPassword() => (_effectiveKeyType & _KEY_PASSWORD) != 0;

  /// True if the key represents a card tag.
  bool isCard() => (_effectiveKeyType & _KEY_CARD) != 0;

  /// True if the key represents a remote control entry.
  bool isRemote() => (_effectiveKeyType & _KEY_REMOTE) != 0;
}
