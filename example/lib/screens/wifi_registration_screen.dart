import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wise_apartment/wise_apartment.dart';
import 'package:wise_apartment/src/models/wifi_registration_event.dart';

class WifiRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic> auth;
  const WifiRegistrationScreen({Key? key, required this.auth})
      : super(key: key);

  @override
  State<WifiRegistrationScreen> createState() => _WifiRegistrationScreenState();
}

class _WifiRegistrationScreenState extends State<WifiRegistrationScreen> {
  final _plugin = WiseApartment();
  bool _loading = false;
  StreamSubscription<Map<String, dynamic>>? _streamSubscription;
  List<WifiRegistrationEvent> _events = [];
  WifiRegistrationEvent? _latestEvent;

  // WiFi config parameters
  final _ssidController = TextEditingController(text: 'MyWiFiNetwork');
  final _passwordController = TextEditingController(text: 'password123');
  final _hostController = TextEditingController(text: 'mqtt.example.com');
  final _portController = TextEditingController(text: '1883');

  @override
  void initState() {
    super.initState();
    // Listen to WiFi registration events immediately
    _setupWifiRegistrationListener();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _ssidController.dispose();
    _passwordController.dispose();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _setupWifiRegistrationListener() {
    debugPrint('════════════════════════════════════════════════════════════');
    debugPrint('🔌 Setting up WiFi registration listener');
    debugPrint('════════════════════════════════════════════════════════════');

    _streamSubscription = _plugin.wifiRegistrationStream.listen(
      (eventMap) {
        if (!mounted) return;

        final type = eventMap['type'] as String?;
        debugPrint('📩 EVENT RECEIVED: $type');
        debugPrint('   Event data: $eventMap');

        if (type == 'wifiRegistration') {
          // Parse event into typed model
          final event = WifiRegistrationEvent.fromMap(eventMap);
          
          debugPrint('   ${event.statusEmoji} Status: ${event.statusHex} - ${event.statusMessage}');
          debugPrint('   Module MAC: ${event.moduleMac}');
          debugPrint('   Lock MAC: ${event.lockMac}');

          setState(() {
            _latestEvent = event;
            _events.insert(0, event);

            // Auto-stop loading when we reach a terminal state
            if (event.isTerminal) {
              _loading = false;
            }
          });

          if (mounted) {
            final color = _getStatusColor(event);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${event.statusEmoji} ${event.statusMessage}'),
                backgroundColor: color,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      onError: (error) {
        debugPrint('✗ WiFi registration stream error: $error');
        if (mounted) {
          setState(() {
            _latestEvent = null;
            _loading = false;
          });
        }
      },
    );

    debugPrint('✓ WiFi registration listener active');
  }

  Color _getStatusColor(WifiRegistrationEvent? event) {
    if (event == null) return Colors.grey;
    if (event.isSuccess) return Colors.green;
    if (event.isError) return Colors.red;
    if (event.isProgress) return event.status == 0x04 ? Colors.lightBlue : Colors.blue;
    return Colors.orange;
  }

  IconData _getStatusIcon(WifiRegistrationEvent? event) {
    if (event == null) return Icons.help_outline;
    if (event.isSuccess) return Icons.check_circle;
    if (event.isError) return Icons.error;
    if (event.status == 0x04) return Icons.wifi;
    if (event.status == 0x02) return Icons.sync;
    return Icons.info;
  }

  Future<void> _startWifiRegistration() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _latestEvent = null;
      _events.clear();
    });

    try {
      // Build WiFi configuration JSON
      final wifiConfig = {
        'ssid': _ssidController.text,
        'password': _passwordController.text,
        'host': _hostController.text,
        'port': int.tryParse(_portController.text) ?? 1883,
        'autoGetIP': true,
      };

      final wifiJson = jsonEncode(wifiConfig);

      debugPrint(
        '════════════════════════════════════════════════════════════',
      );
      debugPrint('🔌 Starting WiFi registration');
      debugPrint('   Config: $wifiJson');
      debugPrint('   Auth: ${widget.auth}');
      debugPrint(
        '════════════════════════════════════════════════════════════',
      );

      // Call the regWifi method
      final result = await _plugin.registerWifi(wifiJson, widget.auth);

      debugPrint('✓ registerWifi method returned: $result');

      // The actual status updates will come via the stream listener
      // Method call just initiates the process
    } catch (e) {
      debugPrint('✗ WiFi registration failed: $e');

      if (mounted) {
        setState(() {
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WiFi registration error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearHistory() {
    setState(() {
      _events.clear();
      _latestEvent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Registration Test'),
        actions: [
          if (_events.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearHistory,
              tooltip: 'Clear history',
            ),
        ],
      ),
      body: Column(
        children: [
          // Current Status Card
          Card(
            margin: const EdgeInsets.all(16),
            color: _getStatusColor(_latestEvent).withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(_latestEvent),
                        size: 48,
                        color: _getStatusColor(_latestEvent),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Status',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _latestEvent?.statusMessage ?? 'Not started',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(_latestEvent),
                                  ),
                            ),
                            if (_latestEvent != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${_latestEvent!.statusHex} • ${_latestEvent!.statusName}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_loading) const CircularProgressIndicator(),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // WiFi Configuration Form
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WiFi Configuration',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ssidController,
                  decoration: const InputDecoration(
                    labelText: 'WiFi SSID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wifi),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'WiFi Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _hostController,
                  decoration: const InputDecoration(
                    labelText: 'MQTT Host',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cloud),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'MQTT Port',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _startWifiRegistration,
                    icon: Icon(
                      _loading ? Icons.hourglass_empty : Icons.wifi_tethering,
                    ),
                    label: Text(
                      _loading ? 'Registering...' : 'Start WiFi Registration',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Status History
          Expanded(
            child: _events.isEmpty
                ? Center(
                    child: Text(
                      'No status updates yet.\nStart WiFi registration to see updates.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status History (${_events.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton.icon(
                              onPressed: _clearHistory,
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Clear'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(event).withOpacity(0.2),
                                  child: Icon(
                                    _getStatusIcon(event),
                                    color: _getStatusColor(event),
                                    size: 24,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(event.statusEmoji),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(event.statusMessage)),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      '${event.statusHex} • ${event.statusName} • ${event.statusType}',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Time: ${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')}',
                                    ),
                                    if (event.moduleMac.isNotEmpty)
                                      Text('Module: ${event.moduleMac}'),
                                    if (event.lockMac.isNotEmpty)
                                      Text('Lock: ${event.lockMac}'),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
