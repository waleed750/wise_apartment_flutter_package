import 'package:flutter/material.dart';
import 'package:wise_apartment/wise_apartment.dart';
import '../src/secure_storage.dart';
import '../src/wifi_config.dart';
// wifi info removed; default SSID/password used instead

class DeviceDetailsScreen extends StatefulWidget {
  final DnaInfoModel device;
  const DeviceDetailsScreen({super.key, required this.device});

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  final _plugin = WiseApartment();
  bool _busy = false;
  // WiFi form controllers
  final TextEditingController _ssidController = TextEditingController(
    text: 'Home',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '123456789@Home',
  );
  bool _showPassword = false;

  Future<void> _openLock() async {
    setState(() => _busy = true);
    final auth = {
      'mac': widget.device.mac,
      'authCode': widget.device.authorizedRoot ?? '',
      'dnaKey': widget.device.dnaAes128Key ?? '',
      'keyGroupId': 1,
      'bleProtocolVer': 2,
    };
    try {
      final ok = await _plugin.openLock(auth);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Open: $ok')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Open error: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _closeLock() async {
    setState(() => _busy = true);
    final auth = {
      'mac': widget.device.mac,
      'authCode': widget.device.authorizedRoot ?? '',
      'dnaKey': widget.device.dnaAes128Key ?? '',
      'keyGroupId': 1,
      'bleProtocolVer': 2,
    };
    try {
      final ok = await _plugin.closeLock(auth);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Close: $ok')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Close error: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _deleteLock() async {
    setState(() => _busy = true);
    final auth = {
      'mac': widget.device.mac,
      'authCode': widget.device.authorizedRoot ?? '',
      'dnaKey': widget.device.dnaAes128Key ?? '',
      'keyGroupId': 1,
      'bleProtocolVer': 2,
    };
    try {
      final ok = await _plugin.deleteLock(auth);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete: $ok')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete error: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _registerWifi() async {
    setState(() => _busy = true);

    // Default host:port when not provided
    const defaultHost = '34.166.141.220';
    const defaultPort = '8090';

    final wifiModel = WifiConfig(
      ssid: _ssidController.text.trim(),
      password: _passwordController.text,
      serverAddress: defaultHost,
      serverPort: defaultPort,
    );

    // Pass the full DnaInfoModel map to native side to avoid losing fields.
    final dna = widget.device.toMap();

    try {
      final res = await _plugin.registerWifi(wifiModel.toRfCodeString(), dna);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('regWifi: ${res.toString()}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('regWifi error: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _removeFromStorage() async {
    await SecureDeviceStorage.removeDevice(widget.device.mac ?? '');
    Navigator.pop(context, {'removed': true, 'mac': widget.device.mac});
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.device.mac ?? 'Device';
    final mac = widget.device.mac ?? '';
    return Scaffold(
      appBar: AppBar(title: Text("Device Details")),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(child: Icon(Icons.lock, size: 120, color: Colors.green)),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(mac, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (_busy) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _openLock, child: const Text('Open')),
                ElevatedButton(
                  onPressed: _closeLock,
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: _deleteLock,
                  child: const Text('Delete'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              children: [
                ElevatedButton(
                  onPressed: _removeFromStorage,
                  child: const Text('Remove from app'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                children: [
                  TextField(
                    controller: _ssidController,
                    decoration: const InputDecoration(labelText: 'WiFi SSID'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'WiFi Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    obscureText: !_showPassword,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Server and port default to http://34.166.141.220:8090',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _registerWifi,
                    child: const Text('Register WiFi'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
