import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wise_apartment/wise_apartment.dart';

class SysParamScreen extends StatefulWidget {
  final Map<String, dynamic> auth;
  const SysParamScreen({super.key, required this.auth});

  @override
  State<SysParamScreen> createState() => _SysParamScreenState();
}

class _SysParamScreenState extends State<SysParamScreen> {
  final _plugin = WiseApartment();
  bool _loading = true;
  Map<String, dynamic>? _response;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _plugin.getSysParam(widget.auth);
      if (!mounted) return;
      setState(() {
        _response = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _response?['body'] ?? _response;
    final text = body == null
        ? 'No data'
        : const JsonEncoder.withIndent('  ').convert(body);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Parameters'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Failed to load: $_error'),
                    const SizedBox(height: 8),
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
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  text,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
    );
  }
}
