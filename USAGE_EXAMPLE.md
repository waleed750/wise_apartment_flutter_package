# WiseApartment Plugin - Usage Example

## Complete Flow with Typed API

```dart
import 'package:wise_apartment/wise_apartment.dart';

final wiseApartment = WiseApartment();

/// Complete smart lock integration flow
Future<void> demonstrateFullFlow() async {
  try {
    // STEP 1: Initialize BLE client
    await wiseApartment.initBleClient();
    print('✅ BLE Client initialized');

    // STEP 2: Scan for devices (Type-safe version)
    print('🔍 Scanning for locks...');
    final devices = await wiseApartment.startScanTyped(timeoutMs: 10000);
    print('Found ${devices.length} devices');

    // Filter for pairable locks
    final pairableDevices = devices.where((d) => d.canPair).toList();
    if (pairableDevices.isEmpty) {
      print('❌ No pairable devices found');
      return;
    }

    final device = pairableDevices.first;
    print('Selected: ${device.mac} (RSSI: ${device.rssi})');

    // STEP 3: Add device and get DNA credentials (CRITICAL!)
    print('🔐 Pairing device...');
    final dnaInfo = await wiseApartment.addDeviceTyped(
      device.mac,
      device.chipType,
    );
    print('✅ Device paired successfully!');
    print('   MAC: ${dnaInfo.mac}');
    print('   Auth Code: ${dnaInfo.authorizedRoot}');
    print('   DNA Key: ${dnaInfo.dnaAes128Key}');
    print('   Protocol: ${dnaInfo.protocolVer}');
    print('   RF Module: ${dnaInfo.rFMoudleType}');

    // CRITICAL: Save DNA info to database/secure storage
    // You'll need this for ALL future operations with this lock
    await saveDnaToDatabase(dnaInfo);

    // STEP 4: Build auth payload for operations
    final authPayload = {
      'mac': dnaInfo.mac,
      'authCode': dnaInfo.authorizedRoot,
      'dnaKey': dnaInfo.dnaAes128Key,
      'protocolVer': dnaInfo.protocolVer,
      'keyGroupId': 900, // Always 900
    };

    // STEP 5: Unlock the lock
    print('🔓 Unlocking...');
    final unlocked = await wiseApartment.openLock(authPayload);
    if (unlocked) {
      print('✅ Lock unlocked successfully!');
    } else {
      print('❌ Failed to unlock');
    }

    // STEP 6: Get module info (if NB-IoT or Cat1)
    if (dnaInfo.rFMoudleType == 0x05) {
      // NB-IoT module
      print('📡 Getting NB-IoT info...');
      final nbInfo = await wiseApartment.getNBIoTInfoTyped(authPayload);
      print('   IMEI: ${nbInfo.imei}');
      print('   IMSI: ${nbInfo.imsi}');
      print('   RSSI: ${nbInfo.rssi}');
    } else if (dnaInfo.rFMoudleType == 0x03) {
      // Cat1 module
      print('📡 Getting Cat1 info...');
      final cat1Info = await wiseApartment.getCat1InfoTyped(authPayload);
      print('   ICCID: ${cat1Info.iccid}');
      print('   IMEI: ${cat1Info.imei}');
      print('   RSSI: ${cat1Info.rssi}');
    }

    // STEP 7: Sync lock records
    print('📜 Syncing lock records...');
    final records = await wiseApartment.syncLockRecords(
      authPayload,
      0, // logVersion (0 = auto-detect from menuFeature)
    );
    print('✅ Synced ${records.length} records');

    // STEP 8: Delete lock (if needed)
    // print('🗑️ Deleting lock...');
    // final deleted = await wiseApartment.deleteLock(authPayload);
    // if (deleted) print('✅ Lock deleted');

  } catch (e) {
    print('❌ Error: $e');
  }
}

/// Save DNA info to your database
Future<void> saveDnaToDatabase(DnaInfoModel dna) async {
  // Example: Save to SQLite, Hive, SharedPreferences, etc.
  // CRITICAL: This data is required for all future lock operations!
  /*
  await database.insert('locks', {
    'mac': dna.mac,
    'authCode': dna.authorizedRoot,
    'dnaKey': dnaInfo.dnaAes128Key,
    'protocolVer': dna.protocolVer,
    'deviceType': dna.deviceType,
    'hardwareVer': dna.hardWareVer,
    'softwareVer': dna.softWareVer,
    'rfModuleType': dna.rFMoudleType,
    'rfModuleMac': dna.RFModuleMac,
    'menuFeature': dna.menuFeature,
    'rawDnaInfo': dna.deviceDnaInfoStr,
  });
  */
  print('💾 DNA saved to database (implement your storage here)');
}
```

## Backward Compatible Usage (Legacy Map-based)

```dart
import 'package:wise_apartment/wise_apartment.dart';

final wiseApartment = WiseApartment();

Future<void> legacyFlow() async {
  // Scan (returns List<Map<String, dynamic>>)
  final devices = await wiseApartment.startScan(timeoutMs: 10000);
  final device = devices.firstWhere(
    (d) => d['isDiscoverable'] == true && d['isPaired'] == false,
  );

  // Add device - NOW RETURNS DNA MAP (not bool!)
  final dnaMap = await wiseApartment.addDevice(
    device['mac'] as String,
    device['chipType'] as int,
  );

  // Build auth from DNA map
  final auth = {
    'mac': dnaMap['mac'],
    'authCode': dnaMap['authCode'],
    'dnaKey': dnaMap['dnaKey'],
    'protocolVer': dnaMap['protocolVer'],
    'keyGroupId': 900,
  };

  // Unlock
  final success = await wiseApartment.openLock(auth);
  print(success ? 'Unlocked!' : 'Failed');
}
```

## Error Handling

```dart
import 'package:wise_apartment/wise_apartment.dart';

Future<void> errorHandlingExample() async {
  try {
    final dna = await wiseApartment.addDeviceTyped('AA:BB:CC:DD:EE:FF', 0);
    print('Success: ${dna.mac}');
  } on WiseApartmentException catch (e) {
    // Structured error with code and details
    print('Error ${e.code}: ${e.message}');
    if (e.details != null) {
      print('Details: ${e.details}');
    }
  } on PlatformException catch (e) {
    // Platform-specific errors
    print('Platform error: ${e.message}');
  } catch (e) {
    // Other errors
    print('Unexpected error: $e');
  }
}
```

## Key Points

### ✅ CRITICAL CHANGES (v2.0):
1. **`addDevice()` NOW RETURNS DNA MAP** (not `bool`)
   - Contains all auth credentials needed for operations
   - MUST be saved to database/storage
   - Required for unlock, delete, module info, records, etc.

2. **Android always disconnects BLE** after operations
   - No more connection leaks
   - Proper resource cleanup

3. **iOS never crashes** due to nil args or SDK exceptions
   - All methods have @try/@catch
   - Argument validation before SDK calls

### 📦 Typed API Benefits:
- **Type safety**: No more casting `Map` values
- **Auto-complete**: IDE knows all fields
- **Compile-time errors**: Catch mistakes early
- **Helper methods**: `canPair`, field validators
- **Null safety**: Proper nullable types

### 🔧 Best Practices:

1. **Always save DNA info after addDevice**
2. **Use keyGroupId = 900** for all auth payloads
3. **Handle WiseApartmentException** for structured errors
4. **Check `canPair` before pairing** devices
5. **Store auth payloads securely** (encrypted storage recommended)

### 🚀 Migration from v1.x:

**Old (v1.x):**
```dart
final success = await addDevice(mac, chipType); // Returns bool
if (success) {
  // DNA not available, must call getDna() separately
  final dna = await getDna({'mac': mac, ...});
}
```

**New (v2.x):**
```dart
final dna = await addDeviceTyped(mac, chipType); // Returns DnaInfoModel
// DNA immediately available, no extra call needed
await openLock(dna.toAuthPayload());
```

### 🎯 Production Checklist:

- ✅ Use `addDeviceTyped()` for type-safe DNA
- ✅ Save DNA to encrypted storage
- ✅ Build auth payload with keyGroupId=900
- ✅ Handle errors with try-catch
- ✅ Test on both Android and iOS
- ✅ Request Bluetooth permissions before scanning
- ✅ Check device RSSI > -80 before pairing
- ✅ Disconnect locks properly (handled automatically)
