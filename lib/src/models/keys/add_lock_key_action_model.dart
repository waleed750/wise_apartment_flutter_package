/// Model representing parameters for adding a lock key action.
class AddLockKeyActionModel {
  String? password;
  int status;
  int localRemoteMode;
  int? authorMode; // nullable per request
  int keyDataType;
  int vaildMode;
  int addedKeyType;
  int addedKeyID;
  int addedKeyGroupId;
  int modifyTimestamp;
  int validStartTime;
  int validEndTime;
  int week;
  int dayStartTimes;
  int dayEndTimes;
  int vaildNumber;

  AddLockKeyActionModel({
    this.password,
    this.status = 0,
    this.localRemoteMode = 1,
    this.authorMode,
    this.keyDataType = 0,
    this.vaildMode = 0,
    this.addedKeyType = 0,
    this.addedKeyID = 0,
    this.addedKeyGroupId = 0,
    this.modifyTimestamp = 0,
    this.validStartTime = 0,
    this.validEndTime = 0,
    this.week = 0,
    this.dayStartTimes = 0,
    this.dayEndTimes = 0,
    this.vaildNumber = 0,
  });

  factory AddLockKeyActionModel.fromMap(Map<String, dynamic>? m) {
    if (m == null) return AddLockKeyActionModel();
    int? parseInt(Object? v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return AddLockKeyActionModel(
      password: m['password']?.toString(),
      status: parseInt(m['status']) ?? 0,
      localRemoteMode: parseInt(m['localRemoteMode']) ?? 1,
      authorMode: m.containsKey('authorMode')
          ? parseInt(m['authorMode'])
          : null,
      keyDataType: parseInt(m['keyDataType']) ?? 0,
      vaildMode: parseInt(m['vaildMode']) ?? 0,
      addedKeyType: parseInt(m['addedKeyType']) ?? 0,
      addedKeyID: parseInt(m['addedKeyID']) ?? 0,
      addedKeyGroupId: parseInt(m['addedKeyGroupId']) ?? 0,
      modifyTimestamp: parseInt(m['modifyTimestamp']) ?? 0,
      validStartTime: parseInt(m['validStartTime']) ?? 0,
      validEndTime: parseInt(m['validEndTime']) ?? 0,
      week: parseInt(m['week']) ?? 0,
      dayStartTimes: parseInt(m['dayStartTimes']) ?? 0,
      dayEndTimes: parseInt(m['dayEndTimes']) ?? 0,
      vaildNumber: parseInt(m['vaildNumber']) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'password': password,
    'status': status,
    'localRemoteMode': localRemoteMode,
    if (authorMode != null) 'authorMode': authorMode,
    'keyDataType': keyDataType,
    'vaildMode': vaildMode,
    'addedKeyType': addedKeyType,
    'addedKeyID': addedKeyID,
    'addedKeyGroupId': addedKeyGroupId,
    'modifyTimestamp': modifyTimestamp,
    'validStartTime': validStartTime,
    'validEndTime': validEndTime,
    'week': week,
    'dayStartTimes': dayStartTimes,
    'dayEndTimes': dayEndTimes,
    'vaildNumber': vaildNumber,
  };

  /// Validate the model fields according to the rules expected by the lock.
  ///
  /// Returns a list of validation error messages. If the list is empty, the
  /// model is considered valid.
  List<String> validate({int? authMode}) {
    final errors = <String>[];

    // authorMode == 1 requires a 6-12 digit password (or card number)
    if (authorMode == 1) {
      if (password == null || !RegExp(r'^\d{6,12}\$').hasMatch(password!)) {
        errors.add(
          'When authorMode==1, password (or card number) is required and must be 6-12 digits.',
        );
      }
    }

    // vaildMode==1 requires valid week and daily start/end times
    if (vaildMode == 1) {
      if (week == 0) errors.add('vaildMode==1 requires non-zero week bitmask.');
      if (dayStartTimes < 0 || dayStartTimes > 1439)
        errors.add('dayStartTimes must be in 0..1439.');
      if (dayEndTimes < 0 || dayEndTimes > 1439)
        errors.add('dayEndTimes must be in 0..1439.');
      if (dayEndTimes <= dayStartTimes)
        errors.add('dayEndTimes must be greater than dayStartTimes.');
    }

    // start/end time rules
    if (validStartTime < 0) errors.add('validStartTime must be >= 0.');
    if (!(validEndTime == 0xFFFFFFFF || validEndTime >= validStartTime)) {
      errors.add('validEndTime must be 0xFFFFFFFF or >= validStartTime.');
    }

    // valid number range
    if (vaildNumber < 0 || vaildNumber > 0xFF)
      errors.add('vaildNumber must be between 0 and 255.');

    // optional authMode-aware check for addedKeyType
    if (authMode != null) {
      final allowedAuth0 = {addedFingerprint, addedCard, addedRemote};
      final allowedAuth1 = {addedPassword, addedCard};
      if (authMode == 0) {
        if (!allowedAuth0.contains(addedKeyType))
          errors.add('For authMode==0, addedKeyType must be one of: 1,4,8.');
      } else if (authMode == 1) {
        if (!allowedAuth1.contains(addedKeyType))
          errors.add('For authMode==1, addedKeyType must be one of: 2,4.');
      }
    }

    // status/localRemoteMode basic sanity
    if (localRemoteMode < 0) errors.add('localRemoteMode must be >= 0.');
    if (status < 0) errors.add('status must be >= 0.');

    return errors;
  }

  /// Validate and throw [ArgumentError] on first failure.
  void validateOrThrow({int? authMode}) {
    final errs = validate(authMode: authMode);
    if (errs.isNotEmpty) throw ArgumentError(errs.join('; '));
  }

  /// Helper constants and methods for `addedKeyType`.
  ///
  /// Mapping:
  /// - When authMode == 0 (lock in normal mode):
  ///   1 -> fingerprint
  ///   4 -> card
  ///   8 -> remote control
  /// - When authMode == 1 (password mode):
  ///   2 -> password
  ///   4 -> card number
  static const int addedFingerprint = 1;
  static const int addedCard = 4;
  static const int addedRemote = 8;
  static const int addedPassword = 2;

  /// Compute the proper `addedKeyType` value for a given `authMode` and a textual choice.
  /// `choice` can be one of: 'fingerprint','card','remote','password','cardNumber'.
  static int computeAddedKeyType({
    required int authMode,
    required String choice,
  }) {
    final c = choice.toLowerCase();
    if (authMode == 0) {
      if (c == 'fingerprint') return addedFingerprint;
      if (c == 'card') return addedCard;
      if (c == 'remote' || c == 'remotecontrol' || c == 'remote_control')
        return addedRemote;
    } else if (authMode == 1) {
      if (c == 'password') return addedPassword;
      if (c == 'card' || c == 'cardnumber' || c == 'card_number')
        return addedCard;
    }
    return 0;
  }

  /// Compute flag as per original Java logic.
  int getFlag() {
    int var1 = (localRemoteMode == 1) ? 1 : 0;
    int var2 = (authorMode == 1) ? 2 : 0;
    int var3 = (vaildMode == 1) ? 4 : 0;
    int var4 = (keyDataType == 1) ? 8 : 0;
    return var1 | var2 | var3 | var4;
  }
}
