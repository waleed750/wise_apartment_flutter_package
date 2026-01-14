// Base for all typed HX record models
import 'package:wise_apartment/src/models/log_type.dart';

abstract class HXRecordBaseModel {
  final int recordTime;
  final int recordType;
  final int logVersion;
  final String modelType;
  final int? eventFlag;
  final int? power;
  final Map<String, dynamic> raw;

  const HXRecordBaseModel({
    required this.recordTime,
    required this.recordType,
    required this.logVersion,
    required this.modelType,
    this.eventFlag,
    this.power,
    required this.raw,
  });

  /// Returns a map of the base fields (used by concrete models' `toMap`).
  Map<String, dynamic> baseToMap() {
    final m = <String, dynamic>{};
    m['recordTime'] = recordTime;
    m['recordType'] = recordType;
    m['logVersion'] = logVersion;
    m['modelType'] = modelType;
    if (eventFlag != null) m['eventFlag'] = eventFlag;
    if (power != null) m['power'] = power;
    return m;
  }

  Map<String, dynamic> toMap();

  String get typeName => LogType.nameOf(recordType);
}
