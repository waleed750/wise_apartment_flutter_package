# wise_apartment

A Flutter plugin bridging the **HXJ BLE SDK** for Android.

## Setup

1. **Android AARs**:
   - Place the HXJ SDK `.aar` files into your project's `android/app/libs/` folder.
   - Or, if developing the plugin, put them in `wise_apartment/android/libs/` and uncomment the dependency in `build.gradle`.

2. **Permissions (Android)**:
   Add these to your `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.BLUETOOTH"/>
   <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <!-- Android 12+ -->
   <uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
   ```

## Usage

```dart
final plugin = WiseApartment();

// 1. Initialize
await plugin.initBleClient();

// 2. Scan
final devices = await plugin.startScan(timeoutMs: 5000);
print(devices); // [{mac: AA:BB:.., name: Lock_1, ...}]

// 3. Open Lock
await plugin.openLock({
  "mac": "AA:BB:CC:DD:EE:FF",
  "authCode": "123456",
  "dnaKey": "key...",
  "keyGroupId": 1,
  "bleProtocolVer": 2
});
```

## Troubleshooting
- **Permission Denied**: Ensure you request runtime permissions (`permission_handler` package recommended for app side) before calling `startScan`.
- **MethodNotFound**: Ensure you are running on Android. iOS is not supported for BLE features yet.
# wise_apartment_flutter_package
