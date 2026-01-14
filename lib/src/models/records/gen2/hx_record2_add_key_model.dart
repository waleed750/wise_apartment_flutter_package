// Doc fields: operKeyGroupId, addedKeyGroupId, lockKeyId, keyType, keyLen, key
import 'package:wise_apartment/src/models/records/shared/record_base_parsers.dart';
import 'package:wise_apartment/src/models/records/gen2/hx_record2_base_model.dart';

class HXRecord2AddKeyModel extends HXRecord2BaseModel {
  final int operKeyGroupId;
  final int addedKeyGroupId;
  final int lockKeyId;
  final int keyType;
  final int keyLen;
  final String key;

  const HXRecord2AddKeyModel({
    required super.recordTime,
    required super.recordType,
    required super.logVersion,
    required super.modelType,
    super.eventFlag,
    super.power,
    required super.raw,
    required this.operKeyGroupId,
    required this.addedKeyGroupId,
    required this.lockKeyId,
    required this.keyType,
    required this.keyLen,
    required this.key,
  });

  factory HXRecord2AddKeyModel.fromMap(Map<String, dynamic> map) {
    final int recordTime = asInt(map['recordTime']);
    final int recordType = asInt(map['recordType']);
    final int logVersion = asInt(map['logVersion']);
    final String modelType = asString(map['modelType']);
    final int? eventFlag = asIntOrNull(map['eventFlag']);
    final int? power = asIntOrNull(map['power']);

    final int operKeyGroupId = asInt(map['operKeyGroupId']);
    final int addedKeyGroupId = asInt(map['addedKeyGroupId']);
    final int lockKeyId = asInt(map['lockKeyId']);
    final int keyType = asInt(map['keyType']);
    final int keyLen = asInt(map['keyLen']);
    final String key = asString(map['key']);

    final raw = Map<String, dynamic>.from(map);
    for (final k in [
      'recordTime',
      'recordType',
      'logVersion',
      'modelType',
      'eventFlag',
      'power',
      'operKeyGroupId',
      'addedKeyGroupId',
      'lockKeyId',
      'keyType',
      'keyLen',
      'key',
    ]) {
      raw.remove(k);
    }

    return HXRecord2AddKeyModel(
      recordTime: recordTime,
      recordType: recordType,
      logVersion: logVersion,
      modelType: modelType,
      eventFlag: eventFlag,
      power: power,
      raw: raw,
      operKeyGroupId: operKeyGroupId,
      addedKeyGroupId: addedKeyGroupId,
      lockKeyId: lockKeyId,
      keyType: keyType,
      keyLen: keyLen,
      key: key,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final m = baseToMap();
    m['operKeyGroupId'] = operKeyGroupId;
    m['addedKeyGroupId'] = addedKeyGroupId;
    m['lockKeyId'] = lockKeyId;
    m['keyType'] = keyType;
    m['keyLen'] = keyLen;
    m['key'] = key;
    m.addAll(raw);
    return m;
  }
}
