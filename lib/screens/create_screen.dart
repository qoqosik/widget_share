import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseService _firebaseService = FirebaseService();
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

  Future<void> _send(String? partnerId) async {
    if (_isSending) return;

    if (partnerId == null || partnerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connect with your partner before sending a widget.'),
        ),
      );
      return;
    }

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
      await _firebaseService.sendWidget(
        recipientId: partnerId,
        text: textPayload,
        imageBytes: _imageBytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Widget sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildSquareContent() {
    final TextField noteField = TextField(
      controller: _noteController,
      maxLines: null,
      expands: true,
      readOnly: _isSending,
      textAlignVertical: TextAlignVertical.top,
      style: TextStyle(
        color: _imageBytes == null ? null : Colors.white,
        fontWeight: _imageBytes == null ? null : FontWeight.w600,
        shadows: _imageBytes == null
            ? null
            : const [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
      ),
      decoration: InputDecoration(
        hintText: _imageBytes == null ? 'Quick note…' : 'Add a note…',
        hintStyle: TextStyle(
          color: _imageBytes == null ? null : Colors.white70,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
      ),
    );

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
          Container(color: Colors.black.withValues(alpha: 0.12)),
          noteField,
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

    return noteField;
  }

  Widget _buildPairingStatus(
    ThemeData theme, {
    required bool isLoading,
    required bool hasError,
    required bool isPaired,
  }) {
    final ColorScheme colorScheme = theme.colorScheme;

    String message;
    IconData icon;
    Color color;

    if (isLoading) {
      message = 'Checking your partner connection...';
      icon = Icons.sync;
      color = colorScheme.onSurfaceVariant;
    } else if (hasError) {
      message = 'Could not load your partner connection right now.';
      icon = Icons.error_outline;
      color = colorScheme.error;
    } else if (isPaired) {
      message = 'Ready to send to your partner.';
      icon = Icons.favorite_outline;
      color = colorScheme.primary;
    } else {
      message = 'Connect with your partner on Add Widget before sending.';
      icon = Icons.link_off;
      color = colorScheme.onSurfaceVariant;
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateContent(
    ThemeData theme, {
    required bool isProfileLoading,
    required bool hasProfileError,
    required String? partnerId,
  }) {
    final bool isPaired = partnerId != null && partnerId.isNotEmpty;
    final bool canSend = !_isSending && !isProfileLoading && isPaired;

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
            const SizedBox(height: 8),
            _buildPairingStatus(
              theme,
              isLoading: isProfileLoading,
              hasError: hasProfileError,
              isPaired: isPaired,
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
              onPressed: canSend ? () => _send(partnerId) : null,
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? uid = _firebaseService.currentUserId;

    if (uid == null || uid.isEmpty) {
      return _buildCreateContent(
        theme,
        isProfileLoading: false,
        hasProfileError: true,
        partnerId: null,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firebaseService.getUserProfile(uid),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
          ) {
            final Map<String, dynamic>? data = snapshot.data?.data();
            final String? partnerId = data?['partnerId'] as String?;

            return _buildCreateContent(
              theme,
              isProfileLoading:
                  snapshot.connectionState == ConnectionState.waiting,
              hasProfileError: snapshot.hasError || data == null,
              partnerId: partnerId,
            );
          },
    );
  }
}
