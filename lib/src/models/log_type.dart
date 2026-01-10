/// Mirror of com.example.hxjblinklibrary.blinkble.profile.data.common.LogType
/// so Dart code can work with the same numeric constants.
class LogType {
  const LogType._();

  static const int noDistinction = 0;
  static const int pickupAlarm = 1;
  static const int numberOfErrorsExceeded = 2;
  static const int notEnoughPower = 3;
  static const int unlockEvent = 4;
  static const int arming = 5;
  static const int disarmed = 6;
  static const int hijackingUnlockAlarm = 7;
  static const int addUser = 8;
  static const int deleteUser = 9;
  static const int antiLock = 10;
  static const int antiLockRelieved = 11;
  static const int pryLockCoreAlarm = 12;
  static const int doorbellEvent = 13;
  static const int falseLockAlarm = 14;
  static const int notClosedAlarm = 15;
  static const int doorLockAlwaysOpenEvent = 16;
  static const int closedNormallyOpen = 17;
  static const int lockFault = 18;
  static const int appSyncLockStatusEvent = 19;
  static const int languageSystemEvent = 20;
  static const int sysLockStatusReleased = 21;
  static const int timeSyncEvent = 22;
  static const int restoreFactorySettingEvent = 23;
  static const int changePasswordEvent = 24;
  static const int keyNotTakenEvent = 25;
  static const int openCappingEvent = 26;
  static const int sysParamSettingEvent = 27;
  static const int keyEnableAndDisableEvent = 28;
  static const int lockEvent = 30;
  static const int toughInEvent = 31;
  static const int mechanicalUnlockingEvent = 32;
  static const int lockEnable = 33;
  static const int modifyValidityEvent = 34;
  static const int wrongKeyUnlock = 43;
  static const int modifyKeyValue = 47;

  /// Optional helper to get a short label from a code.
  static String nameOf(int code) {
    return _names[code] ?? 'NO_DISTINCTION';
  }

  static const Map<int, String> _names = {
    noDistinction: 'NO_DISTINCTION',
    pickupAlarm: 'PICKUP_ALARM',
    numberOfErrorsExceeded: 'NUMBER_OF_ERRORS_EXCEEDED',
    notEnoughPower: 'NOT_ENOUGH_POWER',
    unlockEvent: 'UNLOCK_EVENT',
    arming: 'ARMING',
    disarmed: 'DISARMED',
    hijackingUnlockAlarm: 'HIJACKING_UNLOCK_ALARM',
    addUser: 'ADD_USER',
    deleteUser: 'DELETE_USER',
    antiLock: 'ANTI_LOCK',
    antiLockRelieved: 'ANTI_LOCK_RELIEVED',
    pryLockCoreAlarm: 'PRY_LOCK_CORE_ALARM',
    doorbellEvent: 'DOORBELL_EVENT',
    falseLockAlarm: 'FALSE_LOCK_ALARM',
    notClosedAlarm: 'NOT_CLOSED_ALARM',
    doorLockAlwaysOpenEvent: 'DOOR_LOCK_ALWAYS_OPEN_EVENT',
    closedNormallyOpen: 'CLOSED_NORMALLY_OPEN',
    lockFault: 'LOCK_FAULT',
    appSyncLockStatusEvent: 'APP_SYNC_LOCK_STATUS_EVENT',
    languageSystemEvent: 'LANGUAGE_SYSTEM_EVENT',
    sysLockStatusReleased: 'SYS_LOCK_STATUS_RELEASED',
    timeSyncEvent: 'TIME_SYNC_EVENT',
    restoreFactorySettingEvent: 'RESTORE_FACTORY_SETTING_EVENT',
    changePasswordEvent: 'CHANGE_PASSWORD_EVENT',
    keyNotTakenEvent: 'KEY_NOT_TAKEN_EVENT',
    openCappingEvent: 'OPEN_CAPPING_EVENT',
    sysParamSettingEvent: 'SYS_PARAM_SETTING_EVENT',
    keyEnableAndDisableEvent: 'KEY_ENABLE_AND_DISABLE_EVENT',
    lockEvent: 'LOCK_EVENT',
    toughInEvent: 'TOUGH_IN_EVENT',
    mechanicalUnlockingEvent: 'MECHANICAL_UNLOCKING_EVENT',
    lockEnable: 'LOCK_ENABLE',
    modifyValidityEvent: 'MODIFY_VALIDITY_EVENT',
    wrongKeyUnlock: 'WRONG_KEY_UNLOCK',
    modifyKeyValue: 'MODIFY_KEY_VALUE',
  };
}
