// Top-level HX record factory: dispatches between Gen1 and Gen2
import 'package:wise_apartment/src/models/lock_record.dart';
import 'package:wise_apartment/src/models/records/shared/hx_record_base_model.dart';
import 'package:wise_apartment/src/models/records/shared/record_base_parsers.dart';
import 'package:wise_apartment/src/models/records/gen2/hx_record2_factory.dart'
    as gen2;
import 'package:wise_apartment/src/models/records/gen1/hx_record1_factory.dart'
    as gen1;
import 'package:wise_apartment/src/models/records/shared/hx_record_unknown_model.dart';

HXRecordBaseModel hxRecordFromMap(Map<String, dynamic> map) {
  final int logVersion = asInt(map['logVersion']);

  try {
    if (logVersion >= 2) return gen2.hxRecord2FromMap(map);
    if (logVersion == 1) return gen1.hxRecord1FromMap(map);

    // Unknown logVersion: try modelType heuristic
    final String modelType = asString(map['modelType']);
    if (modelType.contains('Record2') ||
        modelType.toLowerCase().contains('hxrecord2')) {
      return gen2.hxRecord2FromMap(map);
    }
    return gen1.hxRecord1FromMap(map);
  } catch (_) {
    // Fallback unknown model
    return HXRecordUnknownModel(
      recordTime: asInt(map['recordTime']),
      recordType: asInt(map['recordType']),
      logVersion: logVersion,
      modelType: asString(map['modelType']),
      eventFlag: asIntOrNull(map['eventFlag']),
      power: asIntOrNull(map['power']),
      raw: Map<String, dynamic>.from(map)..removeWhere((k, _) => false),
    );
  }
}

HXRecordBaseModel hxRecordFromLockRecord(LockRecord record) {
  return hxRecordFromMap(record.toMap());
}
