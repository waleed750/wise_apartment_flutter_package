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
      if (!mounted) return;
      final ok = res['isSuccessful'] == true;
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

  List<DropdownMenuItem<int>> _opts12(String l1, String l2) => [
    const DropdownMenuItem<int>(value: null, child: Text('— no change —')),
    DropdownMenuItem<int>(value: 1, child: Text('1 – $l1')),
    DropdownMenuItem<int>(value: 2, child: Text('2 – $l2')),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 2),
            Text(
              'Only the changed fields will be sent. '
              '"— no change —" leaves the current lock value unchanged.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const Divider(height: 20),

            // ── Fields ──────────────────────────────────────────────────────
            _dropdown<int>(
              label: 'Unlock mode',
              value: _lockOpen,
              items: _opts12('Single', 'Combination'),
              onChanged: (v) => setState(() => _lockOpen = v),
            ),
            _dropdown<int>(
              label: 'Normally open',
              value: _normallyOpen,
              items: _opts12('Enable', 'Disable'),
              onChanged: (v) => setState(() => _normallyOpen = v),
            ),
            _dropdown<int>(
              label: 'Door-open voice',
              value: _isSound,
              items: _opts12('On', 'Off'),
              onChanged: (v) => setState(() => _isSound = v),
            ),
            _dropdown<int>(
              label: 'Tamper alarm',
              value: _isTamperWarn,
              items: _opts12('Enable', 'Disable'),
              onChanged: (v) => setState(() => _isTamperWarn = v),
            ),
            _dropdown<int>(
              label: 'Lock-core alarm',
              value: _isLockCoreWarn,
              items: const [
                DropdownMenuItem<int>(
                  value: null,
                  child: Text('— no change —'),
                ),
                DropdownMenuItem<int>(value: 0, child: Text('0 – No change')),
                DropdownMenuItem<int>(value: 1, child: Text('1 – Enable')),
                DropdownMenuItem<int>(value: 2, child: Text('2 – Disable')),
              ],
              onChanged: (v) => setState(() => _isLockCoreWarn = v),
            ),
            _dropdown<int>(
              label: 'Anti-lock',
              value: _isLock,
              items: _opts12('Enable', 'Disable'),
              onChanged: (v) => setState(() => _isLock = v),
            ),
            _dropdown<int>(
              label: 'Lock-cap alarm',
              value: _isLockCap,
              items: _opts12('Enable', 'Disable'),
              onChanged: (v) => setState(() => _isLockCap = v),
            ),
            _dropdown<int>(
              label: 'System language',
              value: _systemLanguage,
              items: const [
                DropdownMenuItem<int>(
                  value: null,
                  child: Text('— no change —'),
                ),
                DropdownMenuItem<int>(
                  value: 1,
                  child: Text('1 – Simplified Chinese'),
                ),
                DropdownMenuItem<int>(
                  value: 2,
                  child: Text('2 – Traditional Chinese'),
                ),
                DropdownMenuItem<int>(value: 3, child: Text('3 – English')),
                DropdownMenuItem<int>(value: 4, child: Text('4 – Vietnamese')),
                DropdownMenuItem<int>(value: 5, child: Text('5 – Thai')),
              ],
              onChanged: (v) => setState(() => _systemLanguage = v),
            ),
            _dropdown<int>(
              label: 'System volume',
              value: _sysVolume,
              items: const [
                DropdownMenuItem<int>(
                  value: null,
                  child: Text('— no change —'),
                ),
                DropdownMenuItem<int>(
                  value: 0,
                  child: Text('0 – Do not change'),
                ),
                DropdownMenuItem<int>(value: 1, child: Text('1')),
                DropdownMenuItem<int>(value: 2, child: Text('2')),
                DropdownMenuItem<int>(value: 3, child: Text('3')),
                DropdownMenuItem<int>(value: 4, child: Text('4')),
                DropdownMenuItem<int>(value: 5, child: Text('5 – Max')),
              ],
              onChanged: (v) => setState(() => _sysVolume = v),
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
