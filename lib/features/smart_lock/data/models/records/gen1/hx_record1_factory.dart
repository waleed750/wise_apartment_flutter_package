import 'package:wise_apartment/src/models/lock_record.dart';
import 'package:wise_apartment/features/smart_lock/data/models/records/gen1/hx_record1_base_model.dart';
import 'hx_record1_unknown_model.dart';

import 'hx_record1_add_key_model.dart';
import 'hx_record1_alarm_model.dart';
import 'hx_record1_delete_key_model.dart';
import 'hx_record1_keyenable_model.dart';
import 'hx_record1_modify_key_model.dart';
import 'hx_record1_modify_key_time_model.dart';
import 'hx_record1_modify_key_value_model.dart';
import 'hx_record1_set_sys_pram_model.dart';
import 'hx_record1_unlock_model.dart';
import 'hx_record1_wrong_key_unlock_model.dart';

HXRecord1BaseModel hxRecord1FromMap(Map<String, dynamic> map) {
  final modelType = map['modelType'] as String?;
  if (modelType != null) {
    switch (modelType) {
      case 'addKey':
        return HXRecord1AddKeyModel.fromMap(map);
      case 'alarm':
        return HXRecord1AlarmModel.fromMap(map);
      case 'deleteKey':
        return HXRecord1DeleteKeyModel.fromMap(map);
      case 'keyEnable':
        return HXRecord1KeyenableModel.fromMap(map);
      case 'modifyKey':
        return HXRecord1ModifyKeyModel.fromMap(map);
      case 'modifyKeyTime':
        return HXRecord1ModifyKeyTimeModel.fromMap(map);
      case 'modifyKeyValue':
        return HXRecord1ModifyKeyValueModel.fromMap(map);
      case 'setSysPram':
        return HXRecord1SetSysPramModel.fromMap(map);
      case 'unlock':
        return HXRecord1UnlockModel.fromMap(map);
      case 'wrongKeyUnlock':
        return HXRecord1WrongKeyUnlockModel.fromMap(map);
    }
  }

  // fallback to recordType heuristics (basic)
  final rt = map['recordType'] as int?;
  if (rt != null) {
    switch (rt) {
      case 1:
        return HXRecord1AddKeyModel.fromMap(map);
      case 2:
        return HXRecord1DeleteKeyModel.fromMap(map);
    }
  }

  return HXRecord1UnknownModel.fromMap(map);
}

HXRecord1BaseModel hxRecord1FromLockRecord(LockRecord record) {
  return hxRecord1FromMap(record.toMap());
}
