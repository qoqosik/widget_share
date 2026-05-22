import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/shared_widget_data.dart';
import '../services/firebase_service.dart';

/// Archive: Received / Sent grids backed by Firestore widget history.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              'Notes',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _NotesGrid(
                  stream: _firebaseService.streamReceivedWidgets(),
                  emptyMessage: 'No received notes yet.',
                ),
                _NotesGrid(
                  stream: _firebaseService.streamSentWidgets(),
                  emptyMessage: 'No sent notes yet.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({required this.stream, required this.emptyMessage});

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.hasError) {
              return const _NotesStatusMessage(
                icon: Icons.error_outline,
                message: 'Could not load notes right now.',
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final List<SharedWidgetData> notes = docs
                .map((doc) => SharedWidgetData.fromMap(doc.data()))
                .where((note) => note.hasContent)
                .toList();

            if (notes.isEmpty) {
              return _NotesStatusMessage(
                icon: Icons.note_outlined,
                message: emptyMessage,
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: notes.length,
              itemBuilder: (BuildContext context, int index) {
                return _NoteCard(payload: notes[index]);
              },
            );
          },
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.payload});

  final SharedWidgetData payload;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DecodedWidgetImage imageResult = payload.decodeImage();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _NotePreview(payload: payload, imageResult: imageResult),
          ),
          if (payload.timestamp != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Text(
                _formatTimestamp(payload.timestamp!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');

    return '$month/$day $hour:$minute';
  }
}

class _NotePreview extends StatelessWidget {
  const _NotePreview({required this.payload, required this.imageResult});

  final SharedWidgetData payload;
  final DecodedWidgetImage imageResult;

  @override
  Widget build(BuildContext context) {
    if (payload.hasImage && imageResult.bytes == null) {
      return _ImageErrorPreview(showText: payload.hasText, text: payload.text);
    }

    if (imageResult.bytes != null && payload.hasText) {
      return _MixedPreview(imageBytes: imageResult.bytes!, text: payload.text!);
    }

    if (imageResult.bytes != null) {
      return _ImagePreview(imageBytes: imageResult.bytes!);
    }

    if (payload.hasText) {
      return _TextPreview(text: payload.text!);
    }

    return const _ImageErrorPreview(showText: false);
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return const _ImageErrorPreview(showText: false);
            },
      ),
    );
  }
}

class _MixedPreview extends StatelessWidget {
  const _MixedPreview({required this.imageBytes, required this.text});

  final Uint8List imageBytes;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        _ImagePreview(imageBytes: imageBytes),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.62),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TextPreview extends StatelessWidget {
  const _TextPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.58),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: SingleChildScrollView(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageErrorPreview extends StatelessWidget {
  const _ImageErrorPreview({required this.showText, this.text});

  final bool showText;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.errorContainer),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, color: colorScheme.error),
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showText && text != null && text!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  text!,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotesStatusMessage extends StatelessWidget {
  const _NotesStatusMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
