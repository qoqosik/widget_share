# Android Home Widget

Widget Share has a minimal Android home screen widget backed by the `home_widget` Flutter package.

## Current Support

- Android only.
- Text-only display.
- Shows the latest received widget text when available.
- Shows `New widget received` when the latest received widget is image/drawing-only.
- Shows `No note yet` when there is no received widget.
- Tapping the widget or the `Open` area opens the Flutter app. The app's existing Firestore listener then syncs and updates widget storage.

Native image/photo/drawing rendering is intentionally not implemented yet.

## Native Files

- Provider: `android/app/src/main/kotlin/com/example/widget_share/WidgetShareHomeWidgetProvider.kt`
- Layout: `android/app/src/main/res/layout/widget_share_home_widget.xml`
- Provider metadata: `android/app/src/main/res/xml/widget_share_home_widget_info.xml`
- Background drawables:
  - `android/app/src/main/res/drawable/widget_share_widget_background.xml`
  - `android/app/src/main/res/drawable/widget_share_widget_button_background.xml`

## Flutter Update Flow

`lib/services/home_widget_service.dart` writes data through `HomeWidget.saveWidgetData` and triggers `HomeWidget.updateWidget`.

`lib/screens/add_widget_screen.dart` updates the widget when the latest received widget is displayed:

- text or mixed widget: saves the text
- image/drawing-only widget: saves `New widget received`
- empty state: saves `No note yet`

Updates are deduplicated in the Add Widget screen so the same payload is not written repeatedly during rebuilds.

## Saved Data Keys

- `latest_note_text`: text shown by the native widget.
- `latest_note_type`: one of `text`, `image`, `mixed`, or `empty`.
- `latest_note_updated_at`: ISO timestamp written by Flutter when widget storage is updated.

## Manual Test

1. Install the app on an Android emulator or device.
2. Long-press the home screen and add the Widget Share widget.
3. Open the app and pair with another user.
4. Send a text-only widget from the partner.
5. Open the Add Widget tab on the receiving device.
6. Confirm the home screen widget shows the latest text.
7. Send an image-only or drawing-only widget.
8. Open the Add Widget tab again.
9. Confirm the home screen widget shows `New widget received`.
10. Tap the widget or `Open` area and confirm it opens the app.
11. Restart the app or device and confirm the widget still shows the last saved text.

## Limitations

- No native image rendering yet.
- No native/background Firestore sync.
- The widget updates when Flutter displays the latest received widget, mainly from the Add Widget tab.
- The `Open` area opens the app rather than refreshing Firestore directly.
- iOS widgets are not implemented.

## Future Image Support Plan

For image support, keep native widget data small and avoid reading Firestore from native Android directly. A later task can:

1. Compress or render the latest image to a local file from Flutter.
2. Save the file path through `HomeWidget.saveWidgetData`.
3. Update `WidgetShareHomeWidgetProvider` to decode that local file into the `RemoteViews`.
4. Keep text fallback behavior for missing or corrupt image files.
