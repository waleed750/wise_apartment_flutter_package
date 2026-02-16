# WiFi Registration Stream - Implementation Guide

## 📋 Overview

This document describes the **WiFi Registration Stream** feature that enables real-time monitoring of WiFi configuration events from smart lock devices on both Android and iOS platforms.

---

## ✨ Features

- ✅ **Real-time event streaming** - Get instant updates during WiFi configuration
- ✅ **Cross-platform support** - Identical behavior on Android and iOS
- ✅ **Comprehensive status codes** - Support for all WiFi configuration states
- ✅ **Event-driven architecture** - Uses Flutter EventChannel for efficient streaming
- ✅ **Easy integration** - Simple API that follows existing stream patterns

---

## 🎯 Use Case

When registering a smart lock to a WiFi network, the device goes through multiple stages:
1. Starting network binding
2. Connecting to router
3. Connecting to cloud server
4. Success or error states

This stream allows your Flutter app to display real-time progress to users instead of waiting for a final result.

---

## 📊 Status Codes

### Android & iOS Status Codes

| Code | Hex    | Description                              | Type     |
|------|--------|------------------------------------------|----------|
| `2`  | `0x02` | Network distribution binding in progress | Progress |
| `4`  | `0x04` | WiFi module connected to router          | Progress |
| `5`  | `0x05` | WiFi module connected to cloud (SUCCESS) | Success  |
| `6`  | `0x06` | Incorrect password                       | Error    |
| `7`  | `0x07` | WiFi configuration timeout               | Error    |

### iOS Additional Status Codes

| Code | Hex    | Description                      | Type  |
|------|--------|----------------------------------|-------|
| `8`  | `0x08` | Device failed to connect server  | Error |
| `9`  | `0x09` | Device not authorized            | Error |

---

## 🔧 API Usage

### 1. Listen to WiFi Registration Stream

```dart
import 'package:wise_apartment/wise_apartment.dart';

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _plugin = WiseApartment();
  StreamSubscription<Map<String, dynamic>>? _subscription;
  String _currentStatus = 'Not started';

  @override
  void initState() {
    super.initState();
    _setupListener();
  }

  void _setupListener() {
    _subscription = _plugin.wifiRegistrationStream.listen((event) {
      if (event['type'] == 'wifiRegistration') {
        final status = event['status'] as int?;
        final statusMessage = event['statusMessage'] as String?;
        final moduleMac = event['moduleMac'] as String?;
        final lockMac = event['lockMac'] as String?;
        
        setState(() {
          _currentStatus = statusMessage ?? 'Unknown';
        });

        // Handle different status codes
        switch (status) {
          case 0x05:
            print('✅ SUCCESS: Connected to cloud');
            break;
          case 0x06:
            print('❌ ERROR: Incorrect password');
            break;
          case 0x07:
            print('❌ ERROR: Configuration timeout');
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

### 2. Initiate WiFi Registration

```dart
Future<void> registerWifi() async {
  final wifiConfig = WifiConfig(
    ssid: 'MyWiFi',
    password: 'password123',
    serverAddress: 'mqtt.example.com',
    serverPort: '1883',
    configurationType: WifiConfigurationType.wifiAndServer,
    tokenId: 'device-token-here',
    updateToken: '01',
  );

  try {
    // Call registerWifi - events will come through the stream
    final result = await _plugin.registerWifi(
      wifiConfig.toRfCodeString(),
      deviceDnaMap,
    );
    
    print('Registration initiated: $result');
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## 📦 Event Format

Each event from the stream has the following structure:

```dart
{
  "type": "wifiRegistration",           // String - Always "wifiRegistration"
  "status": 5,                          // int - Status code (0x02-0x09)
  "statusMessage": "WiFi module co...", // String - Human-readable message
  "moduleMac": "AA:BB:CC:DD:EE:FF",    // String - RF module MAC address
  "lockMac": "11:22:33:44:55:66"       // String - Lock device MAC address
}
```

### Field Descriptions

- **`type`**: Event type identifier (always `"wifiRegistration"`)
- **`status`**: Integer status code indicating current state
- **`statusMessage`**: Human-readable description of the status
- **`moduleMac`**: MAC address of the WiFi/RF module (may be empty)
- **`lockMac`**: MAC address of the smart lock device

---

## 🏗️ Architecture

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Smart Lock Device                        │
│                    (BLE Connection)                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ├─────────────────┬─────────────────────┐
                     │                 │                     │
              ┌──────▼──────┐   ┌─────▼────────┐   ┌───────▼────────┐
              │   Android   │   │     iOS      │   │   Flutter App  │
              └──────┬──────┘   └──────┬───────┘   └───────▲────────┘
                     │                 │                    │
┌────────────────────▼─────────────────▼────────────────────┴────────┐
│                                                                     │
│  Android Side:                    iOS Side:                        │
│  • KeyEventRegWifi (0x2D)        • KSHNotificationWiFiNetwork...   │
│  • MyBleClient                   • WiseApartmentPlugin             │
│  • WifiRegistrationCallback      • handleWiFiNetworkConfig...      │
│  • EventChannel emission         • WAEventEmitter                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                        ┌──────────▼──────────┐
                        │   Flutter Layer     │
                        │  • EventChannel     │
                        │  • wifiRegistration │
                        │    Stream           │
                        └─────────────────────┘
```

### Platform-Specific Implementation

#### Android

1. **MyBleClient** receives `KeyEventRegWifi` events (event type `0x2D`)
2. **WifiRegistrationCallback** interface extracts:
   - `wifiStatues` → `status`
   - `ModuleMac` → `moduleMac`
   - Lock MAC from event context
3. Events are dispatched to **EventChannel** via main thread handler
4. Flutter receives events through `wifiRegistrationStream`

#### iOS

1. **NSNotificationCenter** receives `KSHNotificationWiFiNetworkConfig` notifications
2. **handleWiFiNetworkConfigNotification** extracts from `SHWiFiNetworkConfigReportParam`:
   - `wifiStatus` → `status`
   - `rfModuleMac` → `moduleMac`
   - `lockMac` → `lockMac`
3. Events are emitted through **WAEventEmitter**
4. Flutter receives events through `wifiRegistrationStream`

---

## 🧪 Testing

### Test Screen Location

A complete test screen is available at:
```
example/lib/screens/wifi_registration_screen.dart
```

### Access Test Screen

1. Run the example app
2. Navigate to any device details screen
3. Tap the **"Test WiFi Registration Stream"** button (blue button with WiFi icon)

### Test Screen Features

- 📝 WiFi configuration form (SSID, password, server, port)
- 📊 Real-time status display with color indicators
- 📜 Status history log with timestamps
- 🎨 Visual icons for different states
- ⏱️ Automatic loading state management

---

## 📝 Example: Complete Implementation

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wise_apartment/wise_apartment.dart';

class WifiSetupScreen extends StatefulWidget {
  final Map<String, dynamic> deviceAuth;
  
  const WifiSetupScreen({Key? key, required this.deviceAuth}) 
      : super(key: key);

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final _plugin = WiseApartment();
  StreamSubscription<Map<String, dynamic>>? _subscription;
  
  bool _isRegistering = false;
  String _statusMessage = 'Ready to configure';
  Color _statusColor = Colors.grey;
  
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listenToWifiEvents();
  }

  void _listenToWifiEvents() {
    _subscription = _plugin.wifiRegistrationStream.listen((event) {
      if (event['type'] != 'wifiRegistration') return;
      
      final status = event['status'] as int?;
      final message = event['statusMessage'] as String? ?? 'Unknown';
      
      setState(() {
        _statusMessage = message;
        _statusColor = _getColorForStatus(status);
        
        // Stop loading on terminal states
        if (status == 0x05 || status == 0x06 || status == 0x07) {
          _isRegistering = false;
        }
      });
    });
  }

  Color _getColorForStatus(int? status) {
    switch (status) {
      case 0x05: return Colors.green;      // Success
      case 0x06:
      case 0x07:
      case 0x08:
      case 0x09: return Colors.red;        // Errors
      default: return Colors.orange;        // Progress
    }
  }

  Future<void> _startRegistration() async {
    setState(() {
      _isRegistering = true;
      _statusMessage = 'Starting registration...';
      _statusColor = Colors.blue;
    });

    final wifiConfig = WifiConfig(
      ssid: _ssidController.text,
      password: _passwordController.text,
      serverAddress: 'mqtt.example.com',
      serverPort: '1883',
      configurationType: WifiConfigurationType.wifiAndServer,
      tokenId: await _getDeviceToken(),
      updateToken: '01',
    );

    try {
      await _plugin.registerWifi(
        wifiConfig.toRfCodeString(),
        widget.deviceAuth,
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _statusColor = Colors.red;
        _isRegistering = false;
      });
    }
  }

  Future<String> _getDeviceToken() async {
    // Implement your token retrieval logic
    return 'your-device-token';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WiFi Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(labelText: 'WiFi SSID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusColor),
              ),
              child: Row(
                children: [
                  if (_isRegistering)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _statusColor == Colors.green
                          ? Icons.check_circle
                          : _statusColor == Colors.red
                              ? Icons.error
                              : Icons.info,
                      color: _statusColor,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isRegistering ? null : _startRegistration,
              child: Text(_isRegistering ? 'Configuring...' : 'Start WiFi Setup'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔍 Troubleshooting

### Issue: No events received

**Solution:**
1. Ensure you're subscribed to the stream **before** calling `registerWifi()`
2. Verify the device is connected via BLE
3. Check platform logs for event emissions:
   - Android: Look for `"Emitting wifiRegistration event"` in Logcat
   - iOS: Look for `"WiFi registration event emitted"` in Console

### Issue: Events received but status always unknown

**Solution:**
1. Verify the event structure matches the documented format
2. Check that `status` field is an integer, not a string
3. Ensure proper type casting in your event handler

### Issue: Stream stops prematurely

**Solution:**
1. Check if you're disposing the subscription too early
2. Verify the device hasn't disconnected
3. Ensure error handling doesn't cancel the subscription

---

## 📚 Additional Resources

### Related Methods

- `registerWifi(String wifiJson, Map<String, dynamic> dna)` - Initiates WiFi configuration
- `connectBle(Map<String, dynamic> auth)` - Connect to device before registration
- `disconnectBle()` - Disconnect after successful registration

### Related Streams

- `syncLockKeyStream` - Stream for syncing lock keys
- `syncLockRecordsStream` - Stream for syncing lock records
- `getSysParamStream` - Stream for system parameters

---

## 📄 License

This implementation is part of the WiseApartment plugin.

---

## 👥 Support

For issues, questions, or contributions:
- Check the example app for complete implementation
- Review platform-specific native code in `android/` and `ios/` directories
- Test using the provided `WifiRegistrationScreen`

---

**Last Updated:** February 16, 2026  
**Version:** 1.0.0  
**Platforms:** Android, iOS
