import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DnaInfoScreen extends StatelessWidget {
  final Map<String, dynamic> dna;
  const DnaInfoScreen({Key? key, required this.dna}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pretty = const JsonEncoder.withIndent('  ').convert(dna);
    return Scaffold(
      appBar: AppBar(
        title: const Text('DNA Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              try {
                await Clipboard.setData(ClipboardData(text: pretty));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('DNA copied to clipboard')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copy failed')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: SelectableText(pretty),
        ),
      ),
    );
  }
}
