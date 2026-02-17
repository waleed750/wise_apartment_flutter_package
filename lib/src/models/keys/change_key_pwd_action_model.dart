class ChangeKeyPwdActionModel {
  final int lockKeyId;
  final String oldPassword;
  final String newPassword;
  final String lockMac;

  /// Required for Android/iOS native layer calls.
  /// Note: `status` is fixed to 0 in Android native layer usually, but if needed we can add it here.
  const ChangeKeyPwdActionModel({
    required this.lockKeyId,
    required this.oldPassword,
    required this.newPassword,
    required this.lockMac,
  });

  factory ChangeKeyPwdActionModel.fromMap(Map<String, dynamic> map) {
    return ChangeKeyPwdActionModel(
      lockKeyId: map['lockKeyId'] as int,
      oldPassword: map['oldPassword'] as String,
      newPassword: map['newPassword'] as String,
      lockMac: map['lockMac'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lockKeyId': lockKeyId,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
      'lockMac': lockMac,
      'status': 0, // Fixed fill 0 as per requirement
    };
  }

  @override
  String toString() {
    return 'ChangeKeyPwdActionModel(lockKeyId: $lockKeyId, oldPassword: $oldPassword, newPassword: $newPassword, lockMac: $lockMac)';
  }
}
