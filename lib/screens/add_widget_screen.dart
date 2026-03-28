import 'package:flutter/material.dart';

/// Instructions and partner status for adding the home screen widget.
///
/// (Full UI will include partner connection state and platform-specific steps.)
class AddWidgetScreen extends StatelessWidget {
  const AddWidgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partner status',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Placeholder — connect to Firebase to show live status.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.tonal(
              onPressed: () {},
              child: const Text('Widget setup instructions'),
            ),
          ],
        ),
      ),
    );
  }
}
