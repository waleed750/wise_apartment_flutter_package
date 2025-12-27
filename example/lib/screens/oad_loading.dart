import 'package:flutter/material.dart';

class OadLoadingScreen extends StatefulWidget {
  const OadLoadingScreen({Key? key}) : super(key: key);

  @override
  State<OadLoadingScreen> createState() => _OadLoadingScreenState();
}

class _OadLoadingScreenState extends State<OadLoadingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('OadLoadingScreen: initState');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('OadLoadingScreen: dispose');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('OadLoadingScreen: lifecycle -> $state');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OAD Loading')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Preparing firmware upgrade...'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/firmware'),
              child: const Text('Continue to Firmware Upgrade'),
            ),
          ],
        ),
      ),
    );
  }
}
