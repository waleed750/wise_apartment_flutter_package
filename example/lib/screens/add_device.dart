import 'package:flutter/material.dart';
import 'package:wise_apartment/wise_apartment.dart';
import '../src/secure_storage.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _plugin = WiseApartment();
  List<Map<String, dynamic>> _scanned = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _scanning = true);
    try {
      final results = await _plugin.startScan(timeoutMs: 5000);
      setState(() => _scanned = results);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
    } finally {
      setState(() => _scanning = false);
    }
  }

  Future<void> _pairAndSave(Map<String, dynamic> device) async {
    final mac = device['mac'] ?? '';
    final authCodeController = TextEditingController();
    final dnaKeyController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pair device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('MAC: $mac'),
            TextField(
              controller: authCodeController,
              decoration: const InputDecoration(labelText: 'Auth Code'),
            ),
            TextField(
              controller: dnaKeyController,
              decoration: const InputDecoration(labelText: 'DNA Key'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pair'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final auth = {
      'mac': mac,
      'authCode': authCodeController.text,
      'dnaKey': dnaKeyController.text,
      'keyGroupId': 1,
      'bleProtocolVer': 2,
    };

    try {
      final success = await _plugin.openLock(auth);
      if (success == true) {
        final toSave = {
          'mac': mac,
          'name': device['name'] ?? '',
          'rssi': device['rssi'] ?? 0,
          'authCode': auth['authCode'],
          'dnaKey': auth['dnaKey'],
        };
        await SecureDeviceStorage.addDevice(toSave);
        Navigator.pop(context, toSave);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pair failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pair error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Device')),
      body: RefreshIndicator(
        onRefresh: _startScan,
        child: _scanning && _scanned.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView.builder(
                itemCount: _scanned.length,
                itemBuilder: (ctx, i) {
                  final d = _scanned[i];
                  return ListTile(
                    leading: const Icon(Icons.devices),
                    title: Text(d['name'] ?? 'Unknown'),
                    subtitle: Text(d['mac'] ?? ''),
                    trailing: ElevatedButton(
                      child: const Text('Add'),
                      onPressed: () => _pairAndSave(d),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
