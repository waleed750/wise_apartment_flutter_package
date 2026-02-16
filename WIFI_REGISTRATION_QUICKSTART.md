# WiFi Registration Stream - Quick Start Guide

## 🚀 Quick Start (5 Minutes)

### Step 1: Listen to the Stream

```dart
import 'package:wise_apartment/wise_apartment.dart';

final _plugin = WiseApartment();
StreamSubscription? _subscription;

void setupListener() {
  _subscription = _plugin.wifiRegistrationStream.listen((event) {
    if (event['type'] == 'wifiRegistration') {
      final status = event['status'] as int?;
      final message = event['statusMessage'] as String?;
      
      print('Status: $status - $message');
      
      if (status == 0x05) {
        print('✅ SUCCESS: WiFi configured!');
      } else if (status == 0x06 || status == 0x07) {
        print('❌ ERROR: $message');
      }
    }
  });
}
```

### Step 2: Start WiFi Registration

```dart
Future<void> registerWifi() async {
  final config = WifiConfig(
    ssid: 'YourWiFi',
    password: 'YourPassword',
    serverAddress: 'mqtt.server.com',
    serverPort: '1883',
    configurationType: WifiConfigurationType.wifiAndServer,
    tokenId: 'your-token',
    updateToken: '01',
  );

  await _plugin.registerWifi(
    config.toRfCodeString(),
    deviceAuthMap,
  );
}
```

### Step 3: Handle Status Updates

Status codes you'll receive:

| Code | Meaning |
|------|---------|
| `0x02` | Starting... |
| `0x04` | Connected to router |
| `0x05` | ✅ SUCCESS - Connected to cloud |
| `0x06` | ❌ Wrong password |
| `0x07` | ❌ Timeout |

---

## 📱 Complete Example

```dart
class QuickWifiSetup extends StatefulWidget {
  @override
  _QuickWifiSetupState createState() => _QuickWifiSetupState();
}

class _QuickWifiSetupState extends State<QuickWifiSetup> {
  final _plugin = WiseApartment();
  StreamSubscription? _sub;
  String status = 'Ready';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _sub = _plugin.wifiRegistrationStream.listen((event) {
      if (event['type'] == 'wifiRegistration') {
        setState(() {
          status = event['statusMessage'] ?? 'Unknown';
          final code = event['status'] as int?;
          if (code == 0x05 || code == 0x06 || code == 0x07) {
            loading = false;
          }
        });
      }
    });
  }

  Future<void> _register() async {
    setState(() => loading = true);
    try {
      await _plugin.registerWifi(
        WifiConfig(
          ssid: 'MyWiFi',
          password: 'pass123',
          serverAddress: 'server.com',
          serverPort: '1883',
          configurationType: WifiConfigurationType.wifiAndServer,
          tokenId: 'token',
          updateToken: '01',
        ).toRfCodeString(),
        deviceAuth,
      );
    } catch (e) {
      setState(() {
        loading = false;
        status = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WiFi Setup')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(status, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _register,
              child: Text('Start WiFi Setup'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## ⚡ Key Points

1. **Always subscribe BEFORE calling registerWifi()**
2. **Status 0x05 = Success** (connected to cloud)
3. **Status 0x06/0x07 = Error** (password/timeout)
4. **Cancel subscription in dispose()**

---

## 🎯 Status Code Reference

```dart
switch (status) {
  case 0x02: // In progress
    return 'Connecting...';
  case 0x04: // Router connected
    return 'Router OK, connecting to cloud...';
  case 0x05: // SUCCESS
    return '✅ WiFi configured successfully!';
  case 0x06: // ERROR - Password
    return '❌ Incorrect WiFi password';
  case 0x07: // ERROR - Timeout
    return '❌ Configuration timeout';
}
```

---

## 🐛 Common Issues

**Q: No events received?**  
A: Subscribe to stream before calling registerWifi()

**Q: Events stop coming?**  
A: Status 0x05/0x06/0x07 are terminal states (no more events after)

**Q: Wrong password but no error?**  
A: Check event['status'] == 0x06 for password errors

---

## 📖 Full Documentation

See [WIFI_REGISTRATION_STREAM.md](WIFI_REGISTRATION_STREAM.md) for complete details.

---

**Ready to test?** Open the example app and tap "Test WiFi Registration Stream" button!
