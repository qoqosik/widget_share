import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/shared_widget_data.dart';
import '../services/firebase_service.dart';
import '../services/home_widget_service.dart';

/// Instructions, partner connection, and live widget preview.
class AddWidgetScreen extends StatefulWidget {
  const AddWidgetScreen({super.key});

  @override
  State<AddWidgetScreen> createState() => _AddWidgetScreenState();
}

class _AddWidgetScreenState extends State<AddWidgetScreen> {
  final TextEditingController _partnerCodeController = TextEditingController();
  final HomeWidgetService _homeWidgetService = HomeWidgetService();

  bool _isConnecting = false;
  String? _lastHomeWidgetPayload;

  String? get _currentUserId {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _partnerCodeController.dispose();
    super.dispose();
  }

  Future<void> _connectPartner() async {
    if (_isConnecting) return;

    final String code = _partnerCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a partner code.')));
      return;
    }

    setState(() => _isConnecting = true);
    try {
      await FirebaseService().pairWithCode(code);
      if (!mounted) return;
      _partnerCodeController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Partner connected.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Widget _buildLatestWidgetCard(ThemeData theme) {
    final String? uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      _queueHomeWidgetUpdate(HomeWidgetService.fallbackNoNote, type: 'empty');
      return const _WaitingForWidgetCard();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService().getLatestWidget(uid),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.hasError) {
              return _StatusCard(
                title: 'Latest widget',
                child: Text(
                  'Could not load your widget right now.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _StatusCard(
                title: 'Latest widget',
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snapshot.data?.docs;
            if (docs == null || docs.isEmpty) {
              _queueHomeWidgetUpdate(
                HomeWidgetService.fallbackNoNote,
                type: 'empty',
              );
              return const _WaitingForWidgetCard();
            }

            final SharedWidgetData payload = SharedWidgetData.fromMap(
              docs.first.data(),
            );
            if (!payload.hasContent) {
              _queueHomeWidgetUpdate(
                HomeWidgetService.fallbackNoNote,
                type: 'empty',
              );
              return const _WaitingForWidgetCard();
            }

            _queueHomeWidgetUpdate(
              _homeWidgetTextFor(payload),
              type: payload.contentType,
            );

            return _StatusCard(
              title: 'Latest widget',
              child: _LatestWidgetPreview(payload: payload),
            );
          },
    );
  }

  void _queueHomeWidgetUpdate(String text, {required String type}) {
    final String payloadKey = '$type::$text';
    if (_lastHomeWidgetPayload == payloadKey) return;
    _lastHomeWidgetPayload = payloadKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _homeWidgetService.updateLatestReceivedText(text, type: type);
    });
  }

  String _homeWidgetTextFor(SharedWidgetData payload) {
    if (payload.hasText) return payload.text!;
    if (payload.hasImage) return HomeWidgetService.fallbackNewWidget;
    return HomeWidgetService.fallbackNoNote;
  }

  Widget _buildPartnerCard(ThemeData theme) {
    final String? uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      return _StatusCard(
        title: 'Partner',
        child: Text(
          'Sign-in is required before connecting a partner.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService().getUserProfile(uid),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.hasError) {
              return _StatusCard(
                title: 'Partner',
                child: Text(
                  'Could not load your partner profile.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _StatusCard(
                title: 'Partner',
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final Map<String, dynamic>? data = snapshot.data?.data();
            final String? partnerId = data?['partnerId'] as String?;
            final String? pairingCode = data?['pairingCode'] as String?;

            if (partnerId != null && partnerId.isNotEmpty) {
              return _StatusCard(
                title: 'Partner',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected to partner.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Partner ID: $partnerId',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return _StatusCard(
              title: 'Partner',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pairingCode != null && pairingCode.isNotEmpty) ...[
                    Text(
                      'Your code: $pairingCode',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _partnerCodeController,
                    enabled: !_isConnecting,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Partner Code',
                      hintText: 'Enter 5-letter code',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isConnecting ? null : _connectPartner,
                      child: Text(
                        _isConnecting ? 'Connecting...' : 'Connect partner',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  void _showWidgetSetupInstructions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return const _WidgetSetupInstructionsContent();
      },
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
              'Add home screen widget',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'See your partner’s status and follow the steps to pin the widget on your home screen.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _buildPartnerCard(theme),
            const SizedBox(height: 16),
            _buildLatestWidgetCard(theme),
            const Spacer(),
            FilledButton.tonal(
              onPressed: () => _showWidgetSetupInstructions(context),
              child: const Text('Widget setup instructions'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _WaitingForWidgetCard extends StatelessWidget {
  const _WaitingForWidgetCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return _StatusCard(
      title: 'Latest widget',
      child: Text(
        'Waiting for your first widget',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LatestWidgetPreview extends StatelessWidget {
  const _LatestWidgetPreview({required this.payload});

  final SharedWidgetData payload;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DecodedWidgetImage imageResult = payload.decodeImage();

    if (payload.hasImage && imageResult.bytes == null) {
      return _WidgetPreviewError(
        message: payload.hasText
            ? 'The image could not be shown, but the note is still here.'
            : 'Could not show the latest widget image.',
        child: payload.hasText ? _TextPreview(text: payload.text!) : null,
      );
    }

    if (imageResult.bytes != null && payload.hasText) {
      return _ImageWithTextPreview(
        imageBytes: imageResult.bytes!,
        text: payload.text!,
      );
    }

    if (imageResult.bytes != null) {
      return _ImagePreview(imageBytes: imageResult.bytes!);
    }

    if (payload.hasText) {
      return _TextPreview(text: payload.text!);
    }

    return Text(
      'Waiting for your first widget',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return const _WidgetPreviewError(
                  message: 'Could not show the latest widget image.',
                );
              },
        ),
      ),
    );
  }
}

class _ImageWithTextPreview extends StatelessWidget {
  const _ImageWithTextPreview({required this.imageBytes, required this.text});

  final Uint8List imageBytes;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return const _WidgetPreviewError(
                      message: 'Could not show the latest widget image.',
                    );
                  },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  text,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
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
        ),
      ),
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

    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: SingleChildScrollView(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WidgetPreviewError extends StatelessWidget {
  const _WidgetPreviewError({required this.message, this.child});

  final String message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.broken_image_outlined, color: colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (child != null) ...[const SizedBox(height: 12), child!],
      ],
    );
  }
}

/// Scrollable step-by-step guide for Android and iOS home screen widgets.
class _WidgetSetupInstructionsContent extends StatelessWidget {
  const _WidgetSetupInstructionsContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add the widget to your home screen',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Steps can vary slightly by phone model and OS version.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _PlatformSection(
              icon: Icons.phone_android,
              title: 'Android',
              accentColor: const Color(0xFF3DDC84),
              steps: const [
                _StepData(
                  icon: Icons.touch_app_outlined,
                  text:
                      'Long-press an empty area on your home screen until menus appear.',
                ),
                _StepData(
                  icon: Icons.widgets_outlined,
                  text:
                      'Tap Widgets (or Add widget / Widgets — wording varies by launcher).',
                ),
                _StepData(
                  icon: Icons.search,
                  text:
                      'Find Widget Share in the list, or search for it if your launcher has search.',
                ),
                _StepData(
                  icon: Icons.swipe,
                  text:
                      'Touch and hold the widget size you want, then drag it to a home screen.',
                ),
                _StepData(
                  icon: Icons.check_circle_outline,
                  text:
                      'Release to place it. Some launchers let you resize after placing.',
                ),
              ],
            ),
            const SizedBox(height: 28),
            _PlatformSection(
              icon: Icons.phone_iphone,
              title: 'iOS',
              accentColor: colorScheme.primary,
              steps: const [
                _StepData(
                  icon: Icons.touch_app_outlined,
                  text:
                      'Long-press the home screen or an empty area until apps begin to jiggle.',
                ),
                _StepData(
                  icon: Icons.add,
                  text:
                      'Tap the + button in the top-left corner to open the widget gallery.',
                ),
                _StepData(
                  icon: Icons.search,
                  text:
                      'Search for Widget Share, or scroll the list to find the app.',
                ),
                _StepData(
                  icon: Icons.dashboard_customize_outlined,
                  text:
                      'Pick a widget size, tap Add Widget, then position it on your home screen.',
                ),
                _StepData(
                  icon: Icons.check_circle_outline,
                  text:
                      'Tap Done (top right) when you finish editing the home screen.',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PlatformSection extends StatelessWidget {
  const _PlatformSection({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.steps,
  });

  final IconData icon;
  final String title;
  final Color accentColor;
  final List<_StepData> steps;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accentColor, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List<Widget>.generate(steps.length, (int i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < steps.length - 1 ? 12 : 0),
            child: _InstructionStep(stepNumber: i + 1, data: steps[i]),
          );
        }),
      ],
    );
  }
}

class _StepData {
  const _StepData({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.stepNumber, required this.data});

  final int stepNumber;
  final _StepData data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$stepNumber',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  data.icon,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.text,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
