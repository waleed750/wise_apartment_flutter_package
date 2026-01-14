// Unknown fallback for gen2
import 'hx_record2_base_model.dart';

class HXRecord2UnknownModel extends HXRecord2BaseModel {
  const HXRecord2UnknownModel({
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
