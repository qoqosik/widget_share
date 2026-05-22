# Firestore Security Rules

This project uses Firebase Anonymous Auth and stores paired-user widget data in Firestore.

## Files

- `firestore.rules`: versioned Firestore security rules.
- `firestore.indexes.json`: composite indexes for widget history queries.
- `firebase.json`: references the rules and indexes files for Firebase CLI deploys.
- `functions/index.js`: callable `pairWithCode` function for secure reciprocal pairing.

## What The Rules Protect

### `users/{uid}`

Allowed:

- A signed-in user can create their own profile document only at `users/{request.auth.uid}`.
- The created profile must contain only:
  - `uid`
  - `pairingCode`
  - `partnerId`
- `uid` must equal the document ID.
- `pairingCode` must be a 5-letter uppercase code.
- `partnerId` must start as `null`.
- A user can read their own profile.
- A user can read their partner's profile only when both documents point at each other.
- The `pairWithCode` Cloud Function updates `partnerId` and `updatedAt` with the Admin SDK.

Denied:

- Listing all user documents.
- Creating or editing another user's profile.
- Client-side user profile updates.
- Deleting user profiles.

### `widgets/{widgetId}`

Allowed:

- Sender or recipient can read a widget document.
- A signed-in user can create a widget only when:
  - `senderId == request.auth.uid`
  - `recipientId` equals the sender's current `partnerId`
  - only `senderId`, `recipientId`, `text`, `image`, and `timestamp` are present
  - `timestamp == request.time`
  - `text` is null or a string up to 5000 characters
  - `image` is null or a string up to 900000 characters
  - at least one of `text` or `image` is a string

Denied:

- Updating widgets.
- Deleting widgets.
- Reading widgets where the signed-in user is neither sender nor recipient.
- Creating widgets for someone other than the current user's paired partner.

## Pairing Flow

Pairing now uses the callable Cloud Function `pairWithCode`.

- Client calls `pairWithCode(code)`.
- Function runs with Admin SDK.
- Function requires Firebase Auth.
- Function normalizes and validates the 5-letter code.
- Function validates the caller document, code match, uniqueness, existing partner state, partner state, and self-pairing.
- Function updates both user documents atomically.
- Firestore rules keep users from updating another user's profile directly.

This is safer than the old client-side transaction because the client no longer needs to:

- Query `users` by `pairingCode`.
- Read arbitrary user profiles while searching for a code.
- Update another user's `partnerId`.

The Admin SDK bypasses Firestore rules inside the function, so the rules can remain strict for normal client access.

## Deploy

Do not deploy automatically from Codex. To deploy manually:

```sh
firebase deploy --only firestore:rules,firestore:indexes
```

Deploy the pairing function:

```sh
firebase deploy --only functions
```

Deploy Firestore and functions together:

```sh
firebase deploy --only firestore:rules,firestore:indexes,functions
```

To deploy only rules:

```sh
firebase deploy --only firestore:rules
```

To deploy only indexes:

```sh
firebase deploy --only firestore:indexes
```

## Manual Testing

Before deploying to production, test with a temporary Firebase project or emulator.

Expected passing cases:

- Anonymous user creates `users/{ownUid}` with valid fields.
- Anonymous user reads `users/{ownUid}`.
- Anonymous user calls `pairWithCode` with a valid partner code and both users become reciprocally paired.
- Paired user reads partner profile when both `partnerId` fields are reciprocal.
- Paired user creates a widget for their own partner.
- Sender reads a sent widget.
- Recipient reads a received widget.
- Received history query works:
  - `widgets.where('recipientId', isEqualTo: uid).orderBy('timestamp', descending: true)`
- Sent history query works:
  - `widgets.where('senderId', isEqualTo: uid).orderBy('timestamp', descending: true)`

Expected denied cases:

- User creates `users/{someoneElseUid}`.
- User changes their `uid` or `pairingCode`.
- User lists all `users`.
- User reads an unpaired user's profile.
- User creates a widget with a fake `senderId`.
- User creates a widget for someone who is not their `partnerId`.
- User reads a widget where they are neither sender nor recipient.
- User updates or deletes a widget.
- Direct client query of `users` by `pairingCode`.
- Direct client update of another user's `partnerId`.

## Emulator Notes

This repo does not currently include automated rules tests. If Firebase CLI is installed, you can run:

```sh
firebase emulators:start --only firestore,functions
```

For automated rules tests, add Firebase Rules Unit Testing in a separate test package or script. That is intentionally not included in this focused task.

## Remaining Security Limitations

- Pairing code uniqueness is not enforced by rules.
- Pairing code uniqueness is checked by `pairWithCode`; future code-generation should still avoid duplicate codes proactively.
- Base64 image size is capped by rules, but the app still stores images directly in Firestore.
- There is no delete/retention policy for old widgets.
- Anonymous Auth identities are lost if app data is cleared or the app is reinstalled.
- Storage rules are not included because Firebase Storage is not used.
