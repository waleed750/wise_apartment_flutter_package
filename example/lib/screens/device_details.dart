import 'package:flutter/material.dart';
import 'package:wise_apartment/wise_apartment.dart';
import '../src/secure_storage.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> device;
  const DeviceDetailsScreen({super.key, required this.device});

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  final _plugin = WiseApartment();
  bool _busy = false;

  Future<void> _openLock() async {
    setState(() => _busy = true);
    final auth = {
      'mac': widget.device['mac'],
      'authCode': widget.device['authCode'] ?? '',
      'dnaKey': widget.device['dnaKey'] ?? '',
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
      'mac': widget.device['mac'],
      'authCode': widget.device['authCode'] ?? '',
      'dnaKey': widget.device['dnaKey'] ?? '',
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
      'mac': widget.device['mac'],
      'authCode': widget.device['authCode'] ?? '',
      'dnaKey': widget.device['dnaKey'] ?? '',
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

  Future<void> _removeFromStorage() async {
    await SecureDeviceStorage.removeDevice(widget.device['mac']);
    Navigator.pop(context, {'removed': true, 'mac': widget.device['mac']});
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.device['name'] ?? 'Device';
    final mac = widget.device['mac'] ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Center(child: Icon(Icons.lock, size: 120, color: Colors.green)),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(mac),
          const SizedBox(height: 24),
          if (_busy) const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: _openLock, child: const Text('Open')),
              ElevatedButton(onPressed: _closeLock, child: const Text('Close')),
              ElevatedButton(
                onPressed: _deleteLock,
                child: const Text('Delete'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _removeFromStorage,
            child: const Text('Remove from app'),
          ),
        ],
      ),
    );
  }
}
