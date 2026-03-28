import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firebase_service.dart';
import 'drawing_screen.dart';

/// Main hub: 1:1 canvas, draw/photo tools, and send.
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  static const String _senderId = 'user_1';
  static const String _recipientId = 'user_2';

  Uint8List? _imageBytes;

  bool _isSending = false;

  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _openDrawing() async {
    if (_isSending) return;

    final Uint8List? bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        builder: (BuildContext context) => const DrawingScreen(),
      ),
    );
    if (!mounted || bytes == null) return;
    setState(() => _imageBytes = bytes);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_isSending) return;

    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: source);
    if (!mounted || picked == null) return;

    final Uint8List bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

  Future<void> _showPhotoOptions() async {
    if (_isSending) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearImage() {
    setState(() => _imageBytes = null);
  }

  Future<void> _send() async {
    if (_isSending) return;

    final String trimmed = _noteController.text.trim();
    if (trimmed.isEmpty && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a note, drawing, or photo first.')),
      );
      return;
    }

    final String? textPayload = trimmed.isEmpty ? null : trimmed;

    setState(() => _isSending = true);
    try {
      await FirebaseService().sendWidget(
        senderId: _senderId,
        recipientId: _recipientId,
        text: textPayload,
        imageBytes: _imageBytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Widget sent')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildSquareContent() {
    if (_imageBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _imageBytes!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: 'Edit',
                    onPressed: _isSending ? null : _openDrawing,
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    tooltip: 'Delete',
                    onPressed: _isSending ? null : _clearImage,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return TextField(
      controller: _noteController,
      maxLines: null,
      expands: true,
      readOnly: _isSending,
      textAlignVertical: TextAlignVertical.top,
      decoration: const InputDecoration(
        hintText: 'Quick note…',
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add text, draw, or pick a photo for your widget.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: _buildSquareContent(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSending ? null : _openDrawing,
                    icon: const Icon(Icons.brush_outlined),
                    label: const Text('Draw'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSending ? null : _showPhotoOptions,
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Photo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSending ? null : _send,
              child: _isSending
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
