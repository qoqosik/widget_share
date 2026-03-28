import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'widgets/home_shell.dart';

/// Entry point for Widget Share — cross-platform widget sharing between partners.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const WidgetShareApp());
}

/// Root app: theme and [HomeShell] with bottom navigation.
class WidgetShareApp extends StatelessWidget {
  const WidgetShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Widget Share',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const HomeShell(),
    );
  }
}
