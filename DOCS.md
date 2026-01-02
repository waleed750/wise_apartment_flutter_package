# Wise Apartment — Full Documentation

A Flutter plugin for communicating with HXJ Bluetooth smart locks. This document describes setup, usage, and the API surface for the `wise_apartment` package.

---

## Overview

- Package: `wise_apartment`
- Purpose: BLE scanning, lock control (open/close/delete), device info, record sync, and device configuration for HXJ smart locks.

---

## Installation

Add `wise_apartment` to your `pubspec.yaml`:

- Local (during development):

```yaml
dependencies:
  wise_apartment:
    path: ../wise_apartment
```

- From pub (if published):

```yaml
dependencies:
  wise_apartment: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## Platform Setup

### Android

1. Minimum SDK

Ensure `minSdkVersion 21` in `android/app/build.gradle`.

2. Required permissions (add to `android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

3. Add vendor AARs

Copy required vendor AARs into `android/app/libs/` (example names used by vendor):

- `hxjblinklibrary-release.aar`
- any other vendor AARs required by your SDK

And add to `build.gradle`:

```groovy
dependencies {
  implementation fileTree(dir: 'libs', include: ['*.aar', '*.jar'])
}
```

Note: Consumer apps must include vendor AARs; the plugin may compile them as `compileOnly` to avoid producing an invalid AAR.

4. Runtime permissions

Request permissions at runtime using e.g. `permission_handler`:

```dart
final statuses = await [
  Permission.bluetoothScan,
  Permission.bluetoothConnect,
  Permission.location,
].request();
```


### iOS

1. Info.plist entries (`ios/Runner/Info.plist`):

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to communicate with smart locks.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to communicate with smart locks.</string>

<!-- Optional: background BLE -->
<key>UIBackgroundModes</key>
<array>
  <string>bluetooth-central</string>
</array>
```

2. Minimum iOS platform

Set in `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

Note: iOS implementation may be incomplete; some methods may return `UNAVAILABLE`.

---

## Quick Start

Import and create an instance:

```dart
import 'package:wise_apartment/wise_apartment.dart';

final wiseApartment = WiseApartment();
```

Initialize BLE client:

```dart
final ok = await wiseApartment.initBleClient();
```

Scan for devices:

```dart
final devices = await wiseApartment.startScan(timeoutMs: 5000);
await wiseApartment.stopScan();
```

Open a lock (example `auth` map):

```dart
final auth = {
  'mac': 'AA:BB:CC:DD:EE:FF',
  'authCode': 'your_auth_code',
  'dnaKey': 'your_dna_key',
  'keyGroupId': 1,
  'bleProtocolVer': 12,
};

final success = await wiseApartment.openLock(auth);
```

Close lock / Delete / Sync follow similar patterns (pass `auth` map where required).

---

## Authentication Object

All lock operations that require server auth expect an `auth` map containing:

```dart
final auth = {
  'mac': String,
  'authCode': String,
  'dnaKey': String,
  'keyGroupId': int,
  'bleProtocolVer': int,
};
```

`mac` must match the discovered device's MAC address.

---

## API Reference (public)

Primary class: `WiseApartment` ([lib/wise_apartment.dart]).

Core / Platform:

- `Future<String?> getPlatformVersion()` — platform version string.
- `Future<Map<String, dynamic>> getDeviceInfo()` — device info (model/manufacturer).
- `Future<Map<String, dynamic>?> getAndroidBuildConfig()` — Android-only build config.

BLE lifecycle:

- `Future<bool> initBleClient()` — initialize BLE client (call before scanning/connecting).
- `Future<List<Map<String, dynamic>>> startScan({int timeoutMs = 10000})` — start BLE scan.
- `Future<bool> stopScan()` — stop scan.
- `Future<bool> disconnect({required String mac})` — disconnect from device.
- `Future<bool> clearSdkState()` — clear SDK state and cached auth.

Lock operations:

- `Future<bool> openLock(Map<String, dynamic> auth)` — open/unlock device.
- `Future<bool> closeLock(Map<String, dynamic> auth)` — close/lock device.
- `Future<bool> deleteLock(Map<String, dynamic> auth)` — delete/reset lock.
- `Future<Map<String, dynamic>> getDna(Map<String, dynamic> auth)` — get device DNA.

Network/module info:

- `Future<Map<String, dynamic>> getNBIoTInfo(Map<String, dynamic> auth)` — NB-IoT module info.
- `Future<Map<String, dynamic>> getCat1Info(Map<String, dynamic> auth)` — Cat1 module info.

Configuration & sync:

- `Future<bool> setKeyExpirationAlarmTime(Map<String, dynamic> auth, int time)` — set key expiration alarm.
- `Future<List<Map<String, dynamic>>> syncLockRecords(Map<String, dynamic> auth, int logVersion)` — retrieve access logs.
- `Future<Map<String, dynamic>> addDevice(String mac, int chipType)` — add/register device.

Internal helpers:

- `WiseApartmentApi.saveAuth(Map<String,dynamic>)` — persist auth to secure storage.
- `WiseApartmentApi.clearAuth()` — clear stored auth and plugin state.

Implementation details:

- Platform interface: `WiseApartmentPlatform` ([lib/wise_apartment_platform_interface.dart]).
- Method channel implementation: `MethodChannelWiseApartment` ([lib/wise_apartment_method_channel.dart]) — uses channel `wise_apartment/methods`.

---

## Error Handling

The plugin throws `WiseApartmentException(code, message)` for errors.

Common codes:

- `PERMISSION_DENIED` — missing runtime permissions.
- `FAILED` — operation executed but returned failure.
- `ERROR` — unexpected error.
- `UNAVAILABLE` — feature not implemented on platform.
- `TIMEOUT` — timed out.

Example:

```dart
try {
  await wiseApartment.openLock(auth);
} on WiseApartmentException catch (e) {
  print('Error ${e.code}: ${e.message}');
}
```

---

## Example Workflows

- Scan → choose device → call `openLock(auth)` where `auth['mac']` matches discovered `mac`.
- Save server-provided auth using `WiseApartmentApi.saveAuth(auth)` to avoid re-supplying values in every call.
- Periodically sync access logs using `syncLockRecords(auth, logVersion)`.

---

## Files of interest

- `lib/wise_apartment.dart` — public API entrypoint.
- `lib/wise_apartment_platform_interface.dart` — platform interface.
- `lib/wise_apartment_method_channel.dart` — method channel implementation.
- `lib/src/wise_apartment_api.dart` — internal helpers and secure storage usage.
- `example/` — example application demonstrating usage.

---

## Running the example

```bash
cd example
flutter run
```

---

## Troubleshooting

- Empty scan: ensure Bluetooth and Location enabled, proper permissions granted, and device is powered and in range.
- `PERMISSION_DENIED`: verify `AndroidManifest.xml` and request runtime permissions (Android 12+ requires `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT`).
- Connection issues: ensure the lock is not connected to another device and is within range.
- iOS `UNAVAILABLE`: iOS implementation may be incomplete — use Android for testing.

---

## License & Support

This project is proprietary. For issues and feature requests, contact the development team.
