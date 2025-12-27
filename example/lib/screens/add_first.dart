import 'package:flutter/material.dart';

class AddFirstScreen extends StatefulWidget {
  const AddFirstScreen({Key? key}) : super(key: key);

  @override
  State<AddFirstScreen> createState() => _AddFirstScreenState();
}

class _AddFirstScreenState extends State<AddFirstScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('AddFirstScreen: initState');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('AddFirstScreen: dispose');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('AddFirstScreen: lifecycle -> $state');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Device - Step 1')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Press the reset button on the device to enter pairing mode.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              child: const Text('Next'),
              onPressed: () => Navigator.of(context).pushNamed('/add/step2'),
            ),
          ],
        ),
      ),
    );
  }
}
