import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wise_apartment/wise_apartment.dart';

/// Displays and allows editing of the Bluetooth lock system parameters.
///
/// – Tap the refresh icon (app bar) to re-read current parameters from the lock.
/// – Tap the "Set Parameters" FAB to open a bottom sheet and write new settings.
class SysParamScreen extends StatefulWidget {
  final Map<String, dynamic> auth;
  const SysParamScreen({super.key, required this.auth});

  @override
  State<SysParamScreen> createState() => _SysParamScreenState();
}

class _SysParamScreenState extends State<SysParamScreen> {
  final _plugin = WiseApartment();

  // ── Get state ──────────────────────────────────────────────────────────────
  bool _loading = true;
  Map<String, dynamic>? _response;
  Object? _error;

  // ── Set state ──────────────────────────────────────────────────────────────
  bool _setting = false;
  String? _setMessage;
  bool? _setSuccess;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Get ────────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _setMessage = null;
      _setSuccess = null;
    });
    try {
      final res = await _plugin.getSysParam(widget.auth);
      if (!mounted) return;
      setState(() => _response = res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Set ────────────────────────────────────────────────────────────────────

  Future<void> _applyParams(SetSysParamModel model) async {
    setState(() {
      _setting = true;
      _setMessage = null;
      _setSuccess = null;
    });
    try {
      final res = await _plugin.setSysParam(widget.auth, model: model);
    
      final ok = res['isSuccessful'] == true || res['code'] == 0;
      setState(() {
        _setSuccess = ok;
        _setMessage = ok
            ? 'Parameters updated successfully.'
            : 'Set failed: ${res['ackMessage'] ?? res['message'] ?? 'Unknown error'}';
      });
      if (ok) await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _setSuccess = false;
        _setMessage = 'Error: $e';
      });
    } finally {
      if (mounted) setState(() => _setting = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, dynamic> get _body {
    if (_response == null) return {};
    final b = _response!['body'];
    if (b is Map) return Map<String, dynamic>.from(b);
    return {};
  }

  int? _intFromBody(String key) {
    final v = _body[key];
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  void _showSetParamsSheet() {
    final draft = SetSysParamModel(
      lockOpen: _intFromBody('lockOpen'),
      normallyOpen: _intFromBody('normallyOpen'),
      isSound: _intFromBody('isSound'),
      sysVolume: _intFromBody('sysVolume'),
      isTamperWarn: _intFromBody('isTamperWarn'),
      isLockCoreWarn: _intFromBody('isLockCoreWarn'),
      isLock: _intFromBody('isLock'),
      isLockCap: _intFromBody('isLockCap'),
      systemLanguage: _intFromBody('systemLanguage'),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SetParamsSheet(
        initial: draft,
        onApply: (model) {
          Navigator.pop(ctx);
          _applyParams(model);
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final prettyBody = _response == null
        ? 'No data'
        : const JsonEncoder.withIndent(
            '  ',
          ).convert(_body.isEmpty ? _response : _body);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Parameters'),
        actions: [
          if (_setting)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _loading ? null : _load,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_loading || _setting) ? null : _showSetParamsSheet,
        icon: const Icon(Icons.edit),
        label: const Text('Set Parameters'),
      ),
      body: Column(
        children: [
          // ── Feedback banner ─────────────────────────────────────────────
          if (_setMessage != null)
            Container(
              color: _setSuccess == true
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              width: double.infinity,
              child: Row(
                children: [
                  Icon(
                    _setSuccess == true
                        ? Icons.check_circle
                        : Icons.error_outline,
                    color: _setSuccess == true
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _setMessage!,
                      style: TextStyle(
                        color: _setSuccess == true
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _setMessage = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // ── Main content ────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load: $_error',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Scrollbar(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SysParamCard(body: _body),
                          if (_body.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Raw response',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                          ],
                          SelectableText(
                            prettyBody,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Current-value card ────────────────────────────────────────────────────────

class _SysParamCard extends StatelessWidget {
  final Map<String, dynamic> body;
  const _SysParamCard({required this.body});

  @override
  Widget build(BuildContext context) {
    if (body.isEmpty) return const SizedBox.shrink();

    Widget row(String label, dynamic value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '—',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );

    String modeLabel(dynamic raw, Map<int, String> labels) {
      if (raw == null) return '—';
      final n = raw is int ? raw : int.tryParse(raw.toString());
      return n == null ? raw.toString() : '${labels[n] ?? raw}';
    }

    final b = body;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Divider(),
            row('Battery', '${b['electricNum'] ?? '—'}%'),
            row(
              'Unlock mode',
              modeLabel(b['lockOpen'], {1: '1 – Single', 2: '2 – Combination'}),
            ),
            row(
              'Normally open',
              modeLabel(b['normallyOpen'], {
                1: '1 – Enabled',
                2: '2 – Disabled',
              }),
            ),
            row('Voice', modeLabel(b['isSound'], {1: '1 – On', 2: '2 – Off'})),
            row(
              'Tamper alarm',
              modeLabel(b['isTamperWarn'], {
                1: '1 – Enabled',
                2: '2 – Disabled',
              }),
            ),
            row(
              'Lock-core alarm',
              modeLabel(b['isLockCoreWarn'], {
                0: '0 – N/A',
                1: '1 – Enabled',
                2: '2 – Disabled',
              }),
            ),
            row(
              'Anti-lock (deadbolt)',
              modeLabel(b['isLock'], {1: '1 – Enabled', 2: '2 – Disabled'}),
            ),
            row(
              'Lock-cap alarm',
              modeLabel(b['isLockCap'], {1: '1 – Enabled', 2: '2 – Disabled'}),
            ),
            row('System language', b['systemLanguage']),
            row('System time', b['sysTime']),
            row('Timezone offset', b['timezoneOffset'] ?? b['TimezoneOffset']),
          ],
        ),
      ),
    );
  }
}

// ── Set-params bottom sheet ────────────────────────────────────────────────────

class _SetParamsSheet extends StatefulWidget {
  final SetSysParamModel initial;
  final void Function(SetSysParamModel) onApply;
  const _SetParamsSheet({required this.initial, required this.onApply});

  @override
  State<_SetParamsSheet> createState() => _SetParamsSheetState();
}

class _SetParamsSheetState extends State<_SetParamsSheet> {
  late int? _lockOpen;
  late int? _normallyOpen;
  late int? _isSound;
  late int? _isTamperWarn;
  late int? _isLockCoreWarn;
  late int? _isLock;
  late int? _isLockCap;
  late int? _systemLanguage;
  late int? _sysVolume;
  late String? _adminPassword;
  late int? _cmdType;
  late int? _setKeyTriggerTime;
  late int? _squareTongueBlockingCurrentLevel;
  late int? _squareTongueExcerciseTime;
  late int? _squareTongueHold;
  late int? _tongueLockTime;
  late int? _tongueUlockTime;
  late int? _unLockDirection;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _lockOpen = m.lockOpen;
    _normallyOpen = m.normallyOpen;
    _isSound = m.isSound;
    _isTamperWarn = m.isTamperWarn;
    _isLockCoreWarn = m.isLockCoreWarn;
    _isLock = m.isLock;
    _isLockCap = m.isLockCap;
    _systemLanguage = m.systemLanguage;
    _sysVolume = m.sysVolume;
    _adminPassword = m.adminPassword;
    _cmdType = m.cmdType;
    _setKeyTriggerTime = m.setKeyTriggerTime;
    _squareTongueBlockingCurrentLevel = m.squareTongueBlockingCurrentLevel;
    _squareTongueExcerciseTime = m.squareTongueExcerciseTime;
    _squareTongueHold = m.squareTongueHold;
    _tongueLockTime = m.tongueLockTime;
    _tongueUlockTime = m.tongueUlockTime;
    _unLockDirection = m.unLockDirection;
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 148,
            child: Text(label, style: const TextStyle(fontSize: 13.5)),
          ),
          Expanded(
            child: DropdownButtonFormField<T>(
              initialValue: value,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(),
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<int>> _itemsFromIntList(List<int> opts, {Map<int, String>? labels}) {
    final List<DropdownMenuItem<int>> items = [
      const DropdownMenuItem<int>(value: null, child: Text('— no change —')),
    ];
    for (final v in opts) {
      final label = labels != null ? (labels[v] ?? v.toString()) : v.toString();
      items.add(DropdownMenuItem<int>(value: v, child: Text(label)));
    }
    return items;
  }

  

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Set System Parameters',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 20),

            // ── Fields ──────────────────────────────────────────────────────
            _dropdown<int>(
              label: 'Unlock mode',
              value: _lockOpen,
              items: _itemsFromIntList(SetSysParamModel.lockOpenOptions, labels: SetSysParamModel.lockOpenLabels),
              onChanged: (v) => setState(() => _lockOpen = v),
            ),
            // Admin password (string)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(width: 148, child: Text('Admin password', style: const TextStyle(fontSize: 13.5))),
                  Expanded(
                    child: TextFormField(
                      initialValue: _adminPassword,
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                      onChanged: (v) => setState(() => _adminPassword = v.isEmpty ? null : v),
                    ),
                  ),
                ],
              ),
            ),
            _dropdown<int>(
              label: 'Command type',
              value: _cmdType,
              items: _itemsFromIntList(SetSysParamModel.cmdTypeOptions, labels: {1: '1 – Normal lock', 2: '2 – Automatic lock'}),
              onChanged: (v) => setState(() => _cmdType = v),
            ),
           
            // Numeric simple inputs
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(width: 148, child: Text('Long-press time', style: const TextStyle(fontSize: 13.5))),
                  Expanded(
                    child: TextFormField(
                      initialValue: _setKeyTriggerTime?.toString(),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => _setKeyTriggerTime = int.tryParse(v)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(width: 148, child: Text('Square tongue current', style: const TextStyle(fontSize: 13.5))),
                  Expanded(
                    child: TextFormField(
                      initialValue: _squareTongueBlockingCurrentLevel?.toString(),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => _squareTongueBlockingCurrentLevel = int.tryParse(v)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(width: 148, child: Text('Square tongue exercise', style: const TextStyle(fontSize: 13.5))),
                  Expanded(
                    child: TextFormField(
                      initialValue: _squareTongueExcerciseTime?.toString(),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => _squareTongueExcerciseTime = int.tryParse(v)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(width: 148, child: Text('Square tongue hold', style: const TextStyle(fontSize: 13.5))),
                  Expanded(
                    child: TextFormField(
                      initialValue: _squareTongueHold?.toString(),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => _squareTongueHold = int.tryParse(v)),
                    ),
                  ),
                ],
              ),
            ),
            _dropdown<int>(
              label: 'Slant tongue level',
              value: _tongueLockTime,
              items: _itemsFromIntList(SetSysParamModel.tongueLockTimeOptions, labels: {for (var i in SetSysParamModel.tongueLockTimeOptions) i: i.toString()}),
              onChanged: (v) => setState(() => _tongueLockTime = v),
            ),
            _dropdown<int>(
              label: 'Tongue retract pause',
              value: _tongueUlockTime,
              items: _itemsFromIntList(SetSysParamModel.tongueUlockTimeOptions, labels: {30: '30 – Slow', 40: '40 – Medium', 50: '50 – Fast'}),
              onChanged: (v) => setState(() => _tongueUlockTime = v),
            ),
            _dropdown<int>(
              label: 'Unlock direction',
              value: _unLockDirection,
              items: _itemsFromIntList(SetSysParamModel.unLockDirectionOptions, labels: {0: '0 – Forward', 1: '1 – Reverse'}),
              onChanged: (v) => setState(() => _unLockDirection = v),
            ),
            Row(
              children: [
                SizedBox(width: 148, child: Text('Sound', style: const TextStyle(fontSize: 13.5))),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable sound'),
                    value: _isSound == 1,
                    onChanged: (v) => setState(() => _isSound = v ? 1 : 2),
                  ),
                ),
              ],
            ),
            _dropdown<int>(
              label: 'System language',
              value: _systemLanguage,
                items: _itemsFromIntList(SetSysParamModel.systemLanguageOptions, labels: SetSysParamModel.systemLanguageLabels),
              onChanged: (v) => setState(() => _systemLanguage = v),
            ),
            Text("System volume (0-5)", style: const TextStyle(fontSize: 13.5)),
            Slider(
              value: _sysVolume?.toDouble() ?? 0,
              min: 0,
              max: SetSysParamModel.sysVolumeOptions.last.toDouble(),
              divisions: SetSysParamModel.sysVolumeOptions.length - 1,
              
              label: _sysVolume?.toString(),
              onChanged: (v) => setState(() => _sysVolume = v.toInt()),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: const Text('Apply Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final model = SetSysParamModel(
      lockOpen: _lockOpen,
      normallyOpen: _normallyOpen,
      isSound: _isSound,
      isTamperWarn: _isTamperWarn,
      isLockCoreWarn: _isLockCoreWarn,
      isLock: _isLock,
      isLockCap: _isLockCap,
      systemLanguage: _systemLanguage,
      sysVolume: _sysVolume,
      adminPassword: _adminPassword,
      cmdType: _cmdType,
      setKeyTriggerTime: _setKeyTriggerTime,
      squareTongueBlockingCurrentLevel: _squareTongueBlockingCurrentLevel,
      squareTongueExcerciseTime: _squareTongueExcerciseTime,
      squareTongueHold: _squareTongueHold,
      tongueLockTime: _tongueLockTime,
      tongueUlockTime: _tongueUlockTime,
      unLockDirection: _unLockDirection,
    );
    if (model.toMap().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one field to change.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.onApply(model);
  }
}
