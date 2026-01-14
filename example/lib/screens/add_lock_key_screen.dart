// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wise_apartment/wise_apartment.dart';
import 'package:wise_apartment/src/models/keys/add_lock_key_action_model.dart';

class AddLockKeyScreen extends StatefulWidget {
  final Map<String, dynamic> auth;
  final Map<String, dynamic>? defaults;
  const AddLockKeyScreen({Key? key, required this.auth, this.defaults})
    : super(key: key);

  @override
  State<AddLockKeyScreen> createState() => _AddLockKeyScreenState();
}

class _AddLockKeyScreenState extends State<AddLockKeyScreen> {
  final _plugin = WiseApartment();

  // Controllers for fields that exist on AddLockKeyActionModel
  final _addedKeyGroupIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _keyDataTypeController = TextEditingController();
  final _validModeController = TextEditingController();
  final _localRemoteModeController = TextEditingController();
  final _statusController = TextEditingController();
  final _addedKeyIDController = TextEditingController();
  final _modifyTimestampController = TextEditingController();
  final _validStartController = TextEditingController();
  final _validEndController = TextEditingController();
  final _vaildNumberController = TextEditingController();
  final _weekController = TextEditingController();
  final _dayStartController = TextEditingController();
  final _dayEndController = TextEditingController();

  // UI-specific controllers / state for redesigned layout
  final _userController = TextEditingController();
  final _cellController = TextEditingController();
  bool _appAuth = true;
  bool _allowRemoteUnlock = false;
  bool _allowAddingKeys = false;

  // Validity segmented control: 0=Limit,1=Permanent,2=Cycle,3=Periodic
  int _validitySegment = 2;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _dailyStart;
  TimeOfDay? _dailyEnd;
  final Set<int> _selectedWeekDays = {}; // 1..7 (Mon..Sun)
  // Cycle validNumber choice: 0=disabled, 1=one-time, 255=unlimited, -1 means unset/custom
  int _vaildNumberChoice = -1;

  final List<MapEntry<int, String>> _keyTypeOptions = [
    MapEntry(1, 'Add fingerprint'),
    MapEntry(4, 'Add card'),
    MapEntry(8, 'Add remote control'),
    MapEntry(2, 'Add password'),
  ];
  int? _selectedKeyOptionIndex = 0;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    final d = widget.defaults ?? {};
    _addedKeyGroupIdController.text = d['addedKeyGroupId']?.toString() ?? '';
    _passwordController.text = d['password']?.toString() ?? '';
    _keyDataTypeController.text = d['keyDataType']?.toString() ?? '0';
    _validModeController.text = d['vaildMode']?.toString() ?? '0';
    _localRemoteModeController.text = d['localRemoteMode']?.toString() ?? '1';
    _statusController.text = d['status']?.toString() ?? '0';
    _addedKeyIDController.text = d['addedKeyID']?.toString() ?? '0';
    _modifyTimestampController.text = d['modifyTimestamp']?.toString() ?? '0';
    _validStartController.text = d['validStartTime']?.toString() ?? '0';
    _validEndController.text = d['validEndTime']?.toString() ?? '0';
    _vaildNumberController.text = d['vaildNumber']?.toString() ?? '0';
    _weekController.text = d['week']?.toString() ?? '0';
    _dayStartController.text = d['dayStartTimes']?.toString() ?? '0';
    _dayEndController.text = d['dayEndTimes']?.toString() ?? '0';

    _userController.text = d['user']?.toString() ?? '';
    _cellController.text = d['cell']?.toString() ?? '';

    // initialize vaildNumber choice from controller
    final vnInt = int.tryParse(_vaildNumberController.text) ?? 0;
    if (vnInt == 0)
      _vaildNumberChoice = 0;
    else if (vnInt == 1)
      _vaildNumberChoice = 1;
    else if (vnInt == 0xFF)
      _vaildNumberChoice = 0xFF;
    else
      _vaildNumberChoice = -1;

    if (d.containsKey('addedKeyType')) {
      final at = d['addedKeyType'];
      final atInt = (at is int) ? at : int.tryParse(at?.toString() ?? '');
      if (atInt != null) {
        final idx = _keyTypeOptions.indexWhere((e) => e.key == atInt);
        if (idx != -1) _selectedKeyOptionIndex = idx;
      }
    }
  }

  @override
  void dispose() {
    _addedKeyGroupIdController.dispose();
    _passwordController.dispose();
    _keyDataTypeController.dispose();
    _validModeController.dispose();
    _modifyTimestampController.dispose();
    _validStartController.dispose();
    _validEndController.dispose();
    _vaildNumberController.dispose();
    _weekController.dispose();
    _dayStartController.dispose();
    _dayEndController.dispose();
    _userController.dispose();
    _cellController.dispose();
    _localRemoteModeController.dispose();
    _statusController.dispose();
    _addedKeyIDController.dispose();
    super.dispose();
  }

  int? parseI(String? s) {
    if (s == null) return null;
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add phone authorization',
          style: TextStyle(fontSize: 16),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top switches
              SwitchListTile(
                title: const Text('App Auth', style: TextStyle(fontSize: 14)),
                value: _appAuth,
                onChanged: (v) => setState(() => _appAuth = v),
              ),
              SwitchListTile(
                title: Row(
                  children: [
                    const Text(
                      'Allow remote unlock',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.help_outline, size: 14, color: Colors.grey[600]),
                  ],
                ),
                value: _allowRemoteUnlock,
                onChanged: (v) => setState(() => _allowRemoteUnlock = v),
              ),
              SwitchListTile(
                title: Row(
                  children: [
                    const Text(
                      'Allow adding keys',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.help_outline, size: 14, color: Colors.grey[600]),
                  ],
                ),
                value: _allowAddingKeys,
                onChanged: (v) => setState(() => _allowAddingKeys = v),
              ),

              const SizedBox(height: 8),

              // User and Cell No.
              TextFormField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: 'User *',
                  labelStyle: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cellController,
                decoration: InputDecoration(
                  labelText: 'Cell No. *',
                  labelStyle: const TextStyle(fontSize: 14),
                  prefix: const Text('+1\u00A0'),
                  suffixIcon: Icon(Icons.contact_phone_outlined, size: 18),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 12),

              // Validity segmented control
              Text(
                'Validity period',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoSegmentedControl<int>(
                groupValue: _validitySegment,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Text('Limit', style: TextStyle(fontSize: 13)),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Text('one Time', style: TextStyle(fontSize: 13)),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Text('Permanent', style: TextStyle(fontSize: 13)),
                  ),
                  3: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Text('Cycle', style: TextStyle(fontSize: 13)),
                  ),
                },
                onValueChanged: (v) => setState(() {
                  _validitySegment = v;
                  if (v == 2) {
                    // Permanent: clear dates and set controllers to 0
                    _startDate = null;
                    _endDate = null;
                    _validStartController.text = '0';
                    _validEndController.text = '0';
                  }
                }),
              ),

              const SizedBox(height: 12),

              if (_validitySegment != 2) ...[
                ListTile(
                  title: const Text(
                    'Start Time *',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: Text(
                    _startDate == null
                        ? 'Not set'
                        : _startDate!
                              .toLocal()
                              .toIso8601String()
                              .split('T')
                              .first,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final dt = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? now,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (dt != null) setState(() => _startDate = dt);
                  },
                ),
                ListTile(
                  title: const Text(
                    'End Time *',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: Text(
                    _endDate == null
                        ? 'Not set'
                        : _endDate!
                              .toLocal()
                              .toIso8601String()
                              .split('T')
                              .first,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final dt = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? now,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (dt != null) setState(() => _endDate = dt);
                  },
                ),

                // Cycle-only: allow setting number of authorizations
                if (_validitySegment == 3) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Number of authorizations',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text(
                          'Disable',
                          style: TextStyle(fontSize: 13),
                        ),
                        selected: _vaildNumberChoice == 0,
                        onSelected: (s) {
                          setState(() {
                            _vaildNumberChoice = s ? 0 : -1;
                            _vaildNumberController.text =
                                _vaildNumberChoice == -1
                                ? ''
                                : _vaildNumberChoice.toString();
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text(
                          '1 time',
                          style: TextStyle(fontSize: 13),
                        ),
                        selected: _vaildNumberChoice == 1,
                        onSelected: (s) {
                          setState(() {
                            _vaildNumberChoice = s ? 1 : -1;
                            _vaildNumberController.text =
                                _vaildNumberChoice == -1
                                ? ''
                                : _vaildNumberChoice.toString();
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text(
                          'Unlimited',
                          style: TextStyle(fontSize: 13),
                        ),
                        selected: _vaildNumberChoice == 0xFF,
                        onSelected: (s) {
                          setState(() {
                            _vaildNumberChoice = s ? 0xFF : -1;
                            _vaildNumberController.text =
                                _vaildNumberChoice == -1
                                ? ''
                                : _vaildNumberChoice.toString();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ],

              const SizedBox(height: 8),
              if (_validitySegment == 3) ...[
                ListTile(
                  title: const Text(
                    'Daily start *',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: Text(
                    _dailyStart == null
                        ? 'All day'
                        : _dailyStart!.format(context),
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime:
                          _dailyStart ?? const TimeOfDay(hour: 0, minute: 0),
                    );
                    if (t != null) setState(() => _dailyStart = t);
                  },
                ),
                ListTile(
                  title: const Text(
                    'Daily end *',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: Text(
                    _dailyEnd == null ? 'All day' : _dailyEnd!.format(context),
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime:
                          _dailyEnd ?? const TimeOfDay(hour: 23, minute: 59),
                    );
                    if (t != null) setState(() => _dailyEnd = t);
                  },
                ),

                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Repeat *', style: TextStyle(fontSize: 14)),
                  trailing: Text(
                    _selectedWeekDays.isEmpty
                        ? 'Not set'
                        : '${_selectedWeekDays.length} days',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),

                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (i) {
                    final label = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ][i];
                    final day = i + 1; // 1..7
                    final selected = _selectedWeekDays.contains(day);
                    return ChoiceChip(
                      label: Text(label, style: const TextStyle(fontSize: 13)),
                      selected: selected,
                      onSelected: (s) => setState(() {
                        if (s)
                          _selectedWeekDays.add(day);
                        else
                          _selectedWeekDays.remove(day);
                      }),
                    );
                  }),
                ),
              ],

              const SizedBox(height: 20),

              if (_adding) const Center(child: CircularProgressIndicator()),

              // Add button styled to match image
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: _adding
                      ? null
                      : () async {
                          // Sync UI-specific fields into model-related controllers before submission
                          if (_startDate != null)
                            _validStartController.text =
                                (_startDate!.millisecondsSinceEpoch ~/ 1000)
                                    .toString();
                          if (_endDate != null)
                            _validEndController.text =
                                (_endDate!.millisecondsSinceEpoch ~/ 1000)
                                    .toString();
                          if (_dailyStart != null)
                            _dayStartController.text =
                                (_dailyStart!.hour * 60 + _dailyStart!.minute)
                                    .toString();
                          if (_dailyEnd != null)
                            _dayEndController.text =
                                (_dailyEnd!.hour * 60 + _dailyEnd!.minute)
                                    .toString();
                          if (_selectedWeekDays.isNotEmpty) {
                            int mask = 0;
                            // Map Mon..Sun to bits 0..6
                            for (final d in _selectedWeekDays) {
                              mask |= (1 << (d - 1));
                            }
                            _weekController.text = mask.toString();
                          }

                          // keep the rest of the existing submission/validation logic
                          if (_selectedKeyOptionIndex == null ||
                              _selectedKeyOptionIndex! < 0 ||
                              _selectedKeyOptionIndex! >=
                                  _keyTypeOptions.length) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select a valid key type',
                                  ),
                                ),
                              );
                            return;
                          }

                          final int kt =
                              _keyTypeOptions[_selectedKeyOptionIndex!].key;
                          final String selectedLabel =
                              _keyTypeOptions[_selectedKeyOptionIndex!].value;

                          final password = _passwordController.text.trim();
                          if (password.isNotEmpty &&
                              !RegExp(r'^\d{6,12}\$').hasMatch(password)) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password must be 6-12 digits'),
                                ),
                              );
                            return;
                          }

                          final actionModel = AddLockKeyActionModel(
                            password: password.isNotEmpty ? password : null,
                            authorMode:
                                ((selectedLabel.toLowerCase().contains(
                                      'password',
                                    ) ||
                                    selectedLabel.toLowerCase().contains(
                                      'card number',
                                    )))
                                ? 1
                                : 0,
                            keyDataType:
                                parseI(_keyDataTypeController.text) ?? 0,
                            vaildMode:
                                parseI(_validModeController.text) ??
                                (_validitySegment == 0
                                    ? 0
                                    : (_validitySegment == 2 ? 0 : 1)),
                            addedKeyType: kt,
                            addedKeyID: parseI(_addedKeyIDController.text) ?? 0,
                            addedKeyGroupId:
                                parseI(_addedKeyGroupIdController.text) ?? 0,
                            modifyTimestamp:
                                parseI(_modifyTimestampController.text) ?? 0,
                            validStartTime:
                                parseI(_validStartController.text) ?? 0,
                            validEndTime: parseI(_validEndController.text) ?? 0,
                            week: parseI(_weekController.text) ?? 0,
                            dayStartTimes:
                                parseI(_dayStartController.text) ?? 0,
                            dayEndTimes: parseI(_dayEndController.text) ?? 0,
                            vaildNumber:
                                parseI(_vaildNumberController.text) ?? 0,
                            localRemoteMode:
                                parseI(_localRemoteModeController.text) ?? 1,
                            status: parseI(_statusController.text) ?? 0,
                          );

                          // validate against authMode
                          final amAuth = widget.auth['authMode'];
                          int authModeVal = 0;
                          if (amAuth is int) {
                            authModeVal = amAuth;
                          } else if (amAuth is String) {
                            authModeVal = int.tryParse(amAuth) ?? 0;
                          }
                          final allowedAuth0 = {1, 4, 8};
                          final allowedAuth1 = {2, 4};
                          final int chosenKeyType = kt;
                          if (!(authModeVal == 0
                              ? allowedAuth0.contains(chosenKeyType)
                              : allowedAuth1.contains(chosenKeyType))) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Selected keyType invalid for this authMode',
                                  ),
                                ),
                              );
                            return;
                          }

                          // authorMode->password required
                          final int? authorModeVal = actionModel.authorMode;
                          if (authorModeVal != null && authorModeVal == 1) {
                            final pw = actionModel.password;
                            if (pw == null ||
                                !RegExp(r'^\d{6,12}\$').hasMatch(pw)) {
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password required (6-12 digits)',
                                    ),
                                  ),
                                );
                              return;
                            }
                          }

                          if (actionModel.vaildMode == 1) {
                            final int week = actionModel.week;
                            final int ds = actionModel.dayStartTimes;
                            final int de = actionModel.dayEndTimes;
                            if (week == 0 ||
                                ds < 0 ||
                                ds > 1439 ||
                                de < 0 ||
                                de > 1439 ||
                                de <= ds) {
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid periodic settings'),
                                  ),
                                );
                              return;
                            }
                          }

                          final int vs = actionModel.validStartTime;
                          final int ve = actionModel.validEndTime;
                          if (vs < 0) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('validStartTime must be >= 0'),
                                ),
                              );
                            return;
                          }
                          if (!(ve == 0xFFFFFFFF || ve >= vs)) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'validEndTime must be 0xFFFFFFFF or >= validStartTime',
                                  ),
                                ),
                              );
                            return;
                          }

                          final int vn = actionModel.vaildNumber;
                          if (vn < 0 || vn > 0xFF) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('vaildNumber must be 0..255'),
                                ),
                              );
                            return;
                          }

                          final Map<String, dynamic> params = {
                            'action': actionModel.toMap(),
                          };

                          setState(() => _adding = true);
                          try {
                            final res = await _plugin.addLockKey(
                              widget.auth,
                              params,
                            );
                            if (!mounted) return;
                            Navigator.of(
                              context,
                            ).pop(Map<String, dynamic>.from(res));
                          } catch (e) {
                            String? codeStr;
                            String? msg;
                            if (e is WiseApartmentException) {
                              codeStr = e.code;
                              msg = e.message;
                            }
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Add key error: ${msg ?? e} (code: ${codeStr ?? ''})',
                                  ),
                                ),
                              );
                          } finally {
                            if (mounted) setState(() => _adding = false);
                          }
                        },
                  child: const Text(
                    'Add',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Advanced: show raw model fields for debugging / advanced users (collapsible)
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
