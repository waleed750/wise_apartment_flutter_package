import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wise_apartment/wise_apartment.dart';

class AddNfcScreen extends StatefulWidget {
  final Map<String, dynamic> auth;
  final int defaultKeyGroupId;

  const AddNfcScreen({
    super.key,
    required this.auth,
    this.defaultKeyGroupId = 901,
  });

  @override
  State<AddNfcScreen> createState() => _AddNfcScreenState();
}

class _AddNfcScreenState extends State<AddNfcScreen> {
  final _plugin = WiseApartment();
  final _keyGroupIdController = TextEditingController();
  StreamSubscription<dynamic>? _streamSubscription;

  // Use AddLockKeyActionModel for validation and parameter management
  late AddLockKeyActionModel _actionModel;

  // Validity type: 0=Permanent, 1=Timed (custom period), 2=Cycled (recurring)
  int _validityType = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _dailyStart;
  TimeOfDay? _dailyEnd;
  final Set<int> _selectedWeekDays = {1, 2, 3, 4, 5, 6, 7}; // Mon-Sun

  bool _isAdding = false;
  String _statusMessage = '';
  double _progress = 0.0;
  int _authTotal = 0;
  int _authCount = 0;

  @override
  void initState() {
    super.initState();
    _keyGroupIdController.text = widget.defaultKeyGroupId.toString();

    // Initialize action model for NFC card (authorMode=0, addedKeyType=card)
    _actionModel = AddLockKeyActionModel(
      authorMode: 0,
      addedKeyType: AddLockKeyActionModel.addedCard,
      addedKeyGroupId: widget.defaultKeyGroupId,
      localRemoteMode: 1,
      status: 0,
    );

    // Apply permanent validity by default
    _actionModel.applyPermanent(groupId: widget.defaultKeyGroupId);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    if (_isAdding) {
      _plugin.exitCmd(widget.auth).catchError((e) {
        log('[AddNfcScreen] exitCmd error in dispose: $e');
      });
    }
    _keyGroupIdController.dispose();
    super.dispose();
  }

  int _parseGroupId() {
    final val =
        int.tryParse(_keyGroupIdController.text) ?? widget.defaultKeyGroupId;
    if (val < 900 || val > 4095) return widget.defaultKeyGroupId;
    return val;
  }

  Future<void> _startAddNfc() async {
    if (_isAdding) return;

    setState(() {
      _isAdding = true;
      _statusMessage = 'Initializing card enrollment...';
      _progress = 0.0;
      _authTotal = 0;
      _authCount = 0;
    });

    try {
      final keyGroupId = _parseGroupId();
      _actionModel.addedKeyGroupId = keyGroupId;

      if (_validityType == 0) {
        _actionModel.applyPermanent(groupId: keyGroupId);
      } else if (_validityType == 1) {
        final start = _startDate ?? DateTime.now();
        final end = _endDate ?? DateTime.now().add(const Duration(days: 30));
        _actionModel.validStartTime = (start.millisecondsSinceEpoch ~/ 1000);
        _actionModel.validEndTime = (end.millisecondsSinceEpoch ~/ 1000);
        _actionModel.vaildNumber = 0xFF;
        _actionModel.vaildMode = 0;
        _actionModel.week = 0;
        _actionModel.dayStartTimes = 0;
        _actionModel.dayEndTimes = 0;
      } else {
        final dailyStartMinutes =
            (_dailyStart?.hour ?? 9) * 60 + (_dailyStart?.minute ?? 0);
        final dailyEndMinutes =
            (_dailyEnd?.hour ?? 21) * 60 + (_dailyEnd?.minute ?? 0);

        _actionModel.applyCycle(
          days: _selectedWeekDays,
          dailyStartMinutes: dailyStartMinutes,
          dailyEndMinutes: dailyEndMinutes,
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(days: 365)),
        );
      }

      try {
        _actionModel.validateOrThrow(authMode: _actionModel.authorMode);
      } catch (e) {
        setState(() {
          _isAdding = false;
          _statusMessage = 'Validation error: $e';
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Validation failed: $e')));
        }
        return;
      }

      final stream = _plugin.addLockKeyStream;
      _streamSubscription = stream.listen(
        (event) {
          if (!mounted) return;
          log('[AddNfcScreen] Stream event: $event');

          final type = event['type'] as String?;
          final message = event['message'] as String? ?? '';
          final bodyRaw = event['body'];
          final body = bodyRaw != null && bodyRaw is Map
              ? Map<String, dynamic>.from(bodyRaw)
              : null;

          if (body != null) {
            _authTotal = (body['authTotal'] as num?)?.toInt() ?? _authTotal;
            _authCount = (body['authCount'] as num?)?.toInt() ?? _authCount;
          }

          double progress = 0.0;
          if (_authTotal > 0) progress = _authCount / _authTotal;

          if (mounted) {
            setState(() {
              _progress = progress;
              if (type == 'addLockKeyChunk' && _authTotal > 0) {
                if (_authTotal == 255) {
                  _statusMessage = 'Please present card ($_authCount)';
                } else {
                  _statusMessage =
                      'Please present card ($_authCount/$_authTotal)';
                }
              } else {
                _statusMessage = message;
              }
            });
          }

          if (type == 'addLockKeyDone') {
            _streamSubscription?.cancel();
            _plugin.exitCmd(widget.auth).catchError((e) {
              log('[AddNfcScreen] exitCmd error: $e');
            });
            if (mounted) {
              setState(() {
                _isAdding = false;
                _statusMessage =
                    'Card enrolled successfully! ($_authCount/$_authTotal)';
                _progress = 1.0;
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) Navigator.of(context).pop(true);
              });
            }
          } else if (type == 'addLockKeyError') {
            _streamSubscription?.cancel();
            _plugin.exitCmd(widget.auth).catchError((e) {
              log('[AddNfcScreen] exitCmd error: $e');
            });
            if (mounted) {
              setState(() {
                _isAdding = false;
                _statusMessage = 'Error: $message';
              });
            }
          }
        },
        onError: (error) {
          log('[AddNfcScreen] Stream error: $error');
          _streamSubscription?.cancel();
          _plugin.exitCmd(widget.auth).catchError((e) {
            log('[AddNfcScreen] exitCmd error: $e');
          });
          if (mounted) {
            setState(() {
              _isAdding = false;
              _statusMessage = 'Error: $error';
            });
          }
        },
      );

      await _plugin.startAddLockKeyStream(widget.auth, _actionModel);
    } catch (e) {
      log('[AddNfcScreen] Exception: $e');
      setState(() {
        _isAdding = false;
        _statusMessage = 'Exception: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cupertino segments: keys map to internal validity types (1=Timed,2=Cycled,0=Permanent)
    final segments = <int, Widget>{
      1: const Text('Timed'),
      2: const Text('Cycled'),
      0: const Text('Permanent'),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Add NFC Card'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.credit_card, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bring the NFC card close to the reader when prompted. The operation will stream progress updates.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _keyGroupIdController,
              decoration: const InputDecoration(
                labelText: 'User ID (900-4095)',
                border: OutlineInputBorder(),
                helperText: 'Enter a unique user ID for this card',
              ),
              keyboardType: TextInputType.text,
              onTapOutside: (event) {
                Focus.of(context).unfocus();
              },
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                Focus.of(context).unfocus();
              },
            ),
            const SizedBox(height: 16),

            const Text(
              'Validity Type:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CupertinoSegmentedControl<int>(
              children: segments,
              groupValue: _validityType == 0 ? 0 : (_validityType == 1 ? 1 : 2),
              onValueChanged: (v) {
                // Map v directly to our internal types: 0,1,2
                setState(() {
                  if (v == 0) {
                    _validityType = 0;
                  } else if (v == 1) {
                    _validityType = 1;
                  } else {
                    _validityType = 2;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            if (_validityType == 1) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _startDate != null
                            ? '${_startDate!.year}-${_startDate!.month}-${_startDate!.day}'
                            : 'Start Date',
                      ),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _endDate != null
                            ? '${_endDate!.year}-${_endDate!.month}-${_endDate!.day}'
                            : 'End Date',
                      ),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              _startDate?.add(const Duration(days: 30)) ??
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: _startDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 730),
                          ),
                        );
                        if (date != null) setState(() => _endDate = date);
                      },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isAdding ? null : _startAddNfc,
              child: Text(_isAdding ? 'Enrolling...' : 'Start Add NFC'),
            ),

            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _progress <= 0 ? null : _progress),
              const SizedBox(height: 8),
              Text(_statusMessage),
            ],
          ],
        ),
      ),
    );
  }
}
