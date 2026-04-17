import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // Функция для отправки виджета
  Future<void> sendWidget({
    required String senderId,
    required String recipientId,
    String? text,
    Uint8List? imageBytes, // Сюда прилетит рисунок или фото
  }) async {
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

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
    return _users.doc(uid).snapshots();
  }

  Future<void> connectPartner(String code) async {
    final String trimmedCode = code.trim().toUpperCase();
    if (trimmedCode.isEmpty) {
      throw Exception('Enter a partner code.');
    }

    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null || myUid.isEmpty) {
      throw Exception('You must be signed in to connect a partner.');
    }

    final QuerySnapshot<Map<String, dynamic>> match = await _users
        .where('pairingCode', isEqualTo: trimmedCode)
        .limit(1)
        .get();

    if (match.docs.isEmpty) {
      throw Exception('Partner code not found.');
    }

    final DocumentReference<Map<String, dynamic>> partnerRef =
        match.docs.first.reference;
    final String partnerUid = partnerRef.id;

    if (partnerUid == myUid) {
      throw Exception('You cannot connect to your own code.');
    }

    final DocumentReference<Map<String, dynamic>> myRef = _users.doc(myUid);

    await _db.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> mySnapshot =
          await transaction.get(myRef);
      final DocumentSnapshot<Map<String, dynamic>> partnerSnapshot =
          await transaction.get(partnerRef);

      if (!mySnapshot.exists) {
        throw Exception('Your profile could not be found.');
      }
      if (!partnerSnapshot.exists) {
        throw Exception('Partner profile could not be found.');
      }

      final String? myPartnerId = mySnapshot.data()?['partnerId'] as String?;
      final String? partnerPartnerId =
          partnerSnapshot.data()?['partnerId'] as String?;

      if (myPartnerId != null && myPartnerId.isNotEmpty) {
        throw Exception('You are already connected to a partner.');
      }
      if (partnerPartnerId != null && partnerPartnerId.isNotEmpty) {
        throw Exception('That partner code is already connected.');
      }

      transaction.update(myRef, <String, dynamic>{'partnerId': partnerUid});
      transaction.update(partnerRef, <String, dynamic>{'partnerId': myUid});
    });
  }
}
