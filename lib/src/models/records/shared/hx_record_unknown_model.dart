// Unknown fallback HX record model
import 'hx_record_base_model.dart';

class HXRecordUnknownModel extends HXRecordBaseModel {
  const HXRecordUnknownModel({
    required super.recordTime,
    required super.recordType,
    required super.logVersion,
    required super.modelType,
    super.eventFlag,
    super.power,
    required super.raw,
  });

  @override
  Map<String, dynamic> toMap() {
    final m = baseToMap();
    m.addAll(raw);
    return m;
  }
}
