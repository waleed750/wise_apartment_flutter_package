// Factory to create gen2 HXRecord2 models
import 'package:wise_apartment/src/models/lock_record.dart';
import 'package:wise_apartment/features/smart_lock/data/models/records/shared/record_base_parsers.dart';
import 'hx_record2_base_model.dart';
import 'hx_record2_add_key_model.dart';
import 'hx_record2_alarm_model.dart';
import 'hx_record2_unknown_model.dart';
import 'package:wise_apartment/src/models/log_type.dart';

HXRecord2BaseModel hxRecord2FromMap(Map<String, dynamic> map) {
  final String modelType = asString(map['modelType']);
  // Prefer explicit modelType string if provided
  switch (modelType) {
    case 'HXRecord2AddKeyModel':
      return HXRecord2AddKeyModel.fromMap(map);
    case 'HXRecord2AlarmModel':
      return HXRecord2AlarmModel.fromMap(map);
    // add other explicit names here as implemented
  }

  // Fallback to recordType mapping
  final int recordType = asInt(map['recordType']);
  // Alarm type list: 1,2,3,7,12,14,15,18,25
  const alarmTypes = {1, 2, 3, 7, 12, 14, 15, 18, 25};
  if (alarmTypes.contains(recordType)) return HXRecord2AlarmModel.fromMap(map);

  if (recordType == LogType.addUser) return HXRecord2AddKeyModel.fromMap(map);

  // Unknown fallback
  return HXRecord2UnknownModel(
    recordTime: asInt(map['recordTime']),
    recordType: recordType,
    logVersion: asInt(map['logVersion']),
    modelType: modelType,
    eventFlag: asIntOrNull(map['eventFlag']),
    power: asIntOrNull(map['power']),
    raw: Map<String, dynamic>.from(map)..removeWhere((k, _) => false),
  );
}

HXRecord2BaseModel hxRecord2FromLockRecord(LockRecord record) {
  final map = record.toMap();
  return hxRecord2FromMap(map);
}
