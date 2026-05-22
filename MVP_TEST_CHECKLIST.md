# Widget Share MVP Test Checklist

Use two Android devices or emulators with separate app installs/data.

## Fresh Install

- Device A: install and open the app.
- Device A: confirm anonymous sign-in completes and Add Widget shows a pairing code.
- Device B: install and open the app.
- Device B: confirm anonymous sign-in completes and Add Widget shows a different pairing code.
- Restart each app once and confirm the same user profile/pairing code still loads.

## Pairing

- On Device B, enter Device A's pairing code.
- Confirm both user documents have reciprocal `partnerId`.
- Confirm Add Widget shows `Connected to partner` on both devices after refresh.

## Failed Pairing Cases

- Enter an empty code and confirm a friendly validation message.
- Enter a short/invalid code and confirm `Partner codes must be 5 letters`.
- Enter your own code and confirm self-pairing is rejected.
- Pair once, then try to pair again and confirm already-paired messaging.
- Try a made-up 5-letter code and confirm code-not-found messaging.
- Disable network and try pairing; confirm a friendly failure message.

## Create Send Flow

- Before pairing, open Create and confirm Send is disabled with partner guidance.
- Try sending with no text/image and confirm `Add a note, drawing, or photo first.`
- Send a text-only widget.
- Send a drawing-only widget.
- Send a photo-only widget.
- Send a mixed text+drawing widget.
- Send a mixed text+photo widget.
- Disable network and try sending; confirm a friendly send failure and no crash.

## Add Widget Latest Preview

- Device receiving a text-only widget shows text in Latest widget.
- Device receiving a drawing/photo-only widget shows the image preview.
- Device receiving mixed text+image shows the image and readable text.
- Corrupt a latest widget `image` base64 value in Firestore and confirm fallback UI.
- Clear all received widgets for a test user and confirm the empty state.

## Notes History

- Received tab shows widgets where `recipientId` is the current UID.
- Sent tab shows widgets where `senderId` is the current UID.
- Both tabs are newest first.
- Text-only, image-only, drawing-only, and mixed widgets render without crashing.
- Missing or pending `timestamp` does not crash the UI.
- Empty Received tab shows `No received notes yet.`
- Empty Sent tab shows `No sent notes yet.`

## Android Home Widget

- Add the Widget Share widget to the Android home screen.
- With no received widget, confirm it shows `No note yet`.
- Receive a text-only widget, open Add Widget, and confirm widget text updates.
- Receive an image/drawing-only widget, open Add Widget, and confirm `New widget received`.
- Tap the widget background and confirm the app opens.
- Tap the `Open` area and confirm the app opens.
- Restart the app/device and confirm the widget still shows the last saved text.

## Firestore Rules Sanity Checks

- Signed-in user can create/read only `users/{ownUid}`.
- Client cannot list all `users`.
- Client cannot directly update another user's `partnerId`.
- Callable `pairWithCode` can pair users.
- Sender can create a widget only for their paired partner.
- Sender and recipient can read their widget.
- A third user cannot read someone else's widget.
- Widget update/delete is denied.

## Deployment Sanity

- Deploy functions/rules/indexes only from a deliberate terminal session.
- Do not deploy from Codex automatically.
- After deploy, repeat pairing and send/receive tests on a clean install.
