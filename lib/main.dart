import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'widgets/home_shell.dart';

/// Entry point for Widget Share — cross-platform widget sharing between partners.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final UserCredential credential = await FirebaseAuth.instance
      .signInAnonymously();
  await _ensureUserDocument(credential.user);
  runApp(const WidgetShareApp());
}

Future<void> _ensureUserDocument(User? user) async {
  final String? uid = user?.uid;
  if (uid == null || uid.isEmpty) return;

  final DocumentReference<Map<String, dynamic>> userRef = FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid);
  final DocumentSnapshot<Map<String, dynamic>> snapshot = await userRef.get();

  if (snapshot.exists) return;

  await userRef.set({
    'uid': uid,
    'pairingCode': _generatePairingCode(),
    'partnerId': null,
  });
}

String _generatePairingCode() {
  const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final Random random = Random.secure();

  return String.fromCharCodes(
    List<int>.generate(
      5,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
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
