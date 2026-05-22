import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  String? get currentUserId {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  // Функция для отправки виджета
  Future<void> sendWidget({
    required String recipientId,
    String? text,
    Uint8List? imageBytes, // Сюда прилетит рисунок или фото
  }) async {
    final String? senderId = currentUserId;
    if (senderId == null || senderId.isEmpty) {
      throw const FirebaseServiceException(
        'You must be signed in before sending a widget.',
      );
    }
    if (recipientId.trim().isEmpty) {
      throw const FirebaseServiceException(
        'Connect with your partner before sending a widget.',
      );
    }

    String? base64Image;

    // Если есть картинка, превращаем её в текст (Base64)
    if (imageBytes != null) {
      base64Image = base64Encode(imageBytes);
    }

    await _db.collection('widgets').add({
      'senderId': senderId,
      'recipientId': recipientId,
      'text': text,
      'image': base64Image, // Сохраняем как строку!
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Стрим для получения последнего виджета (для главного экрана)
  Stream<QuerySnapshot<Map<String, dynamic>>> getLatestWidget(String myId) {
    return _db
        .collection('widgets')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) =>
              snapshot.data() ?? <String, dynamic>{},
          toFirestore: (value, _) => value,
        )
        .where('recipientId', isEqualTo: myId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamReceivedWidgets() {
    return _streamWidgetsForCurrentUser('recipientId');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSentWidgets() {
    return _streamWidgetsForCurrentUser('senderId');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _streamWidgetsForCurrentUser(
    String userField,
  ) {
    final String? uid = currentUserId;
    if (uid == null || uid.isEmpty) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.error(
        Exception('You must be signed in to load notes.'),
      );
    }

    return _db
        .collection('widgets')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) =>
              snapshot.data() ?? <String, dynamic>{},
          toFirestore: (value, _) => value,
        )
        .where(userField, isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
    return _users.doc(uid).snapshots();
  }

  Future<void> pairWithCode(String code) async {
    final String trimmedCode = code.trim().toUpperCase();
    if (trimmedCode.isEmpty) {
      throw const FirebaseServiceException('Enter a partner code.');
    }

    if (!RegExp(r'^[A-Z]{5}$').hasMatch(trimmedCode)) {
      throw const FirebaseServiceException('Partner codes must be 5 letters.');
    }

    final String? uid = currentUserId;
    if (uid == null || uid.isEmpty) {
      throw const FirebaseServiceException(
        'You must be signed in to connect a partner.',
      );
    }

    try {
      final HttpsCallable callable = _functions.httpsCallable('pairWithCode');
      await callable.call<void>(<String, dynamic>{'code': trimmedCode});
    } on FirebaseFunctionsException catch (e) {
      throw FirebaseServiceException(_pairingErrorMessage(e));
    } catch (_) {
      throw const FirebaseServiceException(
        'Could not connect to your partner. Try again soon.',
      );
    }
  }

  Future<void> connectPartner(String code) {
    return pairWithCode(code);
  }

  String _pairingErrorMessage(FirebaseFunctionsException error) {
    final String? message = error.message;
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }

    switch (error.code) {
      case 'invalid-argument':
        return 'Enter a valid 5-letter partner code.';
      case 'unauthenticated':
        return 'You must be signed in to connect a partner.';
      case 'not-found':
        return 'Partner code not found.';
      case 'failed-precondition':
        return 'This partner code cannot be connected right now.';
      case 'unavailable':
        return 'Pairing is temporarily unavailable. Try again soon.';
      default:
        return 'Could not connect to your partner. Try again soon.';
    }
  }
}

class FirebaseServiceException implements Exception {
  const FirebaseServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
