# Key Type Enable/Disable Feature

## Overview

This feature allows enabling or disabling key types on smart locks using operation mode 02 (by key type). Instead of managing individual keys, you can enable/disable entire categories of keys using a bitmask.

## Supported Platforms

- ✅ **Android**: Fully supported via `EnableLockKeyAction` SDK method
- ⚠️ **iOS**: Not supported - iOS SDK requires individual key IDs, not type bitmasks. The method will return `KEY_TYPE_NOT_SUPPORTED_ON_IOS` error.

## Key Type Bitmask Values

The `keyType` parameter uses a bitmask where each bit represents a different key type:

| Value | Binary | Key Type |
|-------|--------|----------|
| 1 (0x01) | 00000001 | Fingerprint |
| 2 (0x02) | 00000010 | Password |
| 4 (0x04) | 00000100 | Card |
| 8 (0x08) | 00001000 | Remote |
| 64 (0x40) | 01000000 | App temp password |
| 128 (0x80) | 10000000 | App key |
| 255 (0xFF) | 11111111 | All types |

**Combine multiple types by addition:**
- `5` = Fingerprint + Card (1 + 4)
- `10` = Password + Remote (2 + 8)
- `135` = Fingerprint + Password + Remote + App key (1 + 2 + 8 + 128)

## Valid Number Parameter

The `validNumber` parameter controls enable/disable state and usage count:

| Value | Meaning |
|-------|---------|
| 0 | DISABLE the selected key types |
| 1-254 | ENABLE for specific number of uses |
| 255 (0xFF) | ENABLE with unlimited uses |

## Flutter Integration

### 1. Import the Package

Add to your `pubspec.yaml`:

```yaml
dependencies:
  wise_apartment: ^x.x.x  # Use your version
```

Import in your Dart file:

```dart
import 'package:wise_apartment/wise_apartment.dart';
```

### 2. Basic Usage

```dart
final plugin = WiseApartment();

// Prepare auth/DNA map (required fields from your lock setup)
final auth = {
  'mac': 'AA:BB:CC:DD:EE:FF',
  'dnaAes128Key': 'your-aes-key',
  'authorizedRoot': 'your-auth-code',
  'bleProtocolVer': 13,  // Must be >= 0x0d
  'keyGroupId': 900,
};

try {
  // Enable fingerprint and password keys with unlimited uses
  final response = await plugin.setKeyTypeEnabled(
    auth: auth,
    keyTypeBitmask: 3,  // 1 (fingerprint) + 2 (password)
    validNumber: 255,   // unlimited
  );

  if (response['success'] == true || response['isSuccessful'] == true) {
    print('Key types enabled successfully');
  } else {
    print('Failed: ${response['message']}');
  }
} catch (e) {
  print('Error: $e');
}
```

### 3. Disable Key Types

```dart
// Disable card and remote keys
final response = await plugin.setKeyTypeEnabled(
  auth: auth,
  keyTypeBitmask: 12,  // 4 (card) + 8 (remote)
  validNumber: 0,      // 0 = disable
);
```

### 4. Enable with Limited Uses

```dart
// Enable app temp password for 10 uses only
final response = await plugin.setKeyTypeEnabled(
  auth: auth,
  keyTypeBitmask: 64,  // app temp password
  validNumber: 10,     // limit to 10 uses
);
```

### 5. Using the UI Screen

The package includes a ready-to-use screen:

```dart
import 'package:wise_apartment_example/screens/key_type_enable_screen.dart';

// Navigate to the screen
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => KeyTypeEnableScreen(auth: auth),
  ),
);
```

The screen provides:
- TextField for entering key type bitmask (with helper text)
- TextField for entering valid number (0-255)
- Switch that automatically updates valid number (OFF=0, ON=255)
- Apply button that calls the platform method
- Success/error feedback via SnackBar

## Android Native Implementation

### How the Android Handler Works

The Android implementation (`BleLockManager.enableDisableKeyByType`) uses the HXJ BLE SDK's `EnableLockKeyAction`:

```java
EnableLockKeyAction action = new EnableLockKeyAction();
action.setOperationMod(2);        // Mode 02: by key type
action.setKeyTypeOperMode(2);     // Operation mode 2

// Enable/disable logic:
if (validNumber == 0) {
    action.setKeyIdEn(0);          // Disable: all bits off
} else {
    action.setKeyIdEn(keyType);    // Enable: set bitmask
}

bleClient.enableLockKey(action, callback);
```

**Important Android SDK Notes:**
- `operationMod = 02` means "operate by key type" (not individual key ID)
- `keyIdEn` field acts as a bitmask in mode 02
- Bit = 1 means enable that type
- Bit = 0 means disable that type
- The method requires `bleProtocolVer >= 0x0d` (13)

## iOS Limitation

**iOS does not support this feature.** The iOS SDK (`HXModifyKeyTimeParams`) requires individual key IDs and does not accept type bitmasks.

When you call `setKeyTypeEnabled` on iOS, you'll receive:

```dart
{
  "success": false,
  "code": -1,
  "message": "KEY_TYPE_NOT_SUPPORTED_ON_IOS",
  "ackMessage": "iOS SDK does not support enable/disable by key type bitmask. Use individual key ID operations instead.",
  "isSuccessful": false,
  "isError": true
}
```

**Workaround for iOS:** Use individual key management methods like `modifyLockKey` with specific key IDs.

## Error Handling

```dart
try {
  final response = await plugin.setKeyTypeEnabled(
    auth: auth,
    keyTypeBitmask: keyType,
    validNumber: validNum,
  );

  final success = response['success'] == true || 
                  response['isSuccessful'] == true ||
                  response['code'] == 0;

  if (success) {
    // Success
  } else {
    // Failed - check response['message'] or response['ackMessage']
    print('Failed: ${response['message']}');
  }
} on WiseApartmentException catch (e) {
  // Platform exception
  print('Error: ${e.code} - ${e.message}');
} on ArgumentError catch (e) {
  // Validation error (invalid keyTypeBitmask or validNumber)
  print('Validation error: $e');
} catch (e) {
  // Other errors
  print('Unexpected error: $e');
}
```

## Validation Rules

The Dart wrapper performs validation before calling native code:

- `keyTypeBitmask` must be > 0
- `validNumber` must be 0-255

Invalid values will throw `ArgumentError`.

## Platform Method Channel Details

**Method Name:** `enableDisableKeyByType`

**Arguments:**
```dart
{
  'operationMod': 2,
  'keyTypeOperMode': 2,
  'keyType': <keyTypeBitmask>,
  'validNumber': <validNumber>,
  // Plus all auth fields from the auth map:
  'mac': ...,
  'dnaAes128Key': ...,
  'authorizedRoot': ...,
  'bleProtocolVer': ...,
  'keyGroupId': ...,
}
```

**Response:** Map with fields:
- `success` or `isSuccessful`: bool
- `code`: int (status code)
- `message` or `ackMessage`: String (description)
- `body`: optional additional data
- `lockMac`: String

## Testing

### Manual Testing on Android Device

1. Build and run the example app:
   ```bash
   cd example
   flutter run
   ```

2. Navigate to the "Key Type Enable/Disable" screen

3. Enter a key type bitmask (e.g., `3` for fingerprint + password)

4. Set valid number (e.g., `255` for unlimited or `0` to disable)

5. Tap Apply and verify the response

### Testing on iOS Device

The feature will return `KEY_TYPE_NOT_SUPPORTED_ON_IOS` error as expected.

## Common Use Cases

### Example 1: Disable All Fingerprint Access
```dart
await plugin.setKeyTypeEnabled(
  auth: auth,
  keyTypeBitmask: 1,    // Fingerprint only
  validNumber: 0,       // Disable
);
```

### Example 2: Enable Password and Card Access
```dart
await plugin.setKeyTypeEnabled(
  auth: auth,
  keyTypeBitmask: 6,    // 2 (password) + 4 (card)
  validNumber: 255,     // Unlimited
);
```

### Example 3: Temporary Remote Access
```dart
await plugin.setKeyTypeEnabled(
  auth: auth,
  keyTypeBitmask: 8,    // Remote only
  validNumber: 5,       // 5 uses
);
```

### Example 4: Disable All Keys (Emergency Lockdown)
```dart
await plugin.setKeyTypeEnabled(
  auth: auth,
  keyTypeBitmask: 255,  // All types
  validNumber: 0,       // Disable
);
```

## Troubleshooting

### "INIT_ERROR: Lock manager not initialized"
- Ensure you called `initBleClient()` before using this method
- Check that the plugin is properly attached to the Flutter engine

### "Invalid args: keyTypeBitmask must be positive"
- Verify `keyTypeBitmask` is > 0
- Use values from the bitmask table above

### "Invalid args: validNumber must be 0-255"
- Ensure `validNumber` is in range [0, 255]
- Use 0 for disable, 1-254 for limited uses, 255 for unlimited

### Android: "Code: XXX" errors
- Check that `bleProtocolVer >= 0x0d` (13) in your auth map
- Verify BLE connection is established (`connectBle` first if needed)
- Ensure lock supports this protocol version

### iOS: "KEY_TYPE_NOT_SUPPORTED_ON_IOS"
- Expected behavior - iOS SDK doesn't support type bitmask operations
- Use individual key management methods instead

## Summary

✅ **What This Feature Does:**
- Enable/disable multiple key types with one command (Android only)
- Control usage limits per key type
- Simplify key management at the category level

❌ **What This Feature Doesn't Do:**
- Doesn't work on iOS (SDK limitation)
- Doesn't manage individual key IDs (use `modifyLockKey` for that)
- Doesn't work with `bleProtocolVer < 0x0d`

## API Reference

### `WiseApartment.setKeyTypeEnabled`

```dart
Future<Map<String, dynamic>> setKeyTypeEnabled({
  required Map<String, dynamic> auth,
  required int keyTypeBitmask,
  required int validNumber,
})
```

**Parameters:**
- `auth`: DNA/auth map containing lock credentials
- `keyTypeBitmask`: Bitmask of key types to affect (1-255)
- `validNumber`: Enable (1-255) or disable (0)

**Returns:** Map with response fields (success, code, message, etc.)

**Throws:**
- `ArgumentError`: Invalid keyTypeBitmask or validNumber
- `WiseApartmentException`: Platform error

---

For more examples, see the example app in `example/lib/screens/key_type_enable_screen.dart`.

For questions or issues, please file a GitHub issue with details about your platform, SDK version, and error messages.
