import 'package:flutter/material.dart';

class FirmwareUpgradeScreen extends StatefulWidget {
  const FirmwareUpgradeScreen({Key? key}) : super(key: key);

  @override
  State<FirmwareUpgradeScreen> createState() => _FirmwareUpgradeScreenState();
}

class _FirmwareUpgradeScreenState extends State<FirmwareUpgradeScreen>
    with WidgetsBindingObserver {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('FirmwareUpgradeScreen: initState');
    _simulateProgress();
  }

  void _simulateProgress() async {
    while (_progress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _progress = (_progress + 0.1).clamp(0.0, 1.0));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('FirmwareUpgradeScreen: dispose');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('FirmwareUpgradeScreen: lifecycle -> $state');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firmware Upgrade')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upgrading firmware. Do not disconnect the device.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 12),
            Text('${(_progress * 100).toInt()}%'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _progress >= 1.0
                  ? () => Navigator.of(context).pop()
                  : null,
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
