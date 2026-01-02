# Wise Apartment — API Examples and Expected Returns

This file provides a short example for each public method in `WiseApartment` and the expected return value (example payloads). All methods return a `Future` and may throw `WiseApartmentException` on error.

Usage common snippet:

```dart
import 'package:wise_apartment/wise_apartment.dart';

final wiseApartment = WiseApartment();
```

---

**getPlatformVersion()** :
- Example:
```dart
final version = await wiseApartment.getPlatformVersion();
print(version); // e.g. "Android 12"
```
- Returns: `Future<String?>` — platform string or `null` if unavailable.

---

**getDeviceInfo()** :
- Example:
```dart
final info = await wiseApartment.getDeviceInfo();
print(info['model']);
```
- Returns: `Future<Map<String, dynamic>>` — example:
```json
{
  "model": "Pixel 6",
  "manufacturer": "Google",
  "osVersion": "Android 12"
}
```

---

**getAndroidBuildConfig()** :
- Example:
```dart
final buildConfig = await wiseApartment.getAndroidBuildConfig();
print(buildConfig?['VERSION_NAME']);
```
- Returns: `Future<Map<String, dynamic>?>` — Android build config or `null` on iOS. Example:
```json
{
  "VERSION_NAME": "1.2.3",
  "BUILD_TYPE": "release"
}
```

---

**initBleClient()** :
- Example:
```dart
final ok = await wiseApartment.initBleClient();
if (!ok) throw Exception('BLE init failed');
```
- Returns: `Future<bool>` — `true` if initialization succeeded, `false` otherwise.

---

**startScan({int timeoutMs = 10000})** :
- Example:
```dart
final devices = await wiseApartment.startScan(timeoutMs: 5000);
for (final d in devices) print('${d['name']} ${d['mac']}');
```
- Returns: `Future<List<Map<String, dynamic>>>` — list of discovered devices. Example item:
```json
{
  "name": "HXJ-Lock-001",
  "mac": "AA:BB:CC:11:22:33",
  "rssi": -55,
  "advData": {...}
}
```
- Note: may return `[]` if none found.

---

**stopScan()** :
- Example:
```dart
final stopped = await wiseApartment.stopScan();
```
- Returns: `Future<bool>` — `true` if scan stopped successfully.

---

**openLock(Map<String, dynamic> auth)** :
- Example:
```dart
final auth = {
  'mac': 'AA:BB:CC:11:22:33',
  'authCode': 'AUTH_FROM_SERVER',
  'dnaKey': 'DNA_KEY',
  'keyGroupId': 1,
  'bleProtocolVer': 12,
};
final opened = await wiseApartment.openLock(auth);
print(opened); // true on success
```
- Returns: `Future<bool>` — `true` if lock opened, otherwise `false`. May throw `WiseApartmentException` with codes like `PERMISSION_DENIED`, `FAILED`, `TIMEOUT`.

---

**disconnect({required String mac})** :
- Example:
```dart
final ok = await wiseApartment.disconnect(mac: 'AA:BB:CC:11:22:33');
```
- Returns: `Future<bool>` — `true` if disconnected successfully.

---

**clearSdkState()** :
- Example:
```dart
final ok = await wiseApartment.clearSdkState();
```
- Returns: `Future<bool>` — `true` if SDK state and stored auth were cleared.

---

**closeLock(Map<String, dynamic> auth)** :
- Example:
```dart
final closed = await wiseApartment.closeLock(auth);
```
- Returns: `Future<bool>` — `true` if the device was closed/locked successfully.

---

**getNBIoTInfo(Map<String, dynamic> auth)** :
- Example:
```dart
final nb = await wiseApartment.getNBIoTInfo(auth);
print(nb['imsi']);
```
- Returns: `Future<Map<String, dynamic>>` — example:
```json
{
  "module": "NB-IoT",
  "status": "registered",
  "imsi": "123456789012345",
  "signal": -70
}
```

---

**getCat1Info(Map<String, dynamic> auth)** :
- Example:
```dart
final cat1 = await wiseApartment.getCat1Info(auth);
print(cat1);
```
- Returns: `Future<Map<String, dynamic>>` — example:
```json
{
  "module": "Cat-1",
  "status": "connected",
  "iccid": "898600xxxxxxxxxxxx",
  "signal": -65
}
```

---

**setKeyExpirationAlarmTime(Map<String, dynamic> auth, int time)** :
- Example:
```dart
final ok = await wiseApartment.setKeyExpirationAlarmTime(auth, 3600);
```
- Returns: `Future<bool>` — `true` if alarm time set successfully.
- `time` is seconds (example: `3600` = 1 hour).

---

**syncLockRecords(Map<String, dynamic> auth, int logVersion)** :
- Example:
```dart
final records = await wiseApartment.syncLockRecords(auth, 0);
for (final r in records) print(r);
```
- Returns: `Future<List<Map<String, dynamic>>>` — list of access records. Example item:
```json
{
  "timestamp": 1670000000,
  "type": "open",
  "user": "card_1234",
  "result": "success"
}
```

---

**deleteLock(Map<String, dynamic> auth)** :
- Example:
```dart
final ok = await wiseApartment.deleteLock(auth);
```
- Returns: `Future<bool>` — `true` if lock deleted/reset successfully.

---

**getDna(Map<String, dynamic> auth)** :
- Example:
```dart
final dna = await wiseApartment.getDna(auth);
print(dna['dnaKey']);
```
- Returns: `Future<Map<String, dynamic>>` — example:
```json
{
  "dnaKey": "ABCDEF012345",
  "chipType": 2,
  "firmware": "v1.0.4"
}
```

---

**addDevice(String mac, int chipType)** :
- Example:
```dart
final info = await wiseApartment.addDevice('AA:BB:CC:11:22:33', 2);
print(info['status']);
```
- Returns: `Future<Map<String, dynamic>>` — example:
```json
{
  "status": "added",
  "mac": "AA:BB:CC:11:22:33",
  "chipType": 2
}
```

---

Notes:
- For methods that accept an `auth` map, you can persist server-provided auth using `WiseApartmentApi.saveAuth(auth)` and the plugin will merge stored auth automatically for internal wrappers.
- All methods use the platform method channel and may throw `WiseApartmentException(code, message)`. Handle exceptions with `try`/`catch`.


