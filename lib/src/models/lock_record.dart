import 'log_type.dart';

class LockRecord {
  final int recordTime;
  final int recordType;
  final int logVersion;
  final String modelType;
  final int? eventFlag;
  final int? power;

  /// All additional raw fields reported by the native SDK
  /// (excluding the normalized base fields above).
  final Map<String, dynamic> data;

  const LockRecord({
    required this.recordTime,
    required this.recordType,
    required this.logVersion,
    required this.modelType,
    this.eventFlag,
    this.power,
    required this.data,
  });

  factory LockRecord.fromMap(Map<String, dynamic> map) {
    final int recordTime = (map['recordTime'] is int)
        ? map['recordTime'] as int
        : (map['recordTime'] is num)
        ? (map['recordTime'] as num).toInt()
        : 0;
    final int recordType = (map['recordType'] is int)
        ? map['recordType'] as int
        : (map['recordType'] is num)
        ? (map['recordType'] as num).toInt()
        : 0;
    final int logVersion = (map['logVersion'] is int)
        ? map['logVersion'] as int
        : (map['logVersion'] is num)
        ? (map['logVersion'] as num).toInt()
        : 0;

    final String modelType = map['modelType']?.toString() ?? '';

    final int? eventFlag = map['eventFlag'] is int
        ? map['eventFlag'] as int
        : (map['eventFlag'] is num)
        ? (map['eventFlag'] as num).toInt()
        : null;

    final int? power = map['power'] is int
        ? map['power'] as int
        : (map['power'] is num)
        ? (map['power'] as num).toInt()
        : null;

    final Map<String, dynamic> raw = Map<String, dynamic>.from(map);
    raw.remove('recordTime');
    raw.remove('recordType');
    raw.remove('logVersion');
    raw.remove('modelType');
    raw.remove('eventFlag');
    raw.remove('power');

    return LockRecord(
      recordTime: recordTime,
      recordType: recordType,
      logVersion: logVersion,
      modelType: modelType,
      eventFlag: eventFlag,
      power: power,
      data: raw,
    );
  }

  static List<LockRecord> listFromDynamic(List<dynamic> list) {
    return list
        .whereType<Map>()
        .map((dynamic value) => Map<String, dynamic>.from(value as Map))
        .map(LockRecord.fromMap)
        .toList(growable: false);
  }

  /// Human-readable name for `recordType` using `LogType.nameOf`.
  String get typeName => LogType.nameOf(recordType);

  /// Convenience: compare this record's type.
  bool isType(int t) => recordType == t;

  /// Convenience: true if this record's type is one of [types].
  bool isOneOf(Iterable<int> types) => types.contains(recordType);

  /// Returns true when the underlying data contains a non-null key.
  bool hasData(String key) => data.containsKey(key) && data[key] != null;

  /// Typed getter for data entries with an optional default value.
  T? dataAs<T>(String key, [T? defaultValue]) {
    if (!data.containsKey(key)) return defaultValue;
    final dynamic v = data[key];
    if (v is T) return v;
    return defaultValue;
  }

  /// Reconstruct a flattened Map similar to the native payload.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> m = Map<String, dynamic>.from(data);
    m['recordTime'] = recordTime;
    m['recordType'] = recordType;
    m['logVersion'] = logVersion;
    m['modelType'] = modelType;
    if (eventFlag != null) m['eventFlag'] = eventFlag;
    if (power != null) m['power'] = power;
    return m;
  }

  @override
  String toString() {
    return 'LockRecord(time=$recordTime, type=$recordType, v$logVersion, model=$modelType, eventFlag=$eventFlag, power=$power, data=$data)';
  }
}
