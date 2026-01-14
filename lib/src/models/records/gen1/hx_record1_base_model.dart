// Gen1 base model
import 'package:wise_apartment/src/models/records/shared/hx_record_base_model.dart';

abstract class HXRecord1BaseModel extends HXRecordBaseModel {
  const HXRecord1BaseModel({
    required super.recordTime,
    required super.recordType,
    required super.logVersion,
    required super.modelType,
    super.eventFlag,
    super.power,
    required super.raw,
  });
}
