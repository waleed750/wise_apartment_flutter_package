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
  List<HxjBluetoothDeviceModel> _scanned = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    if (mounted) setState(() => _scanning = true);
    try {
      final results = await _plugin.startScan(timeoutMs: 5000);
      final list = (results)
          .map((e) => HxjBluetoothDeviceModel.fromMap(e))
          .toList();
      if (mounted) setState(() => _scanned = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _addDeviceNative(HxjBluetoothDeviceModel device) async {
    final mac = device.getMac();
    if (mac == null || mac.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid device MAC')));
      }
      return;
    }

    try {
      final cipType = device.chipType ?? 0;
      final res = await _plugin.addDevice(mac, cipType);
      Map<String, dynamic>? toSave;

      // Log for debugging
      debugPrint('addDevice response map: $res');
      final ok = res['ok'] as bool? ?? false;
      final stage = res['stage'];
      final responses = res['responses'];

      if (ok) {
        // prefer dnaInfo if provided
        Object? dna = res['dnaInfo'];
        if (dna == null && responses is Map) {
          final addDev = responses['addDevice'];
          if (addDev is Map) dna = addDev['body'];
        }
        if (dna is Map) {
          toSave = Map<String, dynamic>.from(dna);
        } else {
          toSave = device.toMap();
        }
      } else {
        // show a helpful message with stage and response code/message
        String failedResp = '';
        if (responses is Map) {
          final key = stage is String ? stage : stage?.toString();
          if (key != null && responses.containsKey(key)) {
            final entry = responses[key];
            failedResp = entry?.toString() ?? '';
          } else {
            failedResp = responses.toString();
          }
        } else {
          failedResp = responses?.toString() ?? '';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Add failed at $stage: $failedResp')),
          );
        }
      }

      if (toSave != null) {
        await SecureDeviceStorage.addDevice(toSave);
        if (mounted) Navigator.pop(context, toSave);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Add error: $e')));
      }
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
                    title: Text(d.name ?? 'Unknown'),
                    subtitle: Text(d.getMac() ?? ''),
                    trailing: ElevatedButton(
                      child: const Text('Add'),
                      onPressed: () => _addDeviceNative(d),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
