import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_apartment/wise_apartment_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelWiseApartment platform = MethodChannelWiseApartment();
  const MethodChannel channel = MethodChannel('wise_apartment/methods');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getPlatformVersion':
              return '42';
            case 'syncLockRecords':
              return [
                {
                  'recordTime': 123,
                  'recordType': 1,
                  'logVersion': 2,
                  'modelType': 'HXRecord2UnlockModel',
                },
              ];
            case 'syncLockRecordsPage':
              return {
                'total': 100,
                'nextIndex': 10,
                'hasMore': true,
                'records': [
                  {
                    'recordTime': 123,
                    'recordType': 1,
                    'logVersion': 2,
                    'modelType': 'HXRecord2UnlockModel',
                  },
                ],
              };
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('syncLockRecords returns list of maps', () async {
    final records = await platform.syncLockRecords(<String, dynamic>{}, 2);
    expect(records, isA<List<Map<String, dynamic>>>());
    expect(records, isNotEmpty);
    expect(records.first['recordTime'], 123);
    expect(records.first['logVersion'], 2);
  });
}
