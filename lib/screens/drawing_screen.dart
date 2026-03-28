import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

/// Full-screen [Signature] canvas; on save pops PNG bytes as [Uint8List].
class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 4,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draw something first')),
      );
      return;
    }

    final int w = math.max(1024, _controller.defaultWidth ?? 1024);
    final int h = math.max(1024, _controller.defaultHeight ?? 1024);
    final Uint8List? bytes = await _controller.toPngBytes(width: w, height: h);
    if (!mounted || bytes == null) return;

    Navigator.of(context).pop<Uint8List>(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: SizedBox.expand(
          child: Signature(
            controller: _controller,
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
