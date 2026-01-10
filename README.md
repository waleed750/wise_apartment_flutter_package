# Wise Apartment - BLE Smart Lock Flutter Plugin

A Flutter plugin for communicating with HXJ Bluetooth smart locks. This plugin wraps the native **Android_HXJBLESDK** and provides a unified Dart API for both Android and iOS platforms.

[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-blue)](https://flutter.dev)
[![Flutter](https://img.shields.io/badge/flutter-%3E%3D3.3.0-blue)](https://flutter.dev)

---

## Features

- 🔓 **Lock Control** - Open, close, and delete smart locks via BLE
- 📡 **BLE Scanning** - Discover nearby HXJ Bluetooth devices
- 🔐 **Secure Authentication** - Server-based auth with `authCode` and `dnaKey`
- 📋 **Lock Records** - Sync access logs from the device
- ⚙️ **Device Configuration** - Set key expiration alarms, get device DNA
- 📱 **Cross-Platform** - Works on Android and iOS

---

## Table of Contents

- [Installation](#installation)
- [Platform Setup](#platform-setup)
  - [Android Setup](#android-setup)
  - [iOS Setup](#ios-setup)
- [Usage](#usage)
  - [Initialize](#initialize)
  - [Scan for Devices](#scan-for-devices)
  - [Open Lock](#open-lock)
  - [Close Lock](#close-lock)
  - [Delete Lock](#delete-lock)
  - [Sync Lock Records](#sync-lock-records)
- [API Reference](#api-reference)
- [Error Handling](#error-handling)
- [Example App](#example-app)
- [Troubleshooting](#troubleshooting)

---

## Installation

Add `wise_apartment` to your `pubspec.yaml`:

```yaml
dependencies:
  wise_apartment:
    path: ../wise_apartment  # Local path reference
```

Or if published to a repository:

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

### Android Setup

#### 1. Minimum SDK Version

Ensure your `android/app/build.gradle` has:

```groovy
android {
    defaultConfig {
        minSdkVersion 21  // Required for BLE
    }
}
```

#### 2. Add Required Permissions

Add the following to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Bluetooth permissions (Android 11 and below) -->
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    
    <!-- Location permissions (required for BLE scanning) -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Bluetooth permissions (Android 12+) -->
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" 
        android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    
    <!-- BLE feature declaration -->
    <uses-feature 
        android:name="android.hardware.bluetooth_le" 
        android:required="true" />

    <application ...>
        <!-- Your app config -->
    </application>
</manifest>
```

#### 3. Add SDK AAR Files

Copy the following AAR files to `android/app/libs/`:

- `hxjblinklibrary-release.aar`
- `hblelibrary_base_a.aar`
- `hblelibrary_base_b.aar`

Then add to your `android/app/build.gradle`:

```groovy
dependencies {
    implementation fileTree(dir: 'libs', include: ['*.aar', '*.jar'])
}
```

#### Plugin AAR packaging note

> **Important:** When building the plugin as an AAR, the Android Gradle Plugin will fail if the library module declares direct local `.aar` dependencies because the produced AAR would be missing those libraries' classes and resources. To avoid this issue the plugin compiles against vendor AARs using `compileOnly` (see `wise_apartment/android/build.gradle`). Consumer apps must include the vendor AARs (for example by copying them into the app module's `libs/` folder or publishing them to a Maven repository) so the final APK/AAB contains the native SDK.


#### 4. Request Permissions at Runtime

Use a package like [`permission_handler`](https://pub.dev/packages/permission_handler) to request permissions:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestBlePermissions() async {
  if (Platform.isAndroid) {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    
    return statuses.values.every((s) => s.isGranted);
  }
  return true;
}
```

---

### iOS Setup

#### 1. Info.plist Configuration

Add the following to `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- Bluetooth usage descriptions (required) -->
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>This app uses Bluetooth to communicate with smart locks.</string>
    
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>This app uses Bluetooth to communicate with smart locks.</string>
    
    <!-- Optional: Enable background BLE -->
    <key>UIBackgroundModes</key>
    <array>
        <string>bluetooth-central</string>
    </array>
</dict>
```

#### 2. Minimum iOS Version

Ensure your `ios/Podfile` has:

```ruby
platform :ios, '12.0'
```

> ⚠️ **Note:** iOS implementation is currently in progress. BLE methods return `UNAVAILABLE` error until completed.

---

## Usage

### Import the Package

```dart
import 'package:wise_apartment/wise_apartment.dart';
```

### Initialize

Create an instance and initialize the BLE client:

```dart
final wiseApartment = WiseApartment();

Future<void> initializeBle() async {
  try {
    final success = await wiseApartment.initBleClient();
    print('BLE initialized: $success');
  } catch (e) {
    print('Failed to initialize BLE: $e');
  }
}
```

### Scan for Devices

Discover nearby BLE locks:

```dart
Future<void> scanForLocks() async {
  try {
    // Scan for 5 seconds
    final devices = await wiseApartment.startScan(timeoutMs: 5000);
    
    for (final device in devices) {
      print('Found: ${device['name']} - ${device['mac']} (${device['rssi']} dBm)');
    }
  } catch (e) {
    print('Scan failed: $e');
  }
}

// Stop an ongoing scan
await wiseApartment.stopScan();
```

### Open Lock

Unlock a smart lock with authentication:

```dart
Future<void> unlockDoor() async {
  // Authentication data from your server
  final auth = {
    'mac': 'AA:BB:CC:DD:EE:FF',      // Device MAC address
    'authCode': 'your_auth_code',     // From server
    'dnaKey': 'your_dna_key',         // From server
    'keyGroupId': 1,                   // Key group ID
    'bleProtocolVer': 12,              // BLE protocol version
  };

  try {
    final success = await wiseApartment.openLock(auth);
    print('Lock opened: $success');
  } on WiseApartmentException catch (e) {
    print('Failed to open lock: ${e.code} - ${e.message}');
  }
}
```

### Close Lock

Close/lock the device:

```dart
Future<void> lockDoor() async {
  final auth = {
    'mac': 'AA:BB:CC:DD:EE:FF',
    'authCode': 'your_auth_code',
    'dnaKey': 'your_dna_key',
    'keyGroupId': 1,
    'bleProtocolVer': 12,
  };

  try {
    final success = await wiseApartment.closeLock(auth);
    print('Lock closed: $success');
  } catch (e) {
    print('Failed to close lock: $e');
  }
}
```

### Delete Lock

Remove a lock from the device:

```dart
Future<void> removeLock() async {
  final auth = {
    'mac': 'AA:BB:CC:DD:EE:FF',
    'authCode': 'your_auth_code',
    'dnaKey': 'your_dna_key',
    'keyGroupId': 1,
    'bleProtocolVer': 12,
  };

  try {
    final success = await wiseApartment.deleteLock(auth);
    print('Lock deleted: $success');
  } catch (e) {
    print('Failed to delete lock: $e');
  }
}
```

### Sync Lock Records

Retrieve access logs from the lock:

```dart
Future<void> getLockHistory() async {
  final auth = {
    'mac': 'AA:BB:CC:DD:EE:FF',
    'authCode': 'your_auth_code',
    'dnaKey': 'your_dna_key',
    'keyGroupId': 1,
    'bleProtocolVer': 12,
  };

  try {
    final records = await wiseApartment.syncLockRecords(auth, 0);
    
    for (final record in records) {
      // Each record is a flat map coming from the native
      // HXJ SDK. Common fields include:
      //   - recordTime (int, seconds timestamp)
      //   - recordType (int, LogType enum value)
      //   - logVersion (1 = first gen, 2 = second gen)
      //   - modelType (HXRecord* concrete model name)
      //   - eventFlag / power and other model-specific fields.
      print('Record: $record');
    }
  } catch (e) {
    print('Failed to sync records: $e');
  }
}
```

---

## API Reference

### Core Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `initBleClient()` | Initialize the BLE client | `Future<bool>` |
| `startScan({timeoutMs})` | Scan for BLE devices | `Future<List<Map<String, dynamic>>>` |
| `stopScan()` | Stop ongoing scan | `Future<bool>` |
| `disconnect({mac})` | Disconnect from device | `Future<bool>` |
| `clearSdkState()` | Clear cached SDK state | `Future<bool>` |

### Lock Operations

| Method | Description | Returns |
|--------|-------------|---------|
| `openLock(auth)` | Unlock the device | `Future<bool>` |
| `closeLock(auth)` | Lock the device | `Future<bool>` |
| `deleteLock(auth)` | Delete/reset the lock | `Future<bool>` |
| `getDna(auth)` | Get device DNA info | `Future<Map<String, dynamic>>` |

### Device Information

| Method | Description | Returns |
|--------|-------------|---------|
| `getDeviceInfo()` | Get device info (model, OS) | `Future<Map<String, dynamic>>` |
| `getPlatformVersion()` | Get platform version string | `Future<String?>` |
| `getAndroidBuildConfig()` | Android build config (Android only) | `Future<Map<String, dynamic>?>` |
| `getNBIoTInfo(auth)` | Get NB-IoT module info | `Future<Map<String, dynamic>>` |
| `getCat1Info(auth)` | Get Cat1 module info | `Future<Map<String, dynamic>>` |

### Configuration

| Method | Description | Returns |
|--------|-------------|---------|
| `setKeyExpirationAlarmTime(auth, time)` | Set key expiration alarm | `Future<bool>` |
| `syncLockRecords(auth, logVersion)` | Sync access records | `Future<List<Map<String, dynamic>>>` |
| `addDevice(mac, chipType)` | Add new device | `Future<Map<String, dynamic>>` |

### Authentication Object

All lock operations require an `auth` map with these fields:

```dart
final auth = {
  'mac': String,            // Device MAC address (required)
  'authCode': String,       // Authentication code from server (required)
  'dnaKey': String,         // DNA key from server (required)
  'keyGroupId': int,        // Key group identifier (required)
  'bleProtocolVer': int,    // BLE protocol version (required)
};
```

---

## Error Handling

The plugin throws `WiseApartmentException` for errors:

```dart
try {
  await wiseApartment.openLock(auth);
} on WiseApartmentException catch (e) {
  switch (e.code) {
    case 'PERMISSION_DENIED':
      print('Missing Bluetooth permissions');
      break;
    case 'FAILED':
      print('Operation failed: ${e.message}');
      break;
    case 'ERROR':
      print('Error: ${e.message}');
      break;
    case 'UNAVAILABLE':
      print('Feature not available on this platform');
      break;
    default:
      print('Unknown error: ${e.code}');
  }
}
```

### Error Codes

| Code | Description |
|------|-------------|
| `PERMISSION_DENIED` | Missing Bluetooth or Location permissions |
| `FAILED` | Operation completed but was unsuccessful |
| `ERROR` | Exception occurred during operation |
| `UNAVAILABLE` | Feature not implemented on this platform |
| `TIMEOUT` | Operation timed out |

---

## Example App

A fully functional example app is included in the `example/` directory:

```bash
cd example
flutter run
```

The example demonstrates:
- BLE scanning with pull-to-refresh
- Device discovery and selection
- Lock/unlock operations
- Error handling

---

## Troubleshooting

### "PERMISSION_DENIED" on Android

1. Ensure all permissions are declared in `AndroidManifest.xml`
2. Request permissions at runtime before scanning
3. On Android 12+, both `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` are required

### Scan returns empty list

1. Ensure Bluetooth is enabled on the device
2. Ensure Location services are enabled (required for BLE scanning on Android)
3. Ensure you have granted location permission
4. Make sure the lock is powered on and in range

### Connection timeout

1. Ensure the lock is not connected to another device
2. Move closer to the lock (within 2-5 meters)
3. Check that authentication credentials are correct

### iOS: "UNAVAILABLE" error

iOS implementation is currently in progress. Use Android for testing until iOS support is complete.

---

## Requirements

| Platform | Minimum Version |
|----------|-----------------|
| Android | API 21 (Lollipop) |
| iOS | 12.0 |
| Flutter | 3.3.0 |
| Dart | 3.0.0 |

---

## License

This project is proprietary software. All rights reserved.

---

## Support

For issues and feature requests, please contact the development team.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
