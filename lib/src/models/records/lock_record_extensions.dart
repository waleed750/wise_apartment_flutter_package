import 'package:wise_apartment/src/models/lock_record.dart';
import 'package:wise_apartment/src/models/records/hx_record_factory.dart';
import 'package:wise_apartment/src/models/records/shared/hx_record_base_model.dart';

extension LockRecordX on LockRecord {
  /// Parse this `LockRecord` into a typed `HXRecordBaseModel`.
  HXRecordBaseModel toTyped() => hxRecordFromLockRecord(this);

  /// Convenience checks
  bool get isGen2 => logVersion >= 2;
  bool get isGen1 => logVersion == 1;
}
