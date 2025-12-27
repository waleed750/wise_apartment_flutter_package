import 'package:flutter/material.dart';

class AddSecondScreen extends StatefulWidget {
  const AddSecondScreen({Key? key}) : super(key: key);

  @override
  State<AddSecondScreen> createState() => _AddSecondScreenState();
}

class _AddSecondScreenState extends State<AddSecondScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('AddSecondScreen: initState');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('AddSecondScreen: dispose');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('AddSecondScreen: lifecycle -> $state');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Device - Step 2')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Scanning for device... please wait.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              child: const Text('To Upgrade'),
              onPressed: () => Navigator.of(context).pushNamed('/oad/loading'),
            ),
          ],
        ),
      ),
    );
  }
}
