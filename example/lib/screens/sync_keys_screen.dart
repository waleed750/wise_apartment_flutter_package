import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wise_apartment/wise_apartment.dart';
import 'package:wise_apartment/src/wise_status_store.dart';
import 'package:wise_apartment/src/models/keys/add_lock_key_action_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'add_lock_key_screen.dart';

class SyncKeysScreen extends StatefulWidget {
  final Map<String, dynamic> auth;
  const SyncKeysScreen({Key? key, required this.auth}) : super(key: key);

  @override
  State<SyncKeysScreen> createState() => _SyncKeysScreenState();
}

class _SyncKeysScreenState extends State<SyncKeysScreen> {
  final _plugin = WiseApartment();
  bool _loading = false;
  HxjResponse<LockKeyResult?>? _result;
  // Controllers and storage for Add Key bottom sheet
  final _keyTypeController = TextEditingController();
  final _keyLenController = TextEditingController();
  final _keyController = TextEditingController();
  final _addedKeyGroupIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _keyDataTypeController = TextEditingController();
  final _validModeController = TextEditingController();
  final _addedKeyTypeController = TextEditingController();
  final _addedKeyIDController = TextEditingController();
  final _modifyTimestampController = TextEditingController();
  final _validStartController = TextEditingController();
  final _validEndController = TextEditingController();
  final _vaildNumberController = TextEditingController();
  final _weekController = TextEditingController();
  final _dayStartController = TextEditingController();
  final _dayEndController = TextEditingController();
  // KeyType options (kept as MapEntry<int,String> for code+label). Use index selection in UI.
  final List<MapEntry<int, String>> _keyTypeOptions = [
    MapEntry(1, 'Add fingerprint'),
    MapEntry(4, 'Add card'),
    MapEntry(8, 'Add remote control'),
    MapEntry(2, 'Add password'),
    MapEntry(4, 'Add card number'),
  ];
  int? _selectedKeyOptionIndex;
  final _storage = const FlutterSecureStorage();
  bool _adding = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncKeys();
    });
  }

  @override
  void dispose() {
    _keyTypeController.dispose();
    _keyLenController.dispose();
    _keyController.dispose();
    _addedKeyGroupIdController.dispose();
    _passwordController.dispose();
    // authorMode controller removed; nothing to dispose here
    _keyDataTypeController.dispose();
    _validModeController.dispose();
    _addedKeyTypeController.dispose();
    _addedKeyIDController.dispose();
    _modifyTimestampController.dispose();
    _validStartController.dispose();
    _validEndController.dispose();
    _vaildNumberController.dispose();
    _weekController.dispose();
    _dayStartController.dispose();
    _dayEndController.dispose();
    super.dispose();
  }

  Future<void> _syncKeys() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final res = await _plugin.syncLockKey(widget.auth);
      if (!mounted) return;
      setState(
        () => _result = HxjResponse.fromMap(
          res,
          bodyParser: (body) {
            return LockKeyResult.fromMap(
              Map<String, dynamic>.from(body as Map<dynamic, dynamic>),
            );
          },
        ),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sync keys completed')));
    } catch (e) {
      WiseStatusHandler? status;
      String? codeStr;
      String? msg;
      if (e is WiseApartmentException) {
        codeStr = e.code;
        msg = e.message;
        try {
          status = WiseStatusStore.setFromWiseException(e);
        } catch (_) {}
      } else if (e is PlatformException) {
        try {
          status = WiseStatusStore.setFromMap(
            e.details as Map<String, dynamic>?,
          );
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sync keys error: ${msg ?? e} (code: ${codeStr ?? status?.code})',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddKeySheet() async {
    // populate defaults similar to AddKeyScreen
    final Map<String, dynamic> defaults = {
      'keyDataType': 1,
      'keyType': 1,
      'keyLen': 6,
      'key': '123456',
    };

    try {
      final mac = widget.auth['mac'] as String? ?? 'unknown_mac';
      final key = 'wise_saved_keys_$mac';
      final raw = await _storage.read(key: key);
      if (raw != null && raw.isNotEmpty) {
        final list = json.decode(raw) as List<dynamic>;
        if (list.isNotEmpty) {
          final last = list.last;
          int? lastGroupId;
          if (last is Map && last.containsKey('addedKeyGroupId')) {
            final v = last['addedKeyGroupId'];
            if (v is int) {
              lastGroupId = v;
            } else if (v is String)
              lastGroupId = int.tryParse(v);
          }
          if (lastGroupId != null) defaults['addedKeyGroupId'] = lastGroupId;
        }
      }
    } catch (_) {}

    final res = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => AddLockKeyScreen(auth: widget.auth, defaults: defaults),
      ),
    );

    if (res != null) {
      await _persistKeyResult(res);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Add key ok')));
      }
    }
  }

  Future<void> _persistKeyResult(Map<String, dynamic> res) async {
    try {
      final mac = widget.auth['mac'] as String? ?? 'unknown_mac';
      final key = 'wise_saved_keys_$mac';
      final raw = await _storage.read(key: key);
      List<dynamic> list = [];
      if (raw != null && raw.isNotEmpty) {
        try {
          list = json.decode(raw) as List<dynamic>;
        } catch (_) {
          list = [];
        }
      }
      list.add(res);
      await _storage.write(key: key, value: json.encode(list));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Lock Keys'),
        actions: [
          InkWell(onTap: _syncKeys, child: Icon(Icons.sync)),
          SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Press Sync to retrieve keys from the lock using the plugin.',
            ),

            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _result == null
                  ? const Center(child: Text('No result yet'))
                  : ListView.separated(
                      itemBuilder: (context, index) {
                        final body = _result?.body;
                        final pretty = body != null
                            ? const JsonEncoder.withIndent(
                                '  ',
                              ).convert(body.toMap())
                            : 'No body';
                        return ListTile(
                          onTap: () async {
                            // show full details dialog with copy action
                            if (!mounted) return;
                            await showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Key Details'),
                                content: SingleChildScrollView(
                                  child: SelectableText(pretty),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await Clipboard.setData(
                                          ClipboardData(text: pretty),
                                        );
                                        if (ctx.mounted) {
                                          Navigator.of(ctx).pop();
                                        }
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Copied'),
                                            ),
                                          );
                                        }
                                      } catch (_) {
                                        if (ctx.mounted) {
                                          Navigator.of(ctx).pop();
                                        }
                                      }
                                    },
                                    child: const Text('Copy'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          title: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Text(body?.keyNum.toString() ?? '?'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.lock, size: 18),
                                              const SizedBox(width: 6),
                                              Text(
                                                body?.keyID.toString() ??
                                                    'unknown',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.person,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                body?.appUserID.toString() ??
                                                    'unknown',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.timer, size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            DateTime.fromMillisecondsSinceEpoch(
                                              body?.modifyTimestamp ?? 0,
                                            ).toIso8601String(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => const Divider(),
                      itemCount: 1,
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddKeySheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}
