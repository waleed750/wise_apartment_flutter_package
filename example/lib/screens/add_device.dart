import 'package:flutter/material.dart';
import 'package:wise_apartment/wise_apartment.dart';
import '../src/secure_storage.dart';
import 'device_details.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

// Simple full-screen progress dialog used during add/bind flow
class _AddProgressDialog extends StatelessWidget {
  const _AddProgressDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const SizedBox(
                  width: 160,
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 6),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Binding lock...',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'please put the phone close to the sensor area of the lock',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Icon(Icons.check, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Search for devices'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Bind lock', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      // Show full-screen progress while adding/binding the lock
      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _AddProgressDialog(),
        );
      }
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
        // Dismiss progress dialog first
        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        // Navigate into DeviceDetails so user sees bind progress there
        if (mounted) {
          await Navigator.of(context).push<Map<String, dynamic>>(
            MaterialPageRoute(
              builder: (_) =>
                  DeviceDetailsScreen(device: DnaInfoModel.fromMap(toSave)),
            ),
          );
        }

        // After returning from details, pop AddDeviceScreen with a non-null result
        if (mounted) Navigator.pop(context, {'added': true});
      } else {
        // Dismiss progress dialog then show failure
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      if (mounted) {
        // Ensure progress dialog removed
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Add error: $e')));
      }
    }
  }

  // progress dialog is declared below at file scope

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
