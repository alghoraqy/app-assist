import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:quick_settings/quick_settings.dart';
import 'package:test_connection/home_screen.dart';
import 'package:test_connection/quick_access.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "App Assist",
    notificationText:
        "Background notification for keeping app assist running in the background",
    notificationImportance: AndroidNotificationImportance.high,
  );
  await FlutterBackground.initialize(androidConfig: androidConfig);

  //////
  QuickSettings.setup(
    onTileClicked: onTileClicked,
    onTileAdded: onTileAdded,
    onTileRemoved: onTileRemoved,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
