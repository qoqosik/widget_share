import 'package:flutter/material.dart';

/// Instructions and partner status for adding the home screen widget.
///
/// (Full UI will include partner connection state and platform-specific steps.)
class AddWidgetScreen extends StatelessWidget {
  const AddWidgetScreen({super.key});

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
              onPressed: () => _showWidgetSetupInstructions(context),
              child: const Text('Widget setup instructions'),
            ),
          ],
        ),
      ),
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
    final theme = Theme.of(context);

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
            child: _InstructionStep(
              stepNumber: i + 1,
              data: steps[i],
            ),
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
  const _InstructionStep({
    required this.stepNumber,
    required this.data,
  });

  final int stepNumber;
  final _StepData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$stepNumber',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          data.icon,
          size: 22,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            data.text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
