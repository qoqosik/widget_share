import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const String latestNoteTextKey = 'latest_note_text';
  static const String latestNoteUpdatedAtKey = 'latest_note_updated_at';
  static const String latestNoteTypeKey = 'latest_note_type';
  static const String fallbackNoNote = 'No note yet';
  static const String fallbackNewWidget = 'New widget received';
  static const String fallbackOpenToSync = 'Open Widget Share to sync';
  static const String fallbackUpdateFailed = "Couldn't update widget";
  static const String androidWidgetName = 'WidgetShareHomeWidgetProvider';

  Future<void> updateLatestReceivedText(
    String? text, {
    String type = 'text',
  }) async {
    final String value = _displayText(text);

    try {
      await HomeWidget.saveWidgetData<String>(latestNoteTextKey, value);
      await HomeWidget.saveWidgetData<String>(latestNoteTypeKey, type);
      await HomeWidget.saveWidgetData<String>(
        latestNoteUpdatedAtKey,
        DateTime.now().toIso8601String(),
      );
      await HomeWidget.updateWidget(name: androidWidgetName);
    } catch (error) {
      debugPrint('Could not update Android home widget: $error');
    }
  }

  Future<void> updateEmptyState() {
    return updateLatestReceivedText(fallbackNoNote, type: 'empty');
  }

  Future<void> resetWidgetText() {
    return updateEmptyState();
  }

  String _displayText(String? text) {
    final String? trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallbackNoNote;
    return trimmed;
  }
}
